"""Checks of the library's front door for a game, tools/game.py (`haxelib run helix <command>`, Run.hx): its argument handling (no command,
--help naming the commands, an unknown one); Run.hx taking the caller's folder haxelib appends (HAXELIB_RUN=1) and refusing a Python that
isn't there; init's files, that its starter builds for the browser on `-lib helix` (a haxelib path holding only this checkout as helix),
and its refusal of a folder with anything in it; site's assembly (index.html from the template at the root with the title and the
config's meta, app.js from the hxml's -js, assets copied beside, config.json and favicon.png, the zip's layout, --title and --js, the
refusals); and shader packing a small screen effect (sokol-shdc, fetched when missing) into assets/shaders, rewriting the manifests from
their root when the assets carry them.

    python3 tests/tools/game_test.py"""
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
import game
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


def tool(*args, cwd=None, env=None):
    """tools/game.py run as a command in cwd."""
    return subprocess.run([sys.executable, str(ROOT / 'tools/game.py'), *args], cwd=cwd, env=env, capture_output=True, text=True, encoding='utf-8')


def run_hx(*args, cwd=None, env=None):
    """Run.hx run as `haxe --run Run` from the checkout, as haxelib runs it (with HAXELIB_RUN=1, the caller's folder last)."""
    return subprocess.run(['haxe', '--run', 'Run', *args], cwd=cwd or ROOT, env=env, capture_output=True, text=True, encoding='utf-8')


