"""Fox island keeper's dialogue portraits (issue #71 prototype): transparent bust renders of fox.py in
the same storybook look as dugi_portrait.py / puppy_portrait.py (same cel ramp, key sun, brown outline).

Run (headless, Blender 4.5):
    blender -b --factory-startup -P apps/lab3d/art_src/characters/fox_portrait.py -- \
        [--variant a|b|c] [--out <dir>] [--size 512] [--only happy,worried]

Writes fox_<variant>_<face>.png (RGBA) per expression (the Story.FACES set: explain, happy, surprised,
thinking, worried). Like Puppy and Dugi the model has no face rig: an expression repaints the face
(face_kit) and poses the nodes (head, ears, a paw).
"""
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import bread_cat as bc  # noqa: E402
import dugi_portrait as dp  # noqa: E402
import fox  # noqa: E402

CAM_POS = Vector((0.66, -3.25, 1.00))
CAM_TGT = Vector((0.0, 0.0, 0.92))
# head: (tilt about y, turn about z) deg; nod: about x (+ = chin down); ears: (left, right) deg about x
# (+ = back); ears_out: (left, right) deg about y (+ = tips fall outwards); arm_l: the free paw's target.
EXPRESSIONS = {
    "explain": {"head": (-5.0, 8.0), "ears": (4.0, 2.0), "arm_l": (0.62, -0.55, 0.92)},
    "happy": {"face": {"eyes": "happy", "mouth": "big", "brows": "happy", "blush": 1.5}, "head": (7.0, -3.0),
              "nod": -4.0, "ears": (-4.0, -4.0), "arm_l": (0.62, -0.42, 0.98)},
    "surprised": {"face": {"eyes": "wide", "brows": "raised", "mouth": "o"}, "head": (0.0, 4.0), "nod": -6.0,
                  "ears": (-8.0, -8.0), "arm_l": (0.45, -0.42, 0.78)},
    "thinking": {"face": {"eyes": "look", "brows": "think", "mouth": "hmm"}, "head": (-9.0, 8.0),
                 "ears": (2.0, 8.0), "arm_l": (0.06, -0.36, 0.58)},
    "worried": {"face": {"eyes": "soft", "brows": "worried", "mouth": "wavy", "blush": 0.8},
                "head": (4.0, 4.0), "nod": 8.0, "ears": (16.0, 16.0), "ears_out": (38.0, 38.0)},
}


def render(variant, name, spec, out_dir, size):
    bc.clear_scene()
    fox.set_variant(variant)
    fox.build(spec.get("face"))
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
        fox.pose_point(objs["ArmL"], objs["HandL"], spec["arm_l"])
    bpy.context.view_layer.update()
    dp.CAM_POS = CAM_POS
    dp.CAM_TGT = CAM_TGT
    scene = dp.setup_scene(size)
    scene.render.image_settings.file_format = "PNG"
    outline_mat = dp.make_outline_material()
    chars = [o for o in bpy.data.objects if o.type == "MESH"]
    for m in {s.material for o in chars for s in o.material_slots if s.material}:
        dp.toon(m)
    for o in chars:
        dp.add_outline(o, outline_mat)
    scene.render.filepath = os.path.join(out_dir, "fox_%s_%s.png" % (variant, name))
    bpy.ops.render.render(write_still=True)
    print("PORTRAIT", scene.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir, size, only, variant = "fox_portraits", 512, None, "a"
    for i, a in enumerate(argv):
        if a == "--out":
            out_dir = argv[i + 1]
        elif a == "--size":
            size = int(argv[i + 1])
        elif a == "--only":
            only = argv[i + 1].split(",")
        elif a == "--variant":
            variant = argv[i + 1]
    os.makedirs(out_dir, exist_ok=True)
    for name, spec in EXPRESSIONS.items():
        if only and name not in only:
            continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        render(variant, name, spec, os.path.abspath(out_dir), size)


if __name__ == "__main__":
    main()
