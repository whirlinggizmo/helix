"""A game's shaders packed, from its own folder: what `haxelib run helix shader` runs (Run.hx hands it this command; the others, init and
site, are tools/game/'s in Haxe). From a checkout, `python3 tools/game.py shader` works on the game in the current folder.

  haxelib run helix shader [FILE.glsl ...] [--out DIR] [--sdl-gpu] [--watch]
                                                    the game's shaders packed (tools/pack_shader.py): shaders/*.glsl, or the files named,
                                                    into assets/shaders/<name>.hxshader (or --out), loaded as "shaders/<name>.hxshader";
                                                    --watch packs each again as it changes, until Ctrl+C

Python 3.8 or later; it needs PyYAML (python3 -m pip install pyyaml) and fetches sokol-shdc into the user's cache the first time
(BUILDING.md); with --sdl-gpu, SDL_GPU's translators into the library's build/deps too."""
import argparse
from pathlib import Path
import sys
import time

if sys.version_info < (3, 8):
    sys.exit('helix: Python 3.8 or later is needed; this is ' + sys.version.split()[0])

ROOT = Path(__file__).resolve().parents[1]
POLL = .25


def packer():
    """tools/pack_shader.py, loaded when a shader is packed: it needs PyYAML, which the other commands don't."""
    sys.path.insert(0, str(ROOT / 'tools'))
    try:
        import pack_shader
    except ImportError as error:
        if error.name == 'yaml':
            sys.exit('shader: packing needs PyYAML (python3 -m pip install pyyaml)')
        raise
    return pack_shader


def manifest_folder(out, game):
    """The root of the manifests (tools/gen_manifest.py's: one in each folder, a parent's naming its children's) that out is under: the
    highest folder from out up to game holding a manifest.json, whose tree is rewritten after a pack; None when there is none, as a game
    without a manifest needs nothing."""
    out, game = Path(out).resolve(), Path(game).resolve()
    folder = out
    found = None
    while True:
        if (folder / 'manifest.json').is_file():
            found = folder
        if folder == game or folder.parent == folder:
            return found
        folder = folder.parent


def shader(game, files, out, sdl_gpu, watch):
    """Packs the game's shaders (its shaders/*.glsl, or files) into out as <name>.hxshader, with SDL_GPU's dialects when sdl_gpu; with watch,
    again as each changes (and new ones in shaders/ when none were named), until Ctrl+C. A manifest among the assets is rewritten after a
    pack. Returns the outputs written."""
    game = Path(game)
    pack_shader = packer()
    shdc = pack_shader.shdc_path()
    out = game / out
    named = [game / f for f in files]

    def sources():
        return named or sorted((game / 'shaders').glob('*.glsl'))

    for source in named:
        if not source.is_file():
            sys.exit(f'shader: {relative(source, game)} is not a file')
    if not watch and not sources():
        sys.exit(f'shader: nothing to pack: no shaders/*.glsl in {game.resolve()} and no file named')
    written = []
    packed = {}

    def pack_changed():
        changed = False
        for source in sources():
            stamp = source.stat().st_mtime
            if packed.get(source) == stamp:
                continue
            packed[source] = stamp
            target = out / (source.stem + '.hxshader')
            try:
                pack_shader.pack(shdc, source, target, sdl_gpu)
            except SystemExit as error:
                if not watch:
                    raise
                print(f'shader: {source.name} failed, kept as it was: {error}', flush=True)
                continue
            print(f'shader: {relative(source, game)} -> {relative(target, game)}', flush=True)
            written.append(target)
            changed = True
        if changed:
            manifests = manifest_folder(out, game)
            if manifests:
                sys.path.insert(0, str(ROOT / 'tools'))
                import gen_manifest
                gen_manifest.write(manifests)
                print(f'shader: manifests rewritten under {relative(manifests, game)}', flush=True)

    pack_changed()
    if watch:
        print(f'shader: watching {"shaders/" if not named else f"{len(named)} file(s)"} for changes; Ctrl+C stops', flush=True)
        try:
            while True:
                time.sleep(POLL)
                pack_changed()
        except KeyboardInterrupt:
            pass
    return written


def relative(path, game):
    """path as the game's folder sees it, for a message; the path itself when it's elsewhere."""
    try:
        return Path(path).resolve().relative_to(Path(game).resolve()).as_posix()
    except ValueError:
        return str(path)


def main(argv=None):
    p = argparse.ArgumentParser(prog='haxelib run helix', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='command', required=True, metavar='command')
    a_shader = sub.add_parser('shader', help="the game's shaders packed into .hxshader assets")
    a_shader.add_argument('files', nargs='*', metavar='FILE.glsl', help='the shaders to pack; shaders/*.glsl when none is named')
    a_shader.add_argument('--out', default='assets/shaders', help='where the .hxshader files go (assets/shaders)')
    a_shader.add_argument('--sdl-gpu', action='store_true', help="with SDL_GPU's dialects, for an sdl3-gpu build (glslang and SPIRV-Cross, fetched)")
    a_shader.add_argument('--watch', action='store_true', help='pack again as a shader changes, until Ctrl+C')
    a = p.parse_args(argv)
    shader(Path.cwd(), a.files, a.out, a.sdl_gpu, a.watch)


if __name__ == '__main__':
    main()
