"""Fox island keeper (섬지기 여우) — the keeper of the second island 허턴섬 (issue #71, prototype looks),
generated entirely in Blender Python.

Run (headless):
    blender -b --factory-startup -P apps/lab3d/art_src/characters/fox.py -- \
        [--out apps/lab3d/assets/characters/fox.glb] [--preview fox_preview.png] [--size 768]

Same storybook chibi as Puppy and Dugi (same helpers, same single 1024 px atlas, same node/pivot
conventions, same shared face_kit expressions): a big round head a little wider than the bean body,
a short pointed muzzle with a small dark nose, upright pointed ears with dark tips, cream cheeks,
chin and bib, dark "socks" on the paws and feet, a big bushy tail with a cream tip. Calm and a little
shy: small bean eyes, a tiny closed smile, soft blush. Standing on its hind legs like Dugi/Puppy,
arms hanging along the sides.

The look (2026-11-06 user choice among three prototypes, issue #71): orange fur, a big fluffy tail with a
cream tip, a teal scarf with a knot and two hanging ends. The fox's name is not decided yet.

Blender: +Z up, the fox faces -Y; glTF/Godot: +Y up, faces +Z, left side = +X.
Node tree (no armature; each origin is its pivot):
    Fox                     (empty, origin on the ground between the feet)
      Body                  (mesh: body, feet, tail, scarf; pivot on the ground)
        Head                (mesh incl. cheek tufts, pivot at the neck)
          EarL / EarR       (mesh, pivot at the ear root)
        ArmL / ArmR         (one-segment mitten arm, pivot at the shoulder)
          HandL / HandR     (empty at the paw centre)
Budget: 6 meshes, 1 material, 1 texture (1024 px). Outline mesh contract as bread_cat.py (closed
shells, outward faces, smooth shading).
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

# storybook pastel: orange fur, cream face / bib / tail tip, dark brown socks and ear tips, teal scarf
P = dict(
    fur="#e98b45", fur_shade="#d6783a", ear_tip="#5a3426", cream="#fff4e2", blush="#ff9e9a",
    eye="#2a1a14", nose="#3a2218", mouth="#6b3424", tongue="#ff7f8c", sock="#5a3426",
    scarf="#4fb0a8", scarf_dark="#37908a",
)
# Atlas layout (pixels, origin bottom-left like Blender UVs)
R_HEAD = (0, 512, 1024, 1024)
R_EAR = (0, 256, 256, 512)
R_TAIL = (256, 256, 512, 512)
R_BODY = (512, 256, 768, 512)
SWATCH_ORIGIN = (768, 0)  # 4 x 4 swatches of 64 px
SWATCHES = ["fur", "cream", "sock", "scarf", "scarf_dark", "nose"]


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
HEAD_SX, HEAD_SY, HEAD_SZ = 1.16, 0.96, 0.96   # a round face, a little wider (cheek ruff)
HEAD_C = Vector((0.0, -0.02, 0.815))
NECK = Vector((0.0, 0.0, 0.560))
BODY_C = Vector((0.0, 0.015, 0.300))
BODY_R = Vector((0.225, 0.205, 0.280))          # a slimmer bean than Puppy
EYE_X, EYE_Z, EYE_RX, EYE_RZ = 0.122, -0.012, 0.022, 0.029   # small calm beans
NOSE_Z = -0.092
MUZZLE = (0.0, -0.100, 0.085, 0.070, 0.058)    # bump centre (x, z), half-sizes, height (m): a short pointed snout


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
    # cream: the muzzle and both cheeks sweeping out under the eyes (the fox's white face), and the chin
    cheeks = np.minimum(sd_ellipse(qx, qz, -0.150, -0.140, 0.150, 0.100), sd_ellipse(qx, qz, 0.150, -0.140, 0.150, 0.100))
    mask = np.minimum(np.minimum(cheeks, sd_ellipse(qx, qz, 0.0, -0.115, 0.075, 0.075)), qz + 0.19)
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
            blend(img, smooth_fill(sd_ellipse(qx, qz, ex - 0.007, ez + 0.010, 0.0075, 0.008), aa) * front, np.ones(3))
    fk.brows(img, qx, qz, front, aa, EYE_X, EYE_Z + 0.056, face.get("brows"), hexc(P["ear_tip"]))
    nz = NOSE_Z   # a small dark rounded nose with one shine
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
    """u = around, v = root (0) -> tip (1): a cream tip."""
    u, v = region_grid(R_TAIL)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    blend(img, np.clip((0.35 - v) * 2, 0, 1), hexc(P["fur_shade"]), 0.6)
    blend(img, smooth_fill(0.76 - v, 0.04), hexc(P["cream"]))
    return img


def paint_body():
    u, v = region_grid(R_BODY)
    lon = (u - 0.5) * 2 * math.pi
    lat = (v - 0.5) * math.pi
    dy = -np.cos(lon) * np.cos(lat)
    img = np.zeros(u.shape + (3,)); img[...] = hexc(P["fur"])
    blend(img, np.clip((dy + 0.2) * 0.8, 0, 1), hexc(P["fur_shade"]), 0.4)
    bib = sd_ellipse(lon, lat, 0.0, 0.25, 0.70, 1.20)   # cream chest and tummy
    blend(img, smooth_fill(bib * 0.3, 0.02), hexc(P["cream"]))
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
    img = bpy.data.images.new("fox_atlas", TEX, TEX, alpha=False)
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
    cream = swatch_uv("cream")
    for s in (-1, 1):  # cheek ruff: a cream tuft on each side sweeping back
        rot = Matrix.Rotation(s * math.radians(-28), 3, "Z")
        ellipsoid(bm, HEAD_C + Vector((s * 0.322, -0.040, -0.095)), (0.062, 0.050, 0.040), cream, 12, 7, rot)


ES = 12  # ear ring segments


def ear_path(side):
    """Upright, pointed, leaning a little outwards; the root sinks into the head."""
    s = side
    return [Vector((s * 0.150, -0.030, 0.985)), Vector((s * 0.190, -0.030, 1.080)),
            Vector((s * 0.235, -0.030, 1.190)), Vector((s * 0.275, -0.030, 1.300))]


def make_ear(bm, side):
    p = ear_path(side)
    pts = bezier(p[0], p[1], p[2], p[3], 7)
    radii = [0.098, 0.100, 0.093, 0.080, 0.060, 0.036, 0.012]
    build_tube(bm, pts, radii, ES, lambda u, v: region_uv(R_EAR, u, v), up_hint=Vector((1.0, 0.0, 0.0)), squash=0.36)
    return p[0]


def make_scarf(bm):
    """A teal scarf: a ring round the neck that sags a little in front (thinner at the back), a knot
    at the front left and two ends hanging from it, the longer one a little out."""
    a, b = swatch_uv("scarf"), swatch_uv("scarf_dark")
    c = Vector((0.0, -0.005, 0.532))
    n = 24
    ring, radii = [], []
    for i in range(n):
        t = 2 * math.pi * i / n
        front = max(0.0, -math.cos(t))
        ring.append(c + Vector((0.222 * math.sin(t), -0.200 * math.cos(t), -0.030 * front)))
        radii.append(0.036 + 0.010 * front)
    ring.append(ring[0]); radii.append(radii[0])
    build_tube(bm, ring, radii, 10, lambda u, v: a, up_hint=Vector((0, 0, 1)))
    k = c + Vector((0.085, -0.206, -0.030))
    ellipsoid(bm, k, (0.046, 0.034, 0.040), b, 10, 6)   # the knot
    for dx, ln, tilt in ((0.020, 0.150, -8.0), (-0.020, 0.100, 14.0)):   # the two ends
        rot = Matrix.Rotation(math.radians(tilt), 3, "Y")
        ellipsoid(bm, k + Vector((dx, -0.014, -ln * 0.78)), (0.036, 0.016, ln * 0.62), a, 10, 6, rot)
    for dx in (0.020, -0.020):   # darker tips
        ellipsoid(bm, k + Vector((dx, -0.016, -0.150 if dx > 0 else -0.108)), (0.037, 0.017, 0.016), b, 8, 4)


def make_body(bm):
    build_sphere(bm, body_point, lambda u, v: region_uv(R_BODY, u, v), segs=24, rings=12, lat_min=math.radians(-65))
    sock = swatch_uv("sock")
    for s in (-1, 1):  # dark round feet poking out forward
        rot = Matrix.Rotation(s * math.radians(14), 3, "Z")
        ellipsoid(bm, Vector((s * 0.105, -0.085, 0.048)), (0.076, 0.105, 0.052), sock, 12, 7, rot)
    make_scarf(bm)
    make_tail(bm)


def make_tail(bm):
    """A big fluffy tail: out of the back toward the fox's left (+X), sweeping up, a rounded plume
    that is thickest past the middle, a cream tip (painted)."""
    p0 = Vector((0.04, 0.160, 0.190))
    pts = bezier(p0, Vector((0.20, 0.36, 0.10)), Vector((0.62, 0.55, 0.36)), Vector((0.48, 0.26, 0.73)), 16)
    radii = []
    for i in range(len(pts)):
        t = i / (len(pts) - 1)
        radii.append(0.082 + 0.058 * math.sin(math.pi * min(1.0, t * 1.05) ** 0.9) - 0.050 * t ** 3)
    pts, radii = capsule(pts, radii)
    build_tube(bm, pts, radii, 16, lambda u, v: region_uv(R_TAIL, u, v), up_hint=Vector((0, -1, 0)))


# Short thick mitten arms (variant A of puppy.py): hanging along the sides, the paws dark socks.
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
    build_tube(bm, pts, radii, 12, lambda u, v: swatch_uv("fur"), up_hint=Vector((0, 0, 1)))
    rot = Vector((1, 0, 0)).rotation_difference(ax).to_matrix()
    ellipsoid(bm, H + ax * PAW_R * 0.10, (PAW_R * 1.05, PAW_R, PAW_R * 0.97), swatch_uv("sock"), 14, 8, rot)
    return H


# --------------------------------------------------------------------------------------------
# Scene assembly
# --------------------------------------------------------------------------------------------

def make_material(img):
    mat = bpy.data.materials.new("Fox")
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


SCALE = 1.0   # parts are authored at final size: ~1.30 m with the ears (Puppy 1.27 m with his hat)


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
    root = empty("Fox", origin, None, origin, 0.2)
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
    return root, img


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
    root = bpy.data.objects["Fox"]
    root.rotation_euler = (0.0, 0.0, math.radians(turn))
    bpy.context.view_layer.update()
    dp.CAM_POS = Vector((0.0, -4.0, 0.68))
    dp.CAM_TGT = Vector((0.0, 0.0, 0.66))
    dp.LENS = 70.0
    dp.OUTLINE = 0.012
    scene = dp.setup_scene(size)
    scene.render.image_settings.file_format = "PNG"
    outline_mat = dp.make_outline_material()
    chars = [o for o in bpy.data.objects if o.type == "MESH"]
    for m in {s.material for o in chars for s in o.material_slots if s.material}:
        dp.toon(m)
    for o in chars:
        dp.add_outline(o, outline_mat)
    scene.render.filepath = os.path.abspath(path)
    bpy.ops.render.render(write_still=True)
    print("FOX_PREVIEW", scene.render.filepath)


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
    print("FOX_STATS", stats())
    if opts["out"]:
        bc.export_glb(opts["out"])
        print("FOX_EXPORTED", opts["out"])
    if opts["preview"]:
        render_preview(opts["preview"], int(opts["size"]))
