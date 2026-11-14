"""Yaongi (야옹이), the lighthouse keeper of the third island 퀴리섬 (issue #153), generated entirely in
Blender Python, from fox.py (the same chibi, helpers, atlas, node / pivot conventions and face_kit).

Run (headless):
    blender -b --factory-startup -P apps/lab3d/art_src/characters/yaongi.py -- \
        [--out apps/lab3d/assets/characters/yaongi.glb] [--preview yaongi_preview.png] [--size 768]

The look (docs/islands/curie.md; picked by the user on 2026-11-13 from drafts and colourways: "화학섬
느낌이 나는 디자인으로", "6번이 제일 맘에 듬", "목도리는 빼줘", "코트 닫아"): a white cat, a coral lab
coat closed in front with three buttons and coral sleeves, brass lab goggles pushed up on the forehead,
a chest pocket with three test tubes, a round-bottomed flask of teal potion in the right paw, the tail's
tip in rainbow bands (the rainbow lighthouse's keeper). Unlike the bread cat (an orange tabby in a bread
bag): white, slim, a long thin tail.

Node tree as fox.py (Yaongi / Body / Head / EarL, EarR / ArmL, ArmR / HandL, HandR), and the small
props as their own meshes (Head / Goggles, Body / Pocket, ArmR / Flask) so a render gives each its own
thin outline (PROP_OUTLINE: one body-sized line swallowed them, 2026-11-13 user "디테일이 뭉개지잖아").
Blender: +Z up, faces -Y; glTF/Godot: +Y up, faces +Z.
"""

import math
import os
import sys

sys.dont_write_bytecode = True

import bmesh  # noqa: E402
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bread_cat as bc  # noqa: E402  (generic helpers only)
from bread_cat import (bezier, blend, build_sphere, build_tube, hexc, new_bm, paint_volume,  # noqa: E402
                       sd_ellipse, sd_segment, sd_triangle, smooth_fill)
import face_kit as fk  # noqa: E402  (portrait expressions only)

TEX = 1024
PAD = 3

# storybook pastel: white fur, pink inner ears and nose, brass goggles, a coral coat, teal potion
P = dict(
    fur="#f7f4ee", fur_shade="#e6e0d6", ear_tip="#ffb3c1", cream="#ffffff", blush="#ffb0b8",
    eye="#2a1a14", nose="#ff8fa3", mouth="#6b3424", tongue="#ff7f8c", sock="#f2ede4",
    brass="#d9a441", brass_dark="#b07f2a", coat="#ffb3ae", coat_dark="#f08f8a", whisker="#b9a99a",
    glass="#7fb8d4", cork="#c89b6d", liquid="#36c2b4", tube1="#ff6b6b", tube2="#7bd389", tube3="#6cb8ff",
)
RAINBOW = ["#ff6b6b", "#ffb347", "#ffe066", "#7bd389", "#6cb8ff", "#b48cff"]
# Atlas layout (pixels, origin bottom-left like Blender UVs)
R_HEAD = (0, 512, 1024, 1024)
R_EAR = (0, 256, 256, 512)
R_TAIL = (256, 256, 512, 512)
R_BODY = (512, 256, 768, 512)
SWATCH_ORIGIN = (768, 0)  # 4 x 4 swatches of 64 px
SWATCHES = ["fur", "cream", "sock", "brass", "brass_dark", "nose", "coat", "coat_dark", "glass", "liquid",
            "tube1", "tube2", "tube3", "cork"]


def region_uv(rect, u, v):
    x0, y0, x1, y1 = rect
    return ((x0 + PAD + u * (x1 - x0 - 2 * PAD)) / TEX, (y0 + PAD + v * (y1 - y0 - 2 * PAD)) / TEX)


