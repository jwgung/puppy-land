"""Yaongi's dialogue portraits (issue #153): transparent bust renders of the yaongi model (yaongi.py)
in the same storybook look as dugi_portrait.py / fox_portrait.py (same cel ramp, key sun, brown outline).

Run (headless, Blender 4.5):
    blender -b --factory-startup -P apps/lab3d/art_src/characters/yaongi_portrait.py -- \
        [--out apps/lab3d/assets/characters/portraits] [--size 512] [--only happy,worried]

Writes yaongi_<face>.webp (RGBA, lossless WebP) per expression (the Story.FACES set: explain, happy,
surprised, thinking, worried). Like the fox the model has no face rig: an expression repaints the face
(face_kit) and poses the nodes (head, ears, the free left paw; the right one holds the flask). The small
props keep their own thin outline (yaongi.PROP_OUTLINE).
"""
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import bread_cat as bc  # noqa: E402
import dugi_portrait as dp  # noqa: E402
import yaongi  # noqa: E402

CAM_POS = Vector((0.62, -3.25, 0.92))
CAM_TGT = Vector((0.0, 0.0, 0.82))
# head: (tilt about y, turn about z) deg; nod: about x (+ = chin down); ears: (left, right) deg about x
# (+ = back); ears_out: (left, right) deg about y (+ = tips fall outwards); arm_l: the free paw's target.
# Quick and curious (docs/islands/curie-lines.md): a bigger head tilt and a raised paw than the fox's.
EXPRESSIONS = {
    "explain": {"head": (-6.0, 8.0), "ears": (2.0, 0.0), "arm_l": (0.58, -0.50, 0.78)},
    "happy": {"face": {"eyes": "happy", "mouth": "big", "brows": "happy", "blush": 1.5}, "head": (9.0, -3.0),
              "nod": -5.0, "ears": (-6.0, -6.0), "arm_l": (0.58, -0.40, 0.86)},
    "surprised": {"face": {"eyes": "wide", "brows": "raised", "mouth": "o"}, "head": (0.0, 4.0), "nod": -7.0,
                  "ears": (-10.0, -10.0), "arm_l": (0.44, -0.42, 0.70)},
    "thinking": {"face": {"eyes": "look", "brows": "think", "mouth": "hmm"}, "head": (-10.0, 8.0),
                 "ears": (2.0, 8.0), "arm_l": (0.08, -0.34, 0.52)},
    "worried": {"face": {"eyes": "soft", "brows": "worried", "mouth": "wavy", "blush": 0.8},
                "head": (4.0, 4.0), "nod": 8.0, "ears": (12.0, 12.0), "ears_out": (18.0, 18.0)},
}


def render(name, spec, out_dir, size):
    bc.clear_scene()
    yaongi.build(spec.get("face"))
    objs = {o.name: o for o in bpy.data.objects}
    dp.rot_local(objs["Head"], (1, 0, 0), spec.get("nod", 0.0))
    dp.rot_local(objs["Head"], (0, 1, 0), spec["head"][0])
    dp.rot_local(objs["Head"], (0, 0, 1), spec["head"][1])
    dp.rot_local(objs["EarL"], (1, 0, 0), spec["ears"][0])
    dp.rot_local(objs["EarR"], (1, 0, 0), spec["ears"][1])
    out_l, out_r = spec.get("ears_out", (0.0, 0.0))
    dp.rot_local(objs["EarL"], (0, 1, 0), out_l)
    dp.rot_local(objs["EarR"], (0, 1, 0), -out_r)
    if spec.get("arm_l") is not None:
        yaongi.pose_point(objs["ArmL"], objs["HandL"], spec["arm_l"])
    bpy.context.view_layer.update()
    dp.CAM_POS = CAM_POS
    dp.CAM_TGT = CAM_TGT
    scene = dp.setup_scene(size)
    outline_mat = dp.make_outline_material()
    chars = [o for o in bpy.data.objects if o.type == "MESH"]
    for m in {s.material for o in chars for s in o.material_slots if s.material}:
        dp.toon(m)
    body_outline = dp.OUTLINE
    for o in chars:
        dp.OUTLINE = yaongi.PROP_OUTLINE if o.name in yaongi.PROPS else body_outline
        dp.add_outline(o, outline_mat)
    dp.OUTLINE = body_outline
    scene.render.filepath = os.path.join(out_dir, "yaongi_%s.webp" % name)
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
