"""A game on -lib helix, from its own folder: a starter written, its shaders packed, its web build assembled for hosting. This is what
`haxelib run helix <command>` runs (Run.hx: haxelib starts it in the library's folder and passes the caller's, which the commands work in);
from a checkout, `python3 tools/game.py <command>` works on the game in the current folder.

  haxelib run helix init FOLDER                     a starter game in FOLDER (empty or not yet there): src/Main.hx and src/Game.hx (a
                                                    window title, a rectangle and a greeting), web.hxml, native.hxml, assets/, .gitignore
                                                    and a README with the commands
  haxelib run helix shader [FILE.glsl ...] [--out DIR] [--sdl-gpu] [--watch]
                                                    the game's shaders packed (tools/pack_shader.py): shaders/*.glsl, or the files named,
                                                    into assets/shaders/<name>.hxshader (or --out), loaded as "shaders/<name>.hxshader";
                                                    --watch packs each again as it changes, until Ctrl+C
  haxelib run helix site [--out DIR] [--zip [FILE]] [--title TITLE] [--js FILE] [--hxml FILE]
                                                    the web build assembled for hosting in out/site (or --out): index.html from the
                                                    library's template, app.js (the -js of web.hxml, built first), assets/ copied beside,
                                                    config.json and favicon.png from the game's folder when there; --zip writes it as a
                                                    zip with index.html at the root (out/<game>-web.zip, or FILE), what itch.io takes

The game's folder is the current one. Python 3.8 or later; `shader` needs PyYAML (python3 -m pip install pyyaml) and fetches sokol-shdc
into the user's cache the first time (BUILDING.md); with --sdl-gpu, SDL_GPU's translators into the library's build/deps too."""
import argparse
import os
from pathlib import Path
import shutil
import sys
import time
import zipfile

if sys.version_info < (3, 8):
    sys.exit('helix: Python 3.8 or later is needed; this is ' + sys.version.split()[0])

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / 'templates/index.html'
POLL = .25

# The starter game init writes, each file's text with {name} the game's (its folder's name), {title} its title.
STARTER = {
    'src/Main.hx': '''import helix.app.AppOptions;

/** The entry point, the same in the browser and natively: helix.App runs Game on the backend the build names (-D helix-backend). The
	options' identity names what HeliX keeps for the game (its cache: a folder natively, a database in the browser); the assets are the
	folder beside the page or the program ("assets", the default). */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "{name}";
		new Game(options);
	}
}
''',
    'src/Game.hx': '''import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** The game: init once the services are bound, frame once a display refresh, cleanup as the window closes. What needs a service (a
	Batch2D, a texture) is made in init, not in a field initializer: the object exists before HeliX does. */
class Game extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Window.title = "{title}";
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		// A world unit a logical pixel, from the top left: an unsized camera covers the framebuffer.
		camera.pixels(Window.pixelRatio);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x202840ff);
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0x66bfffff);
		batch.drawText("{title}", 60, 90, 48, 0x102030ff);
		batch.end();
		Graphics.endFrame();
	}
}
''',
    'web.hxml': '''# The browser build: haxe web.hxml -> out/web/app.js; `haxelib run helix site` puts the page around it.
-lib helix
-cp src
-D helix-backend=webgl2
-main Main
-debug
-js out/web/app.js
''',
    'native.hxml': '''# The native build (sokol on GL): haxe native.hxml -> out/native/Main; hxcpp compiles HeliX's adapters' C with it.
-lib helix
-cp src
-D helix-backend=sokol-gl
-main Main
-dce full
-D analyzer-optimize
-D HXCPP_COMPILE_THREADS=4
-cpp out/native
''',
    'assets/README.md': '''The game's files, loaded by their path from here (`Textures.load("player.png")`); `haxelib run helix shader` packs `shaders/*.glsl` into `shaders/` here.
''',
    '.gitignore': '''out/
''',
    'README.md': '''# {title}

A game on [HeliX](https://github.com/whirlinggizmo/helix) (`-lib helix`). `src/Game.hx` is the game, `src/Main.hx` starts it.

```console
haxe web.hxml                        # the browser build, out/web/app.js
haxelib run helix site --zip         # the page around it in out/site/, zipped for hosting (itch.io) as out/{name}-web.zip
haxe native.hxml && out/native/Main  # the native build (hxcpp), out/native/Main; it reads assets/ beside itself: copy (or link) the folder to out/native/assets
```

The dev loop, in two terminals: hotreload-hx's server rebuilds on save and swaps the code into the running page at <http://localhost:8064/>
(the assets served at /assets), and HeliX packs the game's shaders (`shaders/*.glsl`, loaded as `shaders/<name>.hxshader`) as they change.

```console
haxe -lib hotreload-hx --run hotreload.DevServer --port 8064 --mount /assets=assets web.hxml
haxelib run helix shader --watch
```
''',
}


def init(folder):
    """The starter game written into folder, which is made when missing; refuses one that has anything in it. Returns the files written,
    relative to it."""
    folder = Path(folder)
    if folder.exists() and (not folder.is_dir() or any(folder.iterdir())):
        sys.exit(f'init: {folder} is not empty; a starter goes in a new or empty folder')
    name = folder.resolve().name
    title = ' '.join(word[:1].upper() + word[1:] for word in name.replace('-', ' ').replace('_', ' ').split()) or 'Game'
    for relative, text in STARTER.items():
        target = folder / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text.replace('{name}', name).replace('{title}', title), encoding='utf-8', newline='\n')
    return list(STARTER)


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


