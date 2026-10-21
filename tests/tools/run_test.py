"""Checks of the library's front door for a game, `haxelib run helix <command>` (Run.hx, tools/game/, run by Haxe's interpreter): its
argument handling (no command, --help naming the commands, an unknown command or option, a missing value); Run.hx taking the caller's folder
haxelib appends (HAXELIB_RUN=1); init's files, that its starter builds for the browser on `-lib helix` (a haxelib path holding only this
checkout as helix), and its refusal of a folder with anything in it; site's assembly (index.html from the template at the root with the
title and the config's meta, app.js from the hxml's -js, also through an included hxml, assets copied beside, config.json and favicon.png,
the zip's layout and name, --title, --js and --out, the refusals); and shader packing a small screen effect (sokol-shdc, fetched when
missing) into assets/shaders, its refusals, and the manifests rewritten from their root when the assets carry them, as tools/gen_manifest.py
would write them; setup making sokol-shdc ready and listing the tools, a program HELIX_SHDC names in place of the cache's and its refusal of
one that isn't there.

    python3 tests/tools/run_test.py"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import gen_manifest

argparse.ArgumentParser(description=__doc__).parse_args()

EFFECT = '''@fs fs
@include_block helix_screen
layout(binding=2) uniform params {
    float strength;
};
void main() {
    helix_output(helix_screen_color().rgb * strength, 1.0);
}
@end
'''


def run_hx(*args, cwd=None, env=None):
    """Run.hx run as `haxe --run Run` from the checkout, as haxelib runs it (with HAXELIB_RUN=1, the caller's folder last)."""
    return subprocess.run(['haxe', '--run', 'Run', *args], cwd=cwd or ROOT, env=env, capture_output=True, text=True, encoding='utf-8')


def tool(*args, cwd):
    """The front door run in the game's folder cwd, as `haxelib run helix` runs it there."""
    return run_hx(*args, str(cwd), env=dict(os.environ, HAXELIB_RUN='1'))


def done(result):
    """result's output, once it succeeded."""
    assert result.returncode == 0, result.stdout + result.stderr
    return result.stdout


def refusal(result):
    """result's error, once it was refused (exit 1)."""
    assert result.returncode == 1, (result.returncode, result.stdout, result.stderr)
    return result.stderr


def site(root, *args):
    """site run in the game root with args; its folder (out/site or --out's) absolute."""
    done(tool('site', *args, cwd=root))
    out = args[args.index('--out') + 1] if '--out' in args else 'out/site'
    return (Path(root) / out).resolve()


class FrontDoor(unittest.TestCase):
    def test_arguments(self):
        result = run_hx()
        self.assertEqual(result.returncode, 2)
        self.assertIn('command', result.stderr)
        result = run_hx('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        for command in ('init', 'shader', 'site', 'setup'):
            self.assertIn(command, result.stdout)
        self.assertIn('haxelib run helix', result.stdout)
        result = run_hx('bogus')
        self.assertEqual(result.returncode, 2)
        self.assertIn('bogus', result.stderr)
        result = run_hx('site', '--bogus')
        self.assertEqual(result.returncode, 2)
        self.assertIn('--bogus', result.stderr)
        result = run_hx('site', '--out')
        self.assertEqual(result.returncode, 2)
        self.assertIn('needs a value', result.stderr)
        for command in ('init', 'shader', 'site', 'setup'):
            result = run_hx(command, '--help')
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_run_hx(self):
        with tempfile.TemporaryDirectory() as folder:
            # haxelib appends the caller's folder: the command works there, not in the library's.
            result = run_hx('site', folder, env=dict(os.environ, HAXELIB_RUN='1'))
            self.assertEqual(result.returncode, 1)
            self.assertIn(Path(folder).resolve().as_posix(), result.stderr)
            self.assertIn('no web.hxml', result.stderr)


class Init(unittest.TestCase):
    def test_files_and_build(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'my-jam-game'
            written = done(tool('init', 'my-jam-game', cwd=folder))
            for relative in ('src/Main.hx', 'src/Game.hx', 'web.hxml', 'native.hxml', 'assets/README.md', '.gitignore', 'README.md'):
                self.assertIn(relative, written)
                self.assertTrue((target / relative).is_file(), relative)
            self.assertIn('options.product = "my-jam-game"', (target / 'src/Main.hx').read_text(encoding='utf-8'))
            self.assertIn('Window.title = "My Jam Game"', (target / 'src/Game.hx').read_text(encoding='utf-8'))
            self.assertIn('-D helix-backend=sokol-gl', (target / 'native.hxml').read_text(encoding='utf-8'))
            self.assertIn('-D helix-backend=webgl2', (target / 'web.hxml').read_text(encoding='utf-8'))
            self.assertEqual((target / '.gitignore').read_text(encoding='utf-8'), 'out/\n')
            readme = (target / 'README.md').read_text(encoding='utf-8')
            for command in ('haxe web.hxml', 'haxelib run helix site --zip', 'haxe native.hxml', 'hotreload.DevServer', 'haxelib run helix shader --watch'):
                self.assertIn(command, readme)
            # The starter builds for the browser on -lib helix alone: a haxelib path with this checkout as helix (a dev library).
            haxelib = Path(folder) / 'haxelib' / 'helix'
            haxelib.mkdir(parents=True)
            (haxelib / '.dev').write_text(str(ROOT), encoding='utf-8')
            result = subprocess.run(['haxe', 'web.hxml'], cwd=target, env=dict(os.environ, HAXELIB_PATH=str(haxelib.parent)), capture_output=True, text=True, encoding='utf-8')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((target / 'out/web/app.js').is_file())
            # A site from it, as the README says.
            out = site(target, '--zip')
            self.assertEqual((out / 'app.js').read_bytes(), (target / 'out/web/app.js').read_bytes())
            self.assertIn('assets/README.md', zipfile.ZipFile(target / 'out/my-jam-game-web.zip').namelist())

    def test_refuses_a_folder_in_use(self):
        with tempfile.TemporaryDirectory() as folder:
            (Path(folder) / 'something.txt').write_text('x', encoding='utf-8')
            self.assertIn('not empty', refusal(tool('init', '.', cwd=folder)))
            (Path(folder) / 'file.txt').write_text('x', encoding='utf-8')
            self.assertIn('not empty', refusal(tool('init', 'file.txt', cwd=folder)))


class Site(unittest.TestCase):
    def game(self, folder, hxml='-lib helix\n-cp src\n-js out/web/app.js\n'):
        """A game folder with a built web.hxml, assets (one in a subfolder), a config.json and a favicon."""
        root = Path(folder) / 'pocket-game'
        (root / 'out/web').mkdir(parents=True)
        (root / 'web.hxml').write_text(hxml, encoding='utf-8')
        (root / 'out/web/app.js').write_text('console.log("the game");\n', encoding='utf-8')
        (root / 'out/web/app.js.map').write_text('{}', encoding='utf-8')
        (root / 'assets/sub').mkdir(parents=True)
        (root / 'assets/a.txt').write_text('a', encoding='utf-8')
        (root / 'assets/sub/b.txt').write_text('b', encoding='utf-8')
        (root / 'config.json').write_text('{"quality": "high"}', encoding='utf-8')
        (root / 'favicon.png').write_bytes(b'\x89PNG')
        return root

    def test_assembly_and_zip(self):
        with tempfile.TemporaryDirectory() as folder:
            root = self.game(folder)
            out = site(root, '--zip')
            archive = root / 'out/pocket-game-web.zip'
            self.assertTrue((out / 'index.html').is_file())
            page = (out / 'index.html').read_text(encoding='utf-8')
            self.assertIn('<title>pocket-game</title>', page)
            self.assertIn('<meta name="helix-config" content="config.json">', page)
            self.assertNotIn('{{', page)
            self.assertEqual((out / 'app.js').read_text(encoding='utf-8'), 'console.log("the game");\n')
            self.assertFalse((out / 'app.js.map').exists())
            self.assertEqual((out / 'assets/a.txt').read_text(encoding='utf-8'), 'a')
            self.assertEqual((out / 'assets/sub/b.txt').read_text(encoding='utf-8'), 'b')
            self.assertEqual((out / 'config.json').read_text(encoding='utf-8'), '{"quality": "high"}')
            self.assertEqual((out / 'favicon.png').read_bytes(), b'\x89PNG')
            names = zipfile.ZipFile(archive).namelist()
            self.assertEqual(sorted(names), ['app.js', 'assets/a.txt', 'assets/sub/b.txt', 'config.json', 'favicon.png', 'index.html'])
            # Again: the folder is remade, not accumulated.
            (out / 'stale.txt').write_text('x', encoding='utf-8')
            site(root)
            self.assertFalse((out / 'stale.txt').exists())

    def test_options(self):
        with tempfile.TemporaryDirectory() as folder:
            root = self.game(folder, hxml='-lib helix\n--js  out/web/app.js   # the build\n')
            out = site(root, '--title', 'A Title')
            self.assertFalse((root / 'out/pocket-game-web.zip').exists())
            self.assertIn('<title>A Title</title>', (out / 'index.html').read_text(encoding='utf-8'))
            # A game without config.json or favicon.png: no meta, nothing copied.
            (root / 'config.json').unlink()
            (root / 'favicon.png').unlink()
            (root / 'out/web/other.js').write_text('other', encoding='utf-8')
            out = site(root, '--out', 'build/www', '--js', 'out/web/other.js')
            page = (out / 'index.html').read_text(encoding='utf-8')
            self.assertNotIn('helix-config', page)
            self.assertFalse((out / 'config.json').exists())
            self.assertEqual((out / 'app.js').read_text(encoding='utf-8'), 'other')
            # --zip FILE, and the folder's name as the zip's default (above).
            self.assertIn('index.html at its root', done(tool('site', '--zip', 'dist/game.zip', cwd=root)))
            self.assertIn('index.html', zipfile.ZipFile(root / 'dist/game.zip').namelist())
            # Through an hxml it includes, the last -js winning.
            (root / 'common.hxml').write_text('-lib helix\n-js out/web/app.js\n', encoding='utf-8')
            (root / 'web.hxml').write_text('common.hxml\n', encoding='utf-8')
            self.assertEqual((site(root) / 'app.js').read_text(encoding='utf-8'), 'console.log("the game");\n')

    def test_refusals(self):
        with tempfile.TemporaryDirectory() as folder:
            root = self.game(folder)
            (root / 'out/web/app.js').unlink()
            self.assertIn('not built yet', refusal(tool('site', cwd=root)))
            self.assertIn('no other.hxml', refusal(tool('site', '--hxml', 'other.hxml', cwd=root)))
            (root / 'web.hxml').write_text('-lib helix\n-main Main\n', encoding='utf-8')
            self.assertIn('names no -js', refusal(tool('site', cwd=root)))
            (root / 'out/web/app.js').write_text('x', encoding='utf-8')
            self.assertIn('holds the game itself', refusal(tool('site', '--out', '.', '--js', 'out/web/app.js', cwd=root)))
            self.assertIn('holds the game itself', refusal(tool('site', '--out', '..', '--js', 'out/web/app.js', cwd=root)))
            self.assertTrue((root / 'assets/a.txt').is_file())


class Shader(unittest.TestCase):
    def test_pack(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder) / 'shady'
            (root / 'shaders').mkdir(parents=True)
            (root / 'shaders/glow.glsl').write_text(EFFECT, encoding='utf-8')
            self.assertIn('missing.glsl', refusal(tool('shader', 'shaders/missing.glsl', cwd=root)))
            self.assertIn('glow.glsl -> assets/shaders/glow.hxshader', done(tool('shader', cwd=root)))
            packed = json.loads((root / 'assets/shaders/glow.hxshader').read_text(encoding='utf-8'))
            self.assertEqual(packed['kind'], 'screen')
            for dialect in ('glsl410', 'glsl300es'):
                self.assertIn(dialect, packed)
            self.assertNotIn('sdlGpu', packed)
            self.assertFalse((root / 'assets/manifest.json').exists())
            # --out elsewhere, the file named.
            done(tool('shader', 'shaders/glow.glsl', '--out', 'build/packed', cwd=root))
            self.assertTrue((root / 'build/packed/glow.hxshader').is_file())
            # A shader the packer refuses: the packer's message, exit 1.
            (root / 'shaders/bad.glsl').write_text(EFFECT.replace('@include_block helix_screen', ''), encoding='utf-8')
            self.assertIn('exactly one framework block', refusal(tool('shader', 'shaders/bad.glsl', cwd=root)))
            (root / 'shaders/bad.glsl').unlink()
            # Assets carrying manifests: rewritten from their root, as tools/gen_manifest.py writes them (a sibling folder's kept).
            (root / 'assets/sprites').mkdir()
            (root / 'assets/sprites/hero.png').write_bytes(b'\x89PNG')
            (root / 'assets/title.txt').write_text('Shady', encoding='utf-8')
            gen_manifest.write(root / 'assets')
            (root / 'shaders/glow.glsl').write_text(EFFECT.replace('* strength', '* strength * 2.0'), encoding='utf-8')
            self.assertIn('manifests rewritten under assets', done(tool('shader', cwd=root)))
            shaders = (root / 'assets/shaders/manifest.json').read_bytes()
            self.assertIn('glow.hxshader', json.loads(shaders)['files'])
            top = (root / 'assets/manifest.json').read_bytes()
            self.assertEqual(json.loads(top)['dirs']['shaders'], gen_manifest.digest(shaders))
            gen_manifest.write(root / 'assets')
            self.assertEqual((root / 'assets/manifest.json').read_bytes(), top, "the Python writer's bytes")
            self.assertEqual((root / 'assets/shaders/manifest.json').read_bytes(), shaders)
            (root / 'shaders/glow.glsl').unlink()
            self.assertIn('nothing to pack', refusal(tool('shader', cwd=root)))


class Setup(unittest.TestCase):
    def test_setup(self):
        with tempfile.TemporaryDirectory() as folder:
            listed = done(tool('setup', cwd=folder))
            shdc = next(line for line in listed.splitlines() if line.startswith('sokol-shdc'))
            self.assertTrue(Path(shdc.split()[2]).is_file(), listed)
            self.assertIn('cache:', listed)
            self.assertIn('unexpected', run_hx('setup', 'extra', folder, env=dict(os.environ, HAXELIB_RUN='1')).stderr)
            # A program of the user's own, in a cache with nothing in it: listed in place of the pin, nothing fetched.
            cache = Path(folder) / 'cache'
            empty = dict(os.environ, HAXELIB_RUN='1', XDG_CACHE_HOME=str(cache), LOCALAPPDATA=str(cache), HOME=str(cache),
                         USERPROFILE=str(cache))
            mine = Path(folder) / 'my-shdc'
            mine.write_bytes(b'shdc')
            listed = done(run_hx('setup', folder, env=dict(empty, HELIX_SHDC=str(mine))))
            self.assertIn('HELIX_SHDC', listed)
            self.assertIn(mine.resolve().as_posix(), listed)
            self.assertIn('not there yet', listed)
            self.assertFalse((cache / 'helix').exists())
            self.assertIn('HELIX_SHDC names', refusal(run_hx('setup', folder, env=dict(empty, HELIX_SHDC=str(mine) + '-not'))))


if __name__ == '__main__':
    unittest.main()
