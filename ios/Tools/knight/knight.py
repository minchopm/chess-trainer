"""Models the knight's head and mane, and exports them for the app.

Run headless:

    blender --background --python ios/Tools/knight/knight.py -- --out DIR [--preview]

The knight is the one piece a lathe cannot turn. Cut as a flat silhouette and
bevelled it reads as stamped tin from close up, which is the one place the set
stops looking like a set. This builds it as a carved relief instead: the same
outline, swept with a thickness that varies along it — thin at the ears and the
muzzle, full at the cheek and the neck — with a rounded rim and a domed face,
which is what a carved piece actually is.

Nothing here is downloaded. The outline is the app's own, and the geometry is
generated, so the piece carries no licence into a shipped app.
"""

import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

# ── The outline ────────────────────────────────────────────────────────────
#
# Traced anticlockwise from the base of the neck: up the crest, over the poll,
# out along the ears, down the forehead and the bridge of the nose, round the
# muzzle, back under the jaw, and down the throat. Beziers are given as
# (control1, control2, end); straight runs as points.

# Anchors, anticlockwise from the base of the neck: up the crest, over the
# poll, out along the ears, down the face, round the muzzle, back under the jaw
# and down the throat into the chest. A `True` marks a corner the curve is not
# allowed to round off — the two ear tips, the notch between them, the throat,
# and where the neck meets the collar.
#
# The proportions are the reference set's, measured off its profile rather than
# guessed at: the neck is broad and flares to the collar, the face is a long
# straight fall forward and down, the muzzle is blunt, and the ears are small
# and set close. The earlier head had a narrow neck, a pointed muzzle and a
# sawtooth mane, which is a different horse entirely.

CREST = [
    (-0.168, 0.500, True),   # tucked in where the neck meets the collar
    (-0.192, 0.566, False), (-0.189, 0.632, False), (-0.189, 0.665, False),
    (-0.193, 0.698, False), (-0.201, 0.731, False), (-0.207, 0.764, False),
    (-0.214, 0.797, False), (-0.220, 0.830, False), (-0.224, 0.863, False),
    (-0.225, 0.896, False),  # the crest at its fullest, halfway up
    (-0.224, 0.929, False), (-0.218, 0.962, False), (-0.214, 0.978, False),
    (-0.205, 1.004, False), (-0.191, 1.030, False), (-0.179, 1.047, False),
    (-0.164, 1.065, False), (-0.149, 1.082, False), (-0.129, 1.099, False),
    (-0.106, 1.116, False),
]

# What sits on top is mostly not ears. It is the mane, cut off square — a flat
# block with sharp corners standing above the forehead — with one small ear
# showing behind it and the other hidden entirely. Drawn as two tall triangles,
# which is the obvious reading of a knight's head, it comes out a rabbit; and
# rounding these corners loses the one thing that makes the top read as cut
# rather than moulded.
EARS = [
    (-0.090, 1.134, False),  # up out of the skull
    (-0.077, 1.143, True),   # the ear, barely clearing the mane in profile
    (-0.068, 1.150, True),
    (-0.059, 1.145, True),
    (-0.046, 1.143, True),   # the notch behind the mane block
    (-0.010, 1.151, True),   # the block's back corner
    (0.056, 1.160, True),    # its front corner, and the highest point
]

FACE = [
    (0.058, 1.151, False), (0.059, 1.134, False), (0.059, 1.125, False),
    (0.061, 1.116, False), (0.065, 1.099, False), (0.074, 1.091, False),
    (0.092, 1.074, False), (0.114, 1.056, False), (0.135, 1.039, False),
    (0.156, 1.021, False), (0.178, 1.004, False), (0.202, 0.987, False),
    (0.215, 0.978, False), (0.266, 0.943, False),
    # The muzzle: the front edge runs all but straight down before it turns
    # under. A taper here makes a fox, and a round makes a seal.
    (0.277, 0.926, False), (0.281, 0.909, False), (0.281, 0.900, False),
    (0.276, 0.883, False), (0.261, 0.866, False), (0.253, 0.856, True),
    # Under the jaw, back to the throat.
    (0.180, 0.852, False), (0.100, 0.850, False),
    (0.042, 0.848, True),    # the throat notch, tucked in behind the jaw
]

THROAT = [
    (0.051, 0.839, False), (0.058, 0.831, False), (0.088, 0.797, False),
    (0.117, 0.764, False), (0.143, 0.731, False), (0.166, 0.698, False),
    (0.186, 0.665, False), (0.199, 0.632, False), (0.207, 0.599, False),
    (0.209, 0.566, False),
    (0.195, 0.500, True),
]

ANCHORS = CREST + EARS + FACE + THROAT


