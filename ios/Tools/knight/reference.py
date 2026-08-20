"""Measures a reference piece, so a shape can be fitted to it rather than guessed.

    blender --background --python ios/Tools/knight/reference.py -- MODEL --out DIR

Renders the model orthographically from the side, the front and three quarters,
then scans the side and front views row by row and prints the outline as
numbers: how far the piece reaches forward and back at each height, and how deep
it is there. Both are given in *head-heights* — the distance from the crown to
the collar — so they can be read straight into a piece of any size.

This is all a downloaded model is good for here. Most of the good ones are
Creative Commons **NonCommercial**, which this app cannot use: it sells a
subscription and a one-off unlock, and it is GPLv3 besides, which forbids
adding a restriction like NC on top. Proportions are not the model; taking them
is what a reference is for, and nothing of it ships.

The shape itself lives in `TurnedPieces.knightAnchors`, and is looked at with

    RENDER_KNIGHT=1 swift test --package-path ios --filter KnightAngles

which renders the real geometry the app ships from four angles. It used to be
built here as well, and that was a mistake worth recording: two builders of the
same shape drift apart the moment one of them is changed.
"""

import bpy
import math
import os
import sys

from mathutils import Vector


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def bounds(objects):
    low = Vector((1e9,) * 3)
    high = Vector((-1e9,) * 3)
    for obj in objects:
        for corner in obj.bound_box:
            world = obj.matrix_world @ Vector(corner)
            for axis in range(3):
                low[axis] = min(low[axis], world[axis])
                high[axis] = max(high[axis], world[axis])
    return low, high


def look_at(node, target):
    node.rotation_euler = (Vector(target) - node.location).to_track_quat("-Z", "Y").to_euler()


def stage(objects, low, high):
    """Flat white against dark, so only the shape reads."""
    size = high - low
    centre = (high + low) / 2
    reach = max(size)

    surface = bpy.data.materials.new("Reference")
    surface.use_nodes = True
    shader = surface.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (0.9, 0.88, 0.84, 1)
    shader.inputs["Roughness"].default_value = 0.45
    for obj in objects:
        obj.data.materials.clear()
        obj.data.materials.append(surface)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.world = bpy.data.worlds.new("World")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes["Background"]
    background.inputs[0].default_value = (0.09, 0.10, 0.15, 1)

    for offset, energy in (((2.5, -3.0, 2.6), 900), ((-3.0, -1.5, 1.2), 300)):
        light = bpy.data.lights.new("key", "AREA")
        light.energy = energy * reach
        light.size = reach * 2
        node = bpy.data.objects.new("key", light)
        node.location = centre + Vector(offset) * reach
        look_at(node, centre)
        bpy.context.collection.objects.link(node)

    # Orthographic, or the measurements come out of a lens rather than a piece.
    lens = bpy.data.cameras.new("camera")
    lens.type = "ORTHO"
    lens.ortho_scale = reach * 1.15
    camera = bpy.data.objects.new("camera", lens)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
    scene.render.resolution_x = 560
    scene.render.resolution_y = 760
    return camera, centre, reach


def shoot(camera, centre, reach, out):
    scene = bpy.context.scene
    views = {"side": 0, "quarter": 45, "front": 90}
    for name, degrees in views.items():
        angle = math.radians(degrees)
        camera.location = centre + Vector((math.sin(angle), -math.cos(angle), 0)) * reach * 3
        look_at(camera, centre)
        scene.render.filepath = os.path.join(out, f"reference-{name}.png")
        bpy.ops.render.render(write_still=True)
    return {name: os.path.join(out, f"reference-{name}.png") for name in views}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if not argv:
        print(__doc__)
        return
    model = argv[0]
    out = argv[argv.index("--out") + 1] if "--out" in argv else "/tmp"

    clear()
    if model.lower().endswith((".glb", ".gltf")):
        bpy.ops.import_scene.gltf(filepath=model)
    else:
        bpy.ops.wm.usd_import(filepath=model)

    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    low, high = bounds(objects)
    camera, centre, reach = stage(objects, low, high)
    shot = shoot(camera, centre, reach, out)
    print(f"MESHES {len(objects)}  SIZE {tuple(round(v, 3) for v in (high - low))}")
    for name, path in shot.items():
        print(f"VIEW {name} {path}")
    print("\nScan them with ios/Tools/knight/measure.py")


main()
