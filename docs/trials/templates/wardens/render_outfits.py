"""Renders the outfit portraits gen_assets.py puts in the icon atlas: the warden in each of the ten outfits, her head and shoulders,
128 x 128 with a clear background, into icon-sources/outfits/<Outfit>.png.

Each outfit's four parts (head, body, legs, feet) are imported from HeliX's modular-women models (Quaternius, CC0) into a scene of
their own, lit by one sun and a pale sky, and rendered through an orthographic camera from the front and a little to her left.

Run with Blender 5.1:  blender -b -P render_outfits.py
"""
import math
import os

import bpy
import mathutils

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = "/home/rknopf/projects/github/whirlinggizmo/helix/examples/assets/models/modular-women/"
OUT = os.path.join(HERE, "icon-sources", "outfits")
OUTFITS = ["Adventurer", "Casual", "Formal", "Medieval", "Punk", "SciFi", "Soldier", "Suit", "Witch", "Worker"]


def main():
    os.makedirs(OUT, exist_ok=True)
    scene = bpy.data.scenes.new("WardensIcons")
    bpy.context.window.scene = scene

    camera = bpy.data.objects.new("IconCam", bpy.data.cameras.new("IconCam"))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 0.85
    camera.location = (1.2, -3.0, 1.62)
    camera.rotation_euler = (mathutils.Vector((0, 0, 1.47)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(camera)
    scene.camera = camera

    sun = bpy.data.objects.new("IconSun", bpy.data.lights.new("IconSun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)

    world = bpy.data.worlds.new("IconWorld")
    world.use_nodes = True
    sky = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    sky.inputs[0].default_value = (0.8, 0.8, 0.85, 1)
    sky.inputs[1].default_value = 0.9
    scene.world = world

    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.render.resolution_percentage = 100

    for outfit in OUTFITS:
        for o in list(scene.objects):
            if o not in (camera, sun):
                bpy.data.objects.remove(o, do_unlink=True)
        for part in ["Head", "Body", "Legs", "Feet"]:
            bpy.ops.import_scene.gltf(filepath=MODELS + outfit + "_" + part + ".glb")
        # The armature's bone shapes come in as spheres; they aren't hers.
        for o in scene.objects:
            if o.name.startswith("Icosphere"):
                o.hide_render = True
        scene.render.filepath = os.path.join(OUT, outfit + ".png")
        bpy.ops.render.render(write_still=True)


main()