def catmull(anchors, steps=8):
    """A closed curve through every anchor, breaking at the corners.

    Beziers with hand-placed handles were the first way this was written, and
    every change to the shape meant moving four numbers to move one point.
    These anchors are measurements, so the curve is fitted to them instead.
    """
    count = len(anchors)
    points = []
    for i in range(count):
        x0, y0, _ = anchors[(i - 1) % count]
        x1, y1, corner1 = anchors[i]
        x2, y2, corner2 = anchors[(i + 1) % count]
        x3, y3, _ = anchors[(i + 2) % count]
        points.append((x1, y1))
        if corner1 and corner2:
            continue           # a straight run between two corners
        for step in range(1, steps):
            t = step / steps
            t2, t3 = t * t, t * t * t
            points.append((
                0.5 * ((2 * x1) + (-x0 + x2) * t + (2 * x0 - 5 * x1 + 4 * x2 - x3) * t2
                       + (-x0 + 3 * x1 - 3 * x2 + x3) * t3),
                0.5 * ((2 * y1) + (-y0 + y2) * t + (2 * y0 - 5 * y1 + 4 * y2 - y3) * t2
                       + (-y0 + 3 * y1 - 3 * y2 + y3) * t3),
            ))
    return points


def crest_strip(inset=0.055, first=4, last=17):
    """The mane: a raised strip down the back of the neck.

    The reference has no sawtooth. What it has is a ridge running down the
    crest, which is what a mane looks like on a piece that is turned rather
    than carved. It stops below the ears — carried all the way up it breaks out
    through the back of the skull, because the outline turns in there and a
    strip offset sideways does not.
    """
    run = [(x, y) for x, y, _ in CREST[first:last + 1]]
    inner = []
    for i, (x, y) in enumerate(run):
        ax, ay = run[max(0, i - 1)]
        bx, by = run[min(len(run) - 1, i + 1)]
        tx, ty = bx - ax, by - ay
        length = math.hypot(tx, ty) or 1.0
        # Inwards: the back edge is traced upwards, so that is to its right.
        inner.append((x + ty / length * inset, y - tx / length * inset))
    return run + list(reversed(inner))


def bezier(p0, c1, c2, p3, steps):
    for i in range(1, steps + 1):
        t = i / steps
        u = 1 - t
        yield (
            u ** 3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p3[0],
            u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p3[1],
        )


def trace(start, moves, curve_steps=20):
    points = [start]
    for move in moves:
        if move[0] == "l":
            points.append(move[1])
        else:
            points.extend(bezier(points[-1], move[1], move[2], move[3], curve_steps))
    # Closed: drop a duplicated last point if it lands on the first.
    if (points[0][0] - points[-1][0]) ** 2 + (points[0][1] - points[-1][1]) ** 2 < 1e-8:
        points.pop()
    return points


def normals(points):
    """Outward normal at every point, from the neighbours' direction."""
    out = []
    count = len(points)
    for i in range(count):
        a = points[i - 1]
        b = points[(i + 1) % count]
        tx, ty = b[0] - a[0], b[1] - a[1]
        length = math.hypot(tx, ty) or 1.0
        # Anticlockwise outline: the outward normal is the tangent turned right.
        out.append((ty / length, -tx / length))
    return out


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def thickness(point, full, ear_thin=0.55, nose_thin=0.42):
    """How deep the carving is at a point on the outline.

    A carved head is not a slab. The cheek and the neck carry the mass, the
    muzzle narrows, and the ears are almost flat — get that wrong and the piece
    reads as a silhouette cut out of sheet, which is exactly what the old one
    was.
    """
    x, y = point
    ears = smoothstep(1.05, 1.16, y)
    nose = smoothstep(0.19, 0.31, x)
    return full * (1 - ear_thin * ears) * (1 - nose_thin * nose)


def slab(name, points, full, material, bevel=0.028):
    """The outline, given depth.

    A filled curve rather than a mesh built by hand. Blender's curve code
    tessellates a concave outline correctly, extrudes it and rolls the rim over
    in one step; every hand-rolled version of this — sweeping rings, filling
    with a triangle fan, subdividing and solidifying — either bridged the
    throat notch or blew up into spikes, which is a great deal of work to
    arrive at a worse horse.
    """
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "2D"
    data.fill_mode = "BOTH"
    data.resolution_u = 1

    spline = data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for index, (x, y) in enumerate(points):
        spline.points[index].co = (x, y, 0.0, 1.0)
    spline.use_cyclic_u = True

    # Extruded through the thickness, with the rim rolled over. The bevel eats
    # into the outline, so the extrusion is shortened by it: the piece ends up
    # `full` deep in total either way.
    data.extrude = max(0.0, full - bevel)
    data.bevel_depth = bevel
    data.bevel_resolution = 4

    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj


def carve(obj, dome, reach, points):
    """Turns the flat faces of an extruded outline into domed ones.

    An extrusion has two flat sides and reads as a plaque. Lifting each face
    towards its middle, in proportion to how far it is from the edge, is what
    makes it read as something cut out of a solid.
    """
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    mesh = obj.data

    peak = max(abs(v.co.z) for v in mesh.vertices)
    for vert in mesh.vertices:
        # Only the faces, not the rim that was just rolled over.
        if abs(vert.co.z) < peak * 0.92:
            continue
        gap = min(math.hypot(vert.co.x - x, vert.co.y - y) for x, y in points)
        lift = math.sin(min(1.0, gap / reach) * math.pi / 2)
        vert.co.z += math.copysign(dome * lift, vert.co.z)

    for polygon in mesh.polygons:
        polygon.use_smooth = True
    obj.select_set(False)
    return obj


def eye(at, material):
    """A socket rather than a hole.

    Cutting through would mean cutting through a surface rounded on both sides,
    and the reference is not pierced there — it has an eye set into it with a
    highlight sitting in the corner.
    """
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.03, segments=20, ring_count=12,
                                         location=(at[0], at[1], 0))
    ball = bpy.context.active_object
    ball.name = "KnightEye"
    ball.scale = (1.0, 0.72, 4.6)
    ball.data.materials.append(material)
    for polygon in ball.data.polygons:
        polygon.use_smooth = True
    return ball


def build(name, points, full, material, dimple_at=None):
    mesh = relief(points, full)
    if dimple_at:
        dimple(mesh, dimple_at, 0.036, 0.018)
        mesh.normal_update()

    data = bpy.data.meshes.new(name)
    mesh.to_mesh(data)
    mesh.free()
    for polygon in data.polygons:
        polygon.use_smooth = True

    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)

    # Subdivision does the rest: the sweep gives clean quad loops, and one level
    # turns the facets into a surface.
    modifier = obj.modifiers.new("Subdivision", "SUBSURF")
    modifier.levels = 1
    modifier.render_levels = 1
    return obj


def surface(name, colour, metallic, roughness):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return material


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def look_at(camera, target):
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def preview(path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("World")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.024, 0.04, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 1.4

    # The outline lies in XY with the carving running through Z, so the shot
    # that shows it is straight down the Z axis.
    aim = (0.03, 0.86, 0.0)
    for position, energy in (((-1.1, 2.0, 2.4), 420), ((1.6, 0.2, 1.6), 140)):
        light = bpy.data.lights.new("key", "AREA")
        light.energy = energy
        light.size = 2.2
        node = bpy.data.objects.new("key", light)
        node.location = position
        look_at(node, aim)
        bpy.context.collection.objects.link(node)

    camera_data = bpy.data.cameras.new("camera")
    camera_data.lens = 52
    camera = bpy.data.objects.new("camera", camera_data)
    camera.location = (aim[0], aim[1], 2.05)
    look_at(camera, aim)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera

    scene.render.resolution_x = 520
    scene.render.resolution_y = 640
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[argv.index("--out") + 1] if "--out" in argv else "/tmp"

    clear()
    ivory = surface("Ivory", (0.86, 0.80, 0.68, 1), 0.0, 0.34)
    brass = surface("Brass", (0.72, 0.52, 0.24, 1), 0.85, 0.26)

    dark = surface("Eye", (0.05, 0.04, 0.035, 1), 0.1, 0.25)

    outline = catmull(ANCHORS)
    crest = crest_strip()
    head = carve(slab("KnightHead", outline, full=0.150, material=ivory), 0.045, 0.15, outline)
    mane = carve(slab("KnightMane", crest, full=0.118, material=brass, bevel=0.016), 0.02, 0.05, crest)
    # The mane stands a little proud of the head on both faces.
    mane.scale = (1.0, 1.0, 1.28)
    eye((0.055, 0.985), dark)

    # Photographed flat, before it is stood up: the preview looks straight down
    # at the silhouette, and rotating first puts the piece edge-on to it.
    if "--preview" in argv:
        preview(os.path.join(out, "knight-preview.png"))

    # Stood the way the app wants it: the silhouette across the board, facing
    # the opponent, sitting on the neck the lathe turns for it.
    for obj in (head, mane):
        obj.rotation_euler = (math.radians(90), 0.0, math.radians(-90))

    for obj in (head, mane):
        vs = obj.data.vertices if obj.type == "MESH" else []
        xs = [v.co.x for v in vs]; ys = [v.co.y for v in vs]; zs = [v.co.z for v in vs]
        box = (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)) if xs else None
        print(f"{obj.name} type {obj.type} verts {len(vs)} box {box}")
    print(f"OUTLINE {len(outline)} pts  CREST {len(crest)} pts")



    target = os.path.join(out, "knight.usdz")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (head, mane):
        obj.select_set(True)
    bpy.ops.wm.usd_export(filepath=target, selected_objects_only=True,
                          export_materials=True)
    print(f"EXPORTED {target}")


main()
