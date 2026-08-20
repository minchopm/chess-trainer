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

START = (-0.185, 0.5)

OUTLINE = [
    ("c", (-0.275, 0.63), (-0.285, 0.8), (-0.245, 0.925)),
    ("l", (-0.208, 0.945)), ("l", (-0.232, 0.966)), ("l", (-0.196, 0.982)),
    ("l", (-0.22, 1.003)), ("l", (-0.184, 1.019)), ("l", (-0.208, 1.04)),
    ("l", (-0.17, 1.056)),
    ("c", (-0.15, 1.075), (-0.115, 1.092), (-0.078, 1.098)),
    ("l", (-0.088, 1.158)), ("l", (-0.03, 1.104)), ("l", (0.014, 1.156)),
    ("l", (0.046, 1.092)),
    ("c", (0.096, 1.07), (0.138, 1.028), (0.162, 0.972)),
    ("c", (0.198, 0.906), (0.238, 0.858), (0.272, 0.828)),
    ("l", (0.298, 0.812)), ("l", (0.302, 0.772)), ("l", (0.268, 0.76)),
    ("l", (0.276, 0.734)), ("l", (0.226, 0.722)),
    ("c", (0.17, 0.688), (0.09, 0.672), (0.036, 0.712)),
    ("c", (-0.008, 0.746), (-0.028, 0.79), (-0.02, 0.822)),
    ("c", (0.008, 0.76), (0.04, 0.64), (0.098, 0.52)),
]

# The mane: the seven scallops up the back of the crest, closed by a line
# running down inside the neck.
MANE_START = (-0.245, 0.925)
MANE = [
    ("l", (-0.208, 0.945)), ("l", (-0.232, 0.966)), ("l", (-0.196, 0.982)),
    ("l", (-0.22, 1.003)), ("l", (-0.184, 1.019)), ("l", (-0.208, 1.04)),
    ("l", (-0.17, 1.056)),
    ("c", (-0.15, 1.075), (-0.115, 1.092), (-0.078, 1.098)),
    ("l", (-0.055, 1.05)),
    ("c", (-0.12, 1.01), (-0.155, 0.965), (-0.168, 0.9)),
]


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

    outline = trace(START, OUTLINE)
    crest = trace(MANE_START, MANE)
    head = carve(slab("KnightHead", outline, full=0.150, material=ivory), 0.045, 0.15, outline)
    mane = carve(slab("KnightMane", crest, full=0.118, material=brass, bevel=0.016), 0.02, 0.05, crest)
    # The mane stands a little proud of the head on both faces.
    mane.scale = (1.0, 1.0, 1.28)
    eye((0.055, 0.985), dark)

    # Stood the way the app wants it: the silhouette across the board, facing
    # the opponent, sitting on the neck the lathe turns for it.
    for obj in (head, mane):
        obj.rotation_euler = (math.radians(90), 0.0, math.radians(-90))

    target = os.path.join(out, "knight.usdz")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (head, mane):
        obj.select_set(True)
    bpy.ops.wm.usd_export(filepath=target, selected_objects_only=True,
                          export_materials=True)
    print(f"EXPORTED {target}")

    if "--preview" in argv:
        preview(os.path.join(out, "knight-preview.png"))

    print(f"HEAD {head.name}  MANE {mane.name}")


main()