class FrontDoor(unittest.TestCase):
    def test_arguments(self):
        result = tool()
        self.assertEqual(result.returncode, 2)
        self.assertIn('command', result.stderr)
        result = tool('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        for command in ('init', 'shader', 'site'):
            self.assertIn(command, result.stdout)
        self.assertIn('haxelib run helix', result.stdout)
        result = tool('bogus')
        self.assertEqual(result.returncode, 2)
        self.assertIn('bogus', result.stderr)
        for command in ('init', 'shader', 'site'):
            result = tool(command, '--help')
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_run_hx(self):
        result = run_hx('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('init', result.stdout)
        with tempfile.TemporaryDirectory() as folder:
            # haxelib appends the caller's folder: the command works there, not in the library's.
            result = run_hx('site', folder, env=dict(os.environ, HAXELIB_RUN='1'))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(str(Path(folder).resolve()), result.stderr)
            self.assertIn('no web.hxml', result.stderr)
        result = run_hx('--help', env=dict(os.environ, HELIX_PYTHON=str(Path(tempfile.gettempdir()) / 'no-such-python')))
        self.assertEqual(result.returncode, 1)
        self.assertIn('HELIX_PYTHON', result.stderr)
        self.assertIn('no-such-python', result.stderr)


class Init(unittest.TestCase):
    def test_files_and_build(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'my-jam-game'
            written = game.init(target)
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
            out, archive = game.site(target, 'out/site', 'out/my-jam-game-web.zip', 'my-jam-game', None, 'web.hxml')
            self.assertEqual((out / 'app.js').read_bytes(), (target / 'out/web/app.js').read_bytes())
            self.assertIn('assets/README.md', zipfile.ZipFile(archive).namelist())

    def test_refuses_a_folder_in_use(self):
        with tempfile.TemporaryDirectory() as folder:
            (Path(folder) / 'something.txt').write_text('x', encoding='utf-8')
            with self.assertRaises(SystemExit) as refused:
                game.init(folder)
            self.assertIn('not empty', str(refused.exception))
            result = tool('init', folder)
            self.assertEqual(result.returncode, 1)
            self.assertIn('not empty', result.stderr)


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
            out, archive = game.site(root, 'out/site', 'out/pocket-game-web.zip', 'pocket-game', None, 'web.hxml')
            self.assertEqual(out, (root / 'out/site').resolve())
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
            game.site(root, 'out/site', None, 'pocket-game', None, 'web.hxml')
            self.assertFalse((out / 'stale.txt').exists())

    def test_options(self):
        with tempfile.TemporaryDirectory() as folder:
            root = self.game(folder, hxml='-lib helix\n--js  out/web/app.js   # the build\n')
            out, archive = game.site(root, 'out/site', None, 'A Title', None, 'web.hxml')
            self.assertIsNone(archive)
            self.assertIn('<title>A Title</title>', (out / 'index.html').read_text(encoding='utf-8'))
            # A game without config.json or favicon.png: no meta, nothing copied.
            (root / 'config.json').unlink()
            (root / 'favicon.png').unlink()
            (root / 'out/web/other.js').write_text('other', encoding='utf-8')
            out, _ = game.site(root, 'build/www', None, 'pocket-game', 'out/web/other.js', 'web.hxml')
            page = (out / 'index.html').read_text(encoding='utf-8')
            self.assertNotIn('helix-config', page)
            self.assertFalse((out / 'config.json').exists())
            self.assertEqual((out / 'app.js').read_text(encoding='utf-8'), 'other')
            # The command, from the game's folder: the zip's default name is the folder's.
            result = tool('site', '--zip', cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((root / 'out/pocket-game-web.zip').is_file())
            self.assertIn('index.html at its root', result.stdout)

    def test_refusals(self):
        with tempfile.TemporaryDirectory() as folder:
            root = self.game(folder)
            (root / 'out/web/app.js').unlink()
            with self.assertRaises(SystemExit) as refused:
                game.site(root, 'out/site', None, 'x', None, 'web.hxml')
            self.assertIn('not built yet', str(refused.exception))
            with self.assertRaises(SystemExit) as refused:
                game.site(root, 'out/site', None, 'x', None, 'other.hxml')
            self.assertIn('no other.hxml', str(refused.exception))
            (root / 'web.hxml').write_text('-lib helix\n-main Main\n', encoding='utf-8')
            with self.assertRaises(SystemExit) as refused:
                game.site(root, 'out/site', None, 'x', None, 'web.hxml')
            self.assertIn('names no -js', str(refused.exception))
            (root / 'out/web/app.js').write_text('x', encoding='utf-8')
            with self.assertRaises(SystemExit) as refused:
                game.site(root, '.', None, 'x', 'out/web/app.js', 'web.hxml')
            self.assertIn('holds the game itself', str(refused.exception))
            self.assertTrue((root / 'assets/a.txt').is_file())


class Shader(unittest.TestCase):
    def test_pack(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder) / 'shady'
            (root / 'shaders').mkdir(parents=True)
            (root / 'shaders/glow.glsl').write_text(EFFECT, encoding='utf-8')
            with self.assertRaises(SystemExit) as refused:
                game.shader(root, ['shaders/missing.glsl'], 'assets/shaders', False, False)
            self.assertIn('missing.glsl', str(refused.exception))
            written = game.shader(root, [], 'assets/shaders', False, False)
            self.assertEqual(written, [root / 'assets/shaders/glow.hxshader'])
            packed = json.loads(written[0].read_text(encoding='utf-8'))
            self.assertEqual(packed['kind'], 'screen')
            for dialect in ('glsl410', 'glsl300es'):
                self.assertIn(dialect, packed)
            self.assertNotIn('sdlGpu', packed)
            self.assertFalse((root / 'assets/manifest.json').exists())
            # Assets carrying manifests: rewritten from their root, so the root names the shaders folder's new one.
            (root / 'assets/sprites').mkdir()
            (root / 'assets/sprites/hero.png').write_bytes(b'\x89PNG')
            gen_manifest.write(root / 'assets')
            (root / 'shaders/glow.glsl').write_text(EFFECT.replace('* strength', '* strength * 2.0'), encoding='utf-8')
            game.shader(root, ['shaders/glow.glsl'], 'assets/shaders', False, False)
            shaders = (root / 'assets/shaders/manifest.json').read_bytes()
            self.assertIn('glow.hxshader', json.loads(shaders)['files'])
            self.assertEqual(json.loads((root / 'assets/manifest.json').read_text(encoding='utf-8'))['dirs']['shaders'], gen_manifest.digest(shaders))
            (root / 'shaders/glow.glsl').unlink()
            with self.assertRaises(SystemExit) as refused:
                game.shader(root, [], 'assets/shaders', False, False)
            self.assertIn('nothing to pack', str(refused.exception))


if __name__ == '__main__':
    unittest.main()
