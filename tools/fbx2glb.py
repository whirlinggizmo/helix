"""FBX models as GLB files, converted by Blender run headless: each FBX imported into an empty scene (Blender's own defaults, no user
preferences or add-ons) and exported as a binary glTF of the same name in the destination directory, with the glTF exporter's defaults
(+Y up, every mesh, its skin and joints, every action as an animation, materials without textures as factors).

  --opaque               every material opaque: its Principled BSDF's alpha 1 and nothing linked to it, rendered dithered. Quaternius's
                         FBX files carry an alpha of 0 that Blender reads as a transparent material, and exports as "MASK" with
                         its base color's alpha 0.
  --smooth-angle DEG     the meshes' normals smoothed by angle, as Blender's Shade Smooth by Angle does: the normals the FBX carries cleared,
                         its sharp edges forgotten, every face smooth, and an edge sharp where its faces meet at more than DEG degrees.
                         Without it, the normals are the FBX's as Blender imports them.

Sources are FBX files or directories (searched for *.fbx below them); the GLBs go flat into the destination, named after their FBX, written
over any there. Blender is `blender` on the PATH unless --blender names it; the tool runs it once for every file. Tested with Blender 5.1.2.

  python3 tools/fbx2glb.py <model.fbx or directory>... <destination directory> [--opaque] [--smooth-angle DEG] [--blender PATH]

The examples' Ultimate Modular Women (examples/assets/CREDITS.md has the command) were made with it."""
import argparse
import math
from pathlib import Path
import subprocess
import sys

try:
    import bpy
except ImportError:
    bpy = None

HERE = Path(__file__).resolve()


def opaque(material):
    """Make a material opaque: its Principled BSDF's alpha 1, unlinked, and Blender's dithered (opaque) render method."""
    if material.node_tree:
        for node in material.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                alpha = node.inputs['Alpha']
                for link in list(alpha.links):
                    material.node_tree.links.remove(link)
                alpha.default_value = 1.0
    material.surface_render_method = 'DITHERED'


def smooth(mesh_object, angle):
    """Smooth a mesh by angle in its own data: the custom normals cleared, every face smooth, an edge sharp where its faces' normals
    differ by more than angle (radians), the FBX's sharp edges dropped. Its modifiers (the armature's) are untouched."""
    bpy.ops.object.select_all(action='DESELECT')
    mesh_object.select_set(True)
    bpy.context.view_layer.objects.active = mesh_object
    if mesh_object.data.has_custom_normals:
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
    bpy.ops.object.shade_smooth_by_angle(angle=angle, keep_sharp_edges=False)


def convert(source, destination, make_opaque, smooth_angle):
    """Import one FBX into an empty scene, apply the options and export it as destination (a .glb)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source))
    if make_opaque:
        for material in bpy.data.materials:
            opaque(material)
    if smooth_angle is not None:
        for mesh_object in [o for o in bpy.data.objects if o.type == 'MESH']:
            smooth(mesh_object, math.radians(smooth_angle))
    bpy.ops.export_scene.gltf(filepath=str(destination), export_format='GLB')


def blender_main(argv):
    """Inside Blender: convert each source to its destination, pairs after the options."""
    parser = argparse.ArgumentParser(prog='fbx2glb (in Blender)')
    parser.add_argument('--opaque', action='store_true')
    parser.add_argument('--smooth-angle', type=float)
    parser.add_argument('pairs', nargs='+')
    args = parser.parse_args(argv)
    for source, destination in zip(args.pairs[0::2], args.pairs[1::2]):
        print(f'fbx2glb: {source} -> {destination}', flush=True)
        convert(Path(source), Path(destination), args.opaque, args.smooth_angle)


def main():
    """Find the sources, then run Blender once over all of them."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('paths', nargs='+', help='FBX files or directories, then the destination directory')
    parser.add_argument('--opaque', action='store_true', help='make every material opaque')
    parser.add_argument('--smooth-angle', type=float, metavar='DEG', help='smooth the normals by angle, sharp above DEG degrees')
    parser.add_argument('--blender', default='blender', help='the Blender program (default: blender on the PATH)')
    args = parser.parse_args()
    if len(args.paths) < 2:
        parser.error('give at least one source and the destination directory')
    *sources, destination = [Path(p) for p in args.paths]
    if args.smooth_angle is not None and not 0 <= args.smooth_angle <= 180:
        parser.error('--smooth-angle is between 0 and 180 degrees')
    files = []
    for source in sources:
        if source.is_dir():
            files += sorted(source.rglob('*.fbx'))
        elif source.is_file():
            files.append(source)
        else:
            parser.error(f'{source}: no such file or directory')
    if not files:
        parser.error('no FBX files among the sources')
    names = {}
    for f in files:
        if f.stem in names:
            parser.error(f'{f} and {names[f.stem]} would both be {f.stem}.glb')
        names[f.stem] = f
    destination.mkdir(parents=True, exist_ok=True)
    options = (['--opaque'] if args.opaque else []) + ([f'--smooth-angle={args.smooth_angle}'] if args.smooth_angle is not None else [])
    pairs = [str(p) for f in files for p in (f.resolve(), (destination / f'{f.stem}.glb').resolve())]
    command = [args.blender, '--background', '--factory-startup', '--python-exit-code', '1', '--python', str(HERE), '--', *options, *pairs]
    if subprocess.run(command).returncode != 0:
        sys.exit('fbx2glb: Blender failed')
    print(f'fbx2glb: {len(files)} GLB files in {destination}')


if __name__ == '__main__':
    if bpy is not None:
        blender_main(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    else:
        main()