def hxml_output(hxml, game, seen=None):
    """The -js path an hxml names (its last, through the hxml files it includes), relative to the game's folder as haxe resolves it, or
    None."""
    hxml = Path(hxml)
    seen = seen or set()
    if hxml.resolve() in seen:
        return None
    seen.add(hxml.resolve())
    found = None
    tokens = []
    for line in hxml.read_text(encoding='utf-8').splitlines():
        line = line.split('#', 1)[0].strip()
        if line:
            tokens += line.split()
    for i, token in enumerate(tokens):
        if token in ('-js', '--js') and i + 1 < len(tokens):
            found = Path(game) / tokens[i + 1]
        elif token.endswith('.hxml') and (Path(game) / token).is_file():
            included = hxml_output(Path(game) / token, game, seen)
            if included:
                found = included
    return found


def site(game, out, zip_file, title, js, hxml):
    """The game's web build assembled in out for hosting: index.html from the library's template with title, app.js copied from js (or the
    -js of hxml), assets/ copied beside it, the game's config.json (the page told of it) and favicon.png when there; with zip_file, the
    folder zipped there with index.html at the root. Refuses a build not made yet. Returns (out, zip_file or None)."""
    game = Path(game)
    if js is None:
        if not (game / hxml).is_file():
            sys.exit(f'site: no {hxml} in {game.resolve()}: name the hxml with --hxml, or the built JavaScript with --js')
        js = hxml_output(game / hxml, game)
        if js is None:
            sys.exit(f'site: {hxml} names no -js output; name the built JavaScript with --js')
    js = game / js
    if not js.is_file():
        sys.exit(f'site: {relative(js, game)} is not built yet: haxe {hxml} first')
    script = js.read_bytes()
    out = (game / out).resolve()
    if out == game.resolve() or out in game.resolve().parents:
        sys.exit(f'site: --out {out} holds the game itself; name a folder for the site')
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / 'app.js').write_bytes(script)
    config = game / 'config.json'
    meta = '<meta name="helix-config" content="config.json">' if config.is_file() else ''
    page = TEMPLATE.read_text(encoding='utf-8').replace('{{title}}', title).replace('{{meta}}', meta)
    (out / 'index.html').write_text(page, encoding='utf-8', newline='\n')
    if config.is_file():
        shutil.copyfile(config, out / 'config.json')
    if (game / 'favicon.png').is_file():
        shutil.copyfile(game / 'favicon.png', out / 'favicon.png')
    assets = game / 'assets'
    count = 0
    if assets.is_dir():
        shutil.copytree(assets, out / 'assets')
        count = sum(1 for p in (out / 'assets').rglob('*') if p.is_file())
    print(f'site: {relative(out, game)}: index.html, app.js ({len(script) // 1024} KB), assets/ ({count} files)'
          + (', config.json' if config.is_file() else '') + (', favicon.png' if (out / 'favicon.png').is_file() else ''), flush=True)
    if zip_file is not None:
        zip_file = (game / zip_file).resolve()
        zip_file.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(out.rglob('*')):
                if path.is_file() and path != zip_file:
                    archive.write(path, path.relative_to(out).as_posix())
        print(f'site: {relative(zip_file, game)} ({zip_file.stat().st_size // 1024} KB), index.html at its root', flush=True)
    return out, zip_file


def main(argv=None):
    p = argparse.ArgumentParser(prog='haxelib run helix', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='command', required=True, metavar='command')
    a_init = sub.add_parser('init', help='a starter game in a new or empty folder')
    a_init.add_argument('folder')
    a_shader = sub.add_parser('shader', help="the game's shaders packed into .hxshader assets")
    a_shader.add_argument('files', nargs='*', metavar='FILE.glsl', help='the shaders to pack; shaders/*.glsl when none is named')
    a_shader.add_argument('--out', default='assets/shaders', help='where the .hxshader files go (assets/shaders)')
    a_shader.add_argument('--sdl-gpu', action='store_true', help="with SDL_GPU's dialects, for an sdl3-gpu build (glslang and SPIRV-Cross, fetched)")
    a_shader.add_argument('--watch', action='store_true', help='pack again as a shader changes, until Ctrl+C')
    a_site = sub.add_parser('site', help='the web build assembled for hosting')
    a_site.add_argument('--out', default='out/site', help='the folder assembled (out/site)')
    a_site.add_argument('--zip', nargs='?', const='', metavar='FILE', help='also zipped, index.html at the root (out/<game>-web.zip, or FILE)')
    a_site.add_argument('--title', help="the page's title (the game folder's name)")
    a_site.add_argument('--js', help='the built JavaScript (the -js of the hxml)')
    a_site.add_argument('--hxml', default='web.hxml', help='the hxml whose -js names the build (web.hxml)')
    a = p.parse_args(argv)
    game = Path.cwd()
    if a.command == 'init':
        files = init(a.folder)
        print(f'init: {a.folder}: ' + ', '.join(files), flush=True)
    elif a.command == 'shader':
        shader(game, a.files, a.out, a.sdl_gpu, a.watch)
    else:
        name = game.resolve().name
        site(game, a.out, None if a.zip is None else (a.zip or f'out/{name}-web.zip'), a.title or name, a.js, a.hxml)


if __name__ == '__main__':
    main()