def swatch_uv(name):
    i = SWATCHES.index(name)
    return ((SWATCH_ORIGIN[0] + (i % 4) * 64 + 32) / TEX, (SWATCH_ORIGIN[1] + (i // 4) * 64 + 32) / TEX)


def region_grid(rect):
    x0, y0, x1, y1 = rect
    xs = (np.arange(x0, x1) + 0.5 - x0 - PAD) / (x1 - x0 - 2 * PAD)
    ys = (np.arange(y0, y1) + 0.5 - y0 - PAD) / (y1 - y0 - 2 * PAD)
    return np.meshgrid(np.clip(xs, 0, 1), np.clip(ys, 0, 1))


# --------------------------------------------------------------------------------------------
# Shapes (Blender space), shared by geometry and painting
# --------------------------------------------------------------------------------------------

HEAD_R = 0.300
HEAD_SX, HEAD_SY, HEAD_SZ = 1.12, 0.96, 0.94   # a round face
HEAD_C = Vector((0.0, -0.02, 0.815))
NECK = Vector((0.0, 0.0, 0.560))
BODY_C = Vector((0.0, 0.015, 0.300))
BODY_R = Vector((0.225, 0.205, 0.280))          # a slimmer bean than Puppy
EYE_X, EYE_Z, EYE_RX, EYE_RZ = 0.112, -0.010, 0.030, 0.038   # big bright eyes (curious)
NOSE_Z = -0.078
MUZZLE = (0.0, -0.095, 0.075, 0.060, 0.022)    # a small round cat muzzle


def head_point(d):
    x, y, z = d
    p = Vector((x * HEAD_R * HEAD_SX, y * HEAD_R * HEAD_SY * (0.92 if y < 0 else 1.0), z * HEAD_R * HEAD_SZ))
    if y < 0:  # a soft muzzle bump pushed straight forward (keeps the painted front projection exact)
        mx, mz, ax, az, h = MUZZLE
        p.y -= h * math.exp(-((p.x - mx) / ax) ** 2 - ((p.z - mz) / az) ** 2) * min(1.0, -y * 3)
    return HEAD_C + p


def body_point(d):
    lower = max(0.0, -d.z)
    upper = max(0.0, d.z)
    w = 1.0 + 0.12 * lower - 0.10 * upper ** 2
    return BODY_C + Vector((d.x * BODY_R.x * w, d.y * BODY_R.y * w, d.z * BODY_R.z))


# --------------------------------------------------------------------------------------------
# Texture painting (numpy, sRGB)
# --------------------------------------------------------------------------------------------

def paint_head(face=None):
    """face (portraits only, face_kit): an expression; None paints the model's own face."""
    face = face or {}
    u, v = region_grid(R_HEAD)
    lon = (u - 0.5) * 2 * math.pi
    lat = (v - 0.5) * math.pi
    dx = np.sin(lon) * np.cos(lat); dy = -np.cos(lon) * np.cos(lat); dz = np.sin(lat)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    blend(img, np.clip((dy + 0.3) * 0.7, 0, 1), hexc(P["fur_shade"]), 0.5)
    front = dy < 0.0
    qx = dx * HEAD_R * HEAD_SX
    qz = dz * HEAD_R * HEAD_SZ
    aa = 0.0020
    # cream: the muzzle and both cheeks sweeping out under the eyes, and the chin
    mask = np.minimum(sd_ellipse(qx, qz, 0.0, -0.105, 0.085, 0.060), qz + 0.19)
    blend(img, smooth_fill(mask, 0.004) * front, hexc(P["cream"]))
    blend(img, smooth_fill(qz + 0.16, 0.02) * (dy < 0.4), hexc(P["cream"]))
    paint_volume(img, qx, qz, front, HEAD_R * HEAD_SX, HEAD_R * HEAD_SZ, (0.0, -0.105), (0.085, 0.070),
                 hexc("#fffbf3"), (0.94, 0.84, 0.78))
    bk = float(face.get("blush", 1.0))
    for s in (-1, 1):  # blush ovals on the cream cheeks
        blend(img, smooth_fill(sd_ellipse(qx, qz, s * 0.200, -0.088, 0.040 * bk ** 0.5, 0.024 * bk ** 0.5), 0.012) * front,
              hexc(P["blush"]), min(1.0, 0.7 * bk))
    if face.get("eyes", "dot") != "dot":
        fk.eyes(img, qx, qz, front, aa, EYE_X, EYE_Z, EYE_RX, EYE_RZ, face["eyes"], hexc(P["eye"]))
    else:
        for s in (-1, 1):
            ex, ez = s * EYE_X, EYE_Z
            blend(img, smooth_fill(sd_ellipse(qx, qz, ex, ez, EYE_RX, EYE_RZ), aa) * front, hexc(P["eye"]))
            blend(img, smooth_fill(sd_ellipse(qx, qz, ex - 0.009, ez + 0.013, 0.011, 0.012), aa) * front, np.ones(3))
            blend(img, smooth_fill(sd_ellipse(qx, qz, ex + 0.010, ez - 0.014, 0.005, 0.005), aa) * front, np.ones(3), 0.8)
    fk.brows(img, qx, qz, front, aa, EYE_X, EYE_Z + 0.056, face.get("brows"), hexc(P["ear_tip"]))
    for s in (-1, 1):   # whiskers: three thin strokes on each cheek
        for k, dz in enumerate((-0.004, -0.020, -0.036)):
            w = sd_segment(qx, qz, s * 0.075, NOSE_Z + dz * 0.5, s * 0.175, NOSE_Z + dz - 0.006 * (k - 1)) - 0.0018
            blend(img, smooth_fill(w, aa) * front, hexc(P["whisker"]), 0.9)
    nz = NOSE_Z   # a small pink rounded nose with one shine
    nose = sd_triangle(qx, qz, (-0.020, nz + 0.010), (0.020, nz + 0.010), (0.0, nz - 0.012)) - 0.006
    blend(img, smooth_fill(nose, aa) * front, hexc(P["nose"]))
    blend(img, smooth_fill(sd_ellipse(qx, qz, -0.007, nz + 0.008, 0.007, 0.004), aa) * front, np.ones(3), 0.85)
    mcol = hexc(P["mouth"]); stroke = 0.0038
    sdf = sd_segment(qx, qz, 0.0, nz - 0.014, 0.0, nz - 0.026) - stroke * 0.8
    if face.get("mouth", "calm") != "calm":   # a portrait expression's mouth (face_kit)
        fk.mouth(img, qx, qz, front, aa, nz - 0.026, face["mouth"], mcol, hexc(P["tongue"]), sdf, 0.85)
        return img
    cz = nz - 0.026   # tiny closed smile: two small arcs curling up
    for s in (-1, 1):
        cx, r = s * 0.026, 0.026
        ring = np.abs(np.sqrt((qx - cx) ** 2 + (qz - cz - 0.020) ** 2) - r) - stroke * 0.8
        sdf = np.minimum(sdf, np.where((s * (qx - cx) > -0.001) & (qz < cz + 0.003), ring, 1.0))
    blend(img, smooth_fill(sdf, aa) * front, mcol)
    return img


def paint_ear():
    """u = around the ear section (0 = the front-facing line), v = root (0) -> tip (1): a dark tip,
    cream inside on the front."""
    u, v = region_grid(R_EAR)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    inner = np.clip((np.cos(2 * math.pi * u) - 0.35) * 6, 0, 1) * np.clip((0.82 - v) * 8, 0, 1) * np.clip(v * 8, 0, 1)
    blend(img, inner, hexc(P["cream"]), 0.9)
    blend(img, np.clip((v - 0.62) / 0.12, 0, 1), hexc(P["ear_tip"]))
    return img


def paint_tail():
    """u = around, v = root (0) -> tip (1): the tip in rainbow bands (the rainbow lighthouse's keeper)."""
    u, v = region_grid(R_TAIL)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    blend(img, np.clip((0.35 - v) * 2, 0, 1), hexc(P["fur_shade"]), 0.4)
    start, n = 0.70, len(RAINBOW)
    for i, c in enumerate(RAINBOW):
        lo = start + (1.0 - start) * i / n
        blend(img, (v >= lo).astype(float), hexc(c))
    return img


def paint_body():
    u, v = region_grid(R_BODY)
    lon = (u - 0.5) * 2 * math.pi
    lat = (v - 0.5) * math.pi
    dy = -np.cos(lon) * np.cos(lat)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    blend(img, np.clip((dy + 0.2) * 0.8, 0, 1), hexc(P["fur_shade"]), 0.4)
    bib = sd_ellipse(lon, lat, 0.0, 0.25, 0.70, 1.20)   # a white chest and tummy
    blend(img, smooth_fill(bib * 0.3, 0.02), hexc(P["cream"]))
    coat = np.clip((lat + 0.95) * 12, 0, 1)   # the lab coat: all round and closed in front, to the hips
    blend(img, coat, hexc(P["coat"]))
    blend(img, coat * np.clip((dy + 0.1) * 0.8, 0, 1), hexc(P["coat_dark"]), 0.35)
    for b in (0.30, -0.05, -0.40):   # three buttons down the middle of the front
        blend(img, smooth_fill(sd_ellipse(lon, lat, 0.0, b, 0.07, 0.07), 0.01), hexc(P["coat_dark"]))
    return img


def build_atlas(face=None):
    canvas = np.zeros((TEX, TEX, 3)); canvas[...] = hexc(P["fur"])
    for rect, fn in ((R_HEAD, lambda: paint_head(face)), (R_EAR, paint_ear), (R_TAIL, paint_tail), (R_BODY, paint_body)):
        x0, y0, x1, y1 = rect
        canvas[y0:y1, x0:x1] = fn()
    for i, name in enumerate(SWATCHES):
        x = SWATCH_ORIGIN[0] + (i % 4) * 64; y = SWATCH_ORIGIN[1] + (i // 4) * 64
        canvas[y:y + 64, x:x + 64] = hexc(P[name])
    canvas = np.clip(canvas, 0, 1)
    rgba = np.concatenate([canvas, np.ones((TEX, TEX, 1))], axis=2)
    img = bpy.data.images.new("yaongi_atlas", TEX, TEX, alpha=False)
    img.pixels.foreach_set(rgba.astype(np.float32).ravel())
    return img


# --------------------------------------------------------------------------------------------
# Parts
# --------------------------------------------------------------------------------------------

def ellipsoid(bm, centre, radii, uv, segs=12, rings=8, rot=None):
    def pt(d):
        q = Vector((d.x * radii[0], d.y * radii[1], d.z * radii[2]))
        if rot:
            q = rot @ q
        return centre + q
    build_sphere(bm, pt, lambda u, v: uv, segs=segs, rings=rings)


def capsule(pts, radii, start=True, end=True):
    """Extend a tube's centre line with quarter-circle rings so its ends are round domes."""
    pts, radii = list(pts), list(radii)
    for at_end in ((False,) if start else ()) + ((True,) if end else ()):
        i, j = (-1, -2) if at_end else (0, 1)
        ax = (pts[i] - pts[j]).normalized()
        r = radii[i]
        dome = [(pts[i] + ax * r * math.cos(f), r * math.sin(f)) for f in (math.radians(a) for a in (75, 55, 30))]
        if at_end:
            pts += [p for p, _ in dome]; radii += [q for _, q in dome]
        else:
            pts = [p for p, _ in reversed(dome)] + pts; radii = [q for _, q in reversed(dome)] + radii
    return pts, radii


def make_head(bm):
    build_sphere(bm, head_point, lambda u, v: region_uv(R_HEAD, u, v), segs=36, rings=22, lat_min=math.radians(-62))


def make_goggles(bm):
    """Round lab goggles pushed up on the forehead: two brass rings joined by a little bridge, a strap
    round the head."""
    frame = swatch_uv("brass")
    z = HEAD_C.z + 0.150
    tilt = math.radians(-40.0)   # pushed up: the rings look up a little
    front_y = HEAD_C.y - HEAD_R * HEAD_SY * 0.92 * 0.80 - 0.012
    for s in (-1, 1):
        c = Vector((s * 0.110, front_y, z))
        n = 20
        ring = []
        for i in range(n + 1):
            t = 2 * math.pi * i / n
            q = Vector((0.064 * math.cos(t), 0.0, 0.064 * math.sin(t)))
            ring.append(c + Matrix.Rotation(tilt, 3, "X") @ q)
        build_tube(bm, ring, [0.014] * len(ring), 6, lambda u, v: frame, up_hint=Vector((0, -1, 0)))
        # (no lens disc: one opaque material would hide the eyes; the frame alone reads as goggles)
    a = Vector((-0.050, front_y - 0.004, z + 0.004)); b = Vector((0.050, front_y - 0.004, z + 0.004))
    build_tube(bm, [a, (a + b) * 0.5 + Vector((0.0, -0.010, 0.012)), b], [0.010] * 3, 8, lambda u, v: frame)
    # The strap: on the head's surface at the goggles' height, from one ring's outer edge round the back
    # to the other (the back is +y), so nothing sticks out at the sides.
    k = math.sqrt(max(0.0, 1.0 - ((z - HEAD_C.z) / (HEAD_R * HEAD_SZ)) ** 2)) * 0.995
    n = 20
    strap = []
    for i in range(n + 1):
        t = -0.66 * math.pi + 1.32 * math.pi * i / n
        strap.append(HEAD_C + Vector((HEAD_R * HEAD_SX * k * math.sin(t), HEAD_R * HEAD_SY * k * math.cos(t), z - HEAD_C.z)))
    build_tube(bm, strap, [0.008] * len(strap), 6, lambda u, v: swatch_uv("brass_dark"))


ES = 12  # ear ring segments


def ear_path(side):
    """Upright, pointed, leaning a little outwards; the root sinks into the head."""
    s = side
    return [Vector((s * 0.150, -0.020, 0.990)), Vector((s * 0.178, -0.020, 1.060)),
            Vector((s * 0.205, -0.020, 1.125)), Vector((s * 0.228, -0.020, 1.185))]


def make_ear(bm, side):
    p = ear_path(side)
    pts = bezier(p[0], p[1], p[2], p[3], 7)
    radii = [0.100, 0.098, 0.086, 0.068, 0.046, 0.024, 0.008]
    build_tube(bm, pts, radii, ES, lambda u, v: region_uv(R_EAR, u, v), up_hint=Vector((1.0, 0.0, 0.0)), squash=0.36)
    return p[0]


def make_pocket(bm):
    """A chest pocket on the coat's left with three test tubes (red, green, blue tops) in it."""
    c = Vector((0.120, -0.175, 0.290))
    rot = Matrix.Rotation(math.radians(-24), 3, "Z")
    # a flat, wide pocket (a round one read as a pompom), the tubes in front of its top edge
    ellipsoid(bm, c, (0.070, 0.012, 0.042), swatch_uv("coat_dark"), 12, 6, rot)
    for k, (dx, name) in enumerate(((-0.040, "tube1"), (0.000, "tube2"), (0.040, "tube3"))):
        base = c + rot @ Vector((dx, -0.010, 0.000))
        top = 0.120 - 0.020 * (k % 2)
        build_tube(bm, [base, base + Vector((0, 0, top))], [0.019, 0.019], 8, lambda u, v, n=name: swatch_uv(n), up_hint=Vector((0, -1, 0)))   # the coloured potion
        ellipsoid(bm, base + Vector((0, 0, top + 0.008)), (0.022, 0.022, 0.014), swatch_uv("cork"), 8, 4)
    ellipsoid(bm, c + rot @ Vector((0, -0.024, -0.012)), (0.068, 0.010, 0.030), swatch_uv("coat_dark"), 12, 6, rot)   # the pocket's front over the tubes' feet


def make_body(bm):
    build_sphere(bm, body_point, lambda u, v: region_uv(R_BODY, u, v), segs=24, rings=12, lat_min=math.radians(-65))
    sock = swatch_uv("sock")
    for s in (-1, 1):  # round feet poking out forward
        rot = Matrix.Rotation(s * math.radians(14), 3, "Z")
        ellipsoid(bm, Vector((s * 0.105, -0.085, 0.048)), (0.076, 0.105, 0.052), sock, 12, 7, rot)
    make_tail(bm)


def make_tail(bm):
    """A long thin cat tail: out of the back toward the cat's left (+X), sweeping up, a little fuller
    at its rainbow tip (painted)."""
    p0 = Vector((0.04, 0.180, 0.170))
    pts = bezier(p0, Vector((0.22, 0.42, 0.10)), Vector((0.46, 0.46, 0.55)), Vector((0.30, 0.30, 0.86)), 18)
    radii = []
    for i in range(len(pts)):   # a long thin cat tail, a little fuller at the tip
        t = i / (len(pts) - 1)
        radii.append(0.040 + 0.008 * t)
    pts, radii = capsule(pts, radii)
    build_tube(bm, pts, radii, 16, lambda u, v: region_uv(R_TAIL, u, v), up_hint=Vector((0, -1, 0)))


# Short thick mitten arms (the same shape as puppy.py's) in the coat's sleeves, hanging along the sides.
SHOULDER = {1: Vector((0.180, 0.000, 0.465)), -1: Vector((-0.180, 0.000, 0.465))}
HAND = {1: Vector((0.262, -0.030, 0.290)), -1: Vector((-0.262, -0.030, 0.290))}
ARM_R = 0.056
PAW_R = 0.064


def make_arm(bm, side):
    S, H = SHOULDER[side], HAND[side]
    ax = (H - S).normalized()
    root = S - ax * ARM_R * 0.9
    n = 4
    line = [root.lerp(H, i / (n - 1)) for i in range(n)]
    radii = [ARM_R * (1.0 + 0.04 * math.sin(math.pi * i / (n - 1))) for i in range(n)]
    pts, radii = capsule(line, radii, end=False)
    sleeve = swatch_uv("coat")
    build_tube(bm, pts, radii, 12, lambda u, v: sleeve, up_hint=Vector((0, 0, 1)))
    rot = Vector((1, 0, 0)).rotation_difference(ax).to_matrix()
    ellipsoid(bm, H + ax * PAW_R * 0.10, (PAW_R * 1.05, PAW_R, PAW_R * 0.97), swatch_uv("sock"), 14, 8, rot)
    return H


FLASK_AT = HAND[-1] + Vector((-0.030, -0.120, 0.030))   # out in front of the right paw: the arm hides none of it


def make_flask(bm, at):
    """A round-bottomed flask held in the right paw: the coloured potion in the bulb, a glass neck, a rim."""
    ellipsoid(bm, at, (0.062, 0.062, 0.058), swatch_uv("liquid"), 12, 7)
    # the neck, one closed tube (two stacked ones would weld into an open seam): potion in its lower
    # part, then glass (darker than the sky so it reads); a wide rim
    neck = [at + Vector((0, 0, z)) for z in (0.040, 0.084, 0.086, 0.135)]
    build_tube(bm, neck, [0.026] * 4, 10, lambda u, v: swatch_uv("liquid" if v < 0.5 else "glass"), up_hint=Vector((0, -1, 0)))
    build_tube(bm, [at + Vector((0, 0, 0.132)), at + Vector((0, 0, 0.150))], [0.034, 0.034], 10, lambda u, v: swatch_uv("cork"), up_hint=Vector((0, -1, 0)))
    for dx, dz, r in ((0.018, 0.150, 0.012), (-0.010, 0.180, 0.009)):   # two little bubbles above it
        ellipsoid(bm, at + Vector((dx, 0.0, dz)), (r, r, r), swatch_uv("liquid"), 6, 4)


# --------------------------------------------------------------------------------------------
# Scene assembly
# --------------------------------------------------------------------------------------------

def make_material(img):
    mat = bpy.data.materials.new("Yaongi")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.75
    bsdf.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.25
    return mat


SCALE = 1.0   # no correction: parts are authored at final size: ~1.19 m with the ears (the fox 1.30 m)


def mesh_object(name, bm, pivot_world, parent, parent_pivot, mat):
    bmesh.ops.translate(bm, verts=bm.verts, vec=-pivot_world)
    bmesh.ops.scale(bm, verts=bm.verts, vec=(SCALE, SCALE, SCALE))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    me.shade_smooth()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    ob.location = (pivot_world - parent_pivot) * SCALE
    return ob


def empty(name, loc_world, parent, parent_pivot, size=0.03):
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_size = size
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    ob.location = (loc_world - parent_pivot) * SCALE
    return ob


def build(face=None):
    img = build_atlas(face)
    mat = make_material(img)
    origin = Vector((0, 0, 0))
    root = empty("Yaongi", origin, None, origin, 0.2)
    bm = new_bm(); make_body(bm)
    body = mesh_object("Body", bm, origin, root, origin, mat)
    bm = new_bm(); make_head(bm)
    head = mesh_object("Head", bm, NECK, body, origin, mat)
    for side, nm in ((1, "L"), (-1, "R")):
        bm = new_bm(); base = make_ear(bm, side)
        mesh_object("Ear" + nm, bm, base, head, NECK, mat)
    for side, nm in ((1, "L"), (-1, "R")):
        bm = new_bm(); paw = make_arm(bm, side)
        arm = mesh_object("Arm" + nm, bm, SHOULDER[side], body, origin, mat)
        empty("Hand" + nm, paw, arm, SHOULDER[side])
        if side == -1:
            bm = new_bm(); make_flask(bm, FLASK_AT)
            mesh_object("Flask", bm, SHOULDER[side], arm, SHOULDER[side], mat)
    bm = new_bm(); make_goggles(bm)   # the small props are their own meshes (see the header)
    mesh_object("Goggles", bm, NECK, head, NECK, mat)
    bm = new_bm(); make_pocket(bm)
    mesh_object("Pocket", bm, origin, body, origin, mat)
    return root, img


PROPS = ("Goggles", "Pocket", "Flask")
PROP_OUTLINE = 0.005   # the props' outline in a render (the body's: dugi_portrait.OUTLINE)


def add_outlines(dp, outline_mat):
    """The storybook outline (dugi_portrait.add_outline) on every mesh: the body's width, the small
    props PROP_OUTLINE (see the header)."""
    body = dp.OUTLINE
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        dp.OUTLINE = PROP_OUTLINE if o.name in PROPS else body
        dp.add_outline(o, outline_mat)
    dp.OUTLINE = body


def _rotate_about_origin(ob, q):
    mw = ob.matrix_world.copy()
    loc = mw.translation.copy()
    ob.matrix_world = Matrix.Translation(loc) @ q.to_matrix().to_4x4() @ Matrix.Translation(-loc) @ mw


def pose_point(node, tip, target):
    """Swing `node` about its pivot so `tip` (a child empty) points at `target`."""
    bpy.context.view_layer.update()
    S = node.matrix_world.translation.copy()
    T = tip.matrix_world.translation.copy()
    _rotate_about_origin(node, (T - S).rotation_difference(Vector(target) - S))
    bpy.context.view_layer.update()


def stats():
    tris = 0; meshes = 0
    deps = bpy.context.evaluated_depsgraph_get()
    for ob in bpy.context.scene.objects:
        if ob.type == "MESH":
            meshes += 1
            me = ob.evaluated_get(deps).to_mesh()
            me.calc_loop_triangles()
            tris += len(me.loop_triangles)
    pts = [(ob.matrix_world @ v.co) for ob in bpy.context.scene.objects if ob.type == "MESH" for v in ob.data.vertices]
    bounds = [round(min(p[i] for p in pts), 3) for i in range(3)] + [round(max(p[i] for p in pts), 3) for i in range(3)]
    return dict(bounds_min_max=bounds, meshes=meshes, triangles=tris)


def render_preview(path, size, turn=-28.0):
    """A front 3/4 view in the portraits' storybook look (dugi_portrait.py: cel ramp, warm key sun,
    brown outline), transparent PNG."""
    import dugi_portrait as dp
    root = bpy.data.objects["Yaongi"]
    root.rotation_euler = (0.0, 0.0, math.radians(turn))
    bpy.context.view_layer.update()
    dp.CAM_POS = Vector((0.0, -4.0, 0.68))
    dp.CAM_TGT = Vector((0.0, 0.0, 0.66))
    dp.LENS = 70.0
    scene = dp.setup_scene(size)
    scene.render.image_settings.file_format = "PNG"
    outline_mat = dp.make_outline_material()
    chars = [o for o in bpy.data.objects if o.type == "MESH"]
    for m in {s.material for o in chars for s in o.material_slots if s.material}:
        dp.toon(m)
    add_outlines(dp, outline_mat)
    scene.render.filepath = os.path.abspath(path)
    bpy.ops.render.render(write_still=True)
    print("YAONGI_PREVIEW", scene.render.filepath)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {"out": None, "preview": None, "size": "768"}
    i = 0
    while i < len(argv):
        k = argv[i].lstrip("-")
        if k in opts and i + 1 < len(argv):
            opts[k] = argv[i + 1]; i += 2
        else:
            i += 1
    return opts


if __name__ == "__main__":
    opts = parse_args()
    bc.clear_scene()
    build()
    print("YAONGI_STATS", stats())
    if opts["out"]:
        bc.export_glb(opts["out"])
        print("YAONGI_EXPORTED", opts["out"])
    if opts["preview"]:
        render_preview(opts["preview"], int(opts["size"]))
