"""The bread cat's dialogue portraits (#132, 2026-11-12 user: "빵고양이가 주인공인데... 말은 해야지"):
transparent bust renders of the bread cat model (bread_cat.py) in the same storybook look as
dugi_portrait.py / puppy_portrait.py / fox_portrait.py (same cel ramp, key sun, brown outline).

Run (headless, Blender 4.5):
    blender -b --factory-startup -P apps/lab3d/art_src/characters/bread_cat_portrait.py -- \
        [--out apps/lab3d/assets/characters/portraits] [--size 512] [--only happy,worried]

Writes cat_<face>.webp (RGBA, lossless WebP) per expression (the Story.FACES set: explain, happy,
surprised, thinking, worried). The model has no face rig and its ears are part of the head: an
expression repaints the face (bread_cat.paint_head's `face`, face_kit) and turns the head. The in-game
model (bread_cat.glb) is not rebuilt.
"""
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import bread_cat as bc  # noqa: E402
import dugi_portrait as dp  # noqa: E402

# The cat's head spans 0.77-1.40 m (the bag's rim at 0.76 m): the bust from the paws on the rim up to
# the ear tips, seen a little from the viewer's right like the others.
CAM_POS = Vector((0.55, -2.95, 1.10))
CAM_TGT = Vector((0.0, 0.0, 0.98))
# mouth: the model's ("omega", "smile") or a face_kit mouth; head: (tilt about y, turn about z) deg;
# nod: about x (+ = chin down).
EXPRESSIONS = {
    "explain": {"mouth": "omega", "head": (-4.0, 6.0)},
    "happy": {"mouth": "smile", "face": {"eyes": "happy", "brows": "happy", "blush": 1.5}, "head": (7.0, -3.0),
              "nod": -4.0},
    "surprised": {"mouth": "o", "face": {"eyes": "wide", "brows": "raised"}, "head": (0.0, 4.0), "nod": -6.0},
    "thinking": {"mouth": "hmm", "face": {"eyes": "look", "brows": "think"}, "head": (-9.0, 8.0)},
    "worried": {"mouth": "wavy", "face": {"eyes": "soft", "brows": "worried", "blush": 0.8},
                "head": (4.0, 4.0), "nod": 8.0},
}


def render(name, spec, out_dir, size):
    bc.clear_scene()
    bc.build(spec["mouth"], face=spec.get("face"))
    objs = {o.name: o for o in bpy.data.objects}
    dp.rot_local(objs["Head"], (1, 0, 0), spec.get("nod", 0.0))
    dp.rot_local(objs["Head"], (0, 1, 0), spec["head"][0])
    dp.rot_local(objs["Head"], (0, 0, 1), spec["head"][1])
    bpy.context.view_layer.update()
    dp.CAM_POS = CAM_POS
    dp.CAM_TGT = CAM_TGT
    scene = dp.setup_scene(size)
    outline_mat = dp.make_outline_material()
    chars = [o for o in bpy.data.objects if o.type == "MESH"]
    for m in {s.material for o in chars for s in o.material_slots if s.material}:
        dp.toon(m)
    for o in chars:
        dp.add_outline(o, outline_mat)
    scene.render.filepath = os.path.join(out_dir, "cat_%s.webp" % name)
    bpy.ops.render.render(write_still=True)
    print("PORTRAIT", scene.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir, size, only = "apps/lab3d/assets/characters/portraits", 512, None
    for i, a in enumerate(argv):
        if a == "--out":
            out_dir = argv[i + 1]
        elif a == "--size":
            size = int(argv[i + 1])
        elif a == "--only":
            only = argv[i + 1].split(",")
    os.makedirs(out_dir, exist_ok=True)
    for name, spec in EXPRESSIONS.items():
        if only and name not in only:
            continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        render(name, spec, os.path.abspath(out_dir), size)


if __name__ == "__main__":
    main()
