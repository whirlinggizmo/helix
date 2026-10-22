"""Checks of tools/gltf2scene.py: the fixture export (tests/fixtures/gltf2scene) converts to the .scene3d beside it byte for byte, and what the
tool writes parses and writes back the same bytes under the Haxe interpreter (helix.scene.SceneFile3D); the same export as a GLB; every kind's
property in an override, in the writer's order, the tool's list matching SceneSchema.hx; each value's form; a flag beside a behavior; an export without custom
properties; the refusals (a name two siblings share, a node on a path without one); and --check."""
import argparse
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import gltf2scene

argparse.ArgumentParser(description=__doc__).parse_args()
FIXTURES = ROOT / 'tests/fixtures/gltf2scene'
# The generated code SceneFile3D's dependencies compile against (generated/, committed), made current when a source is newer.
import gen_code
gen_code.generate(sdl_gpu=False)

ROUND_TRIP = '''import helix.scene.SceneFile3D;
import sys.io.File;

class RoundTrip {
	static function main():Void {
		var args = Sys.args();
		var file = SceneFile3D.parse(File.getBytes(args[0]), args[0]);
		if (file == null)
			Sys.exit(1);
		File.saveBytes(args[1], file.write());
	}
}
'''
# A valid value for each property of an override, in the type its table gives it.
TYPED = {'tint': '#FF0000FF', 'color': '#102030', 'shadowColor': '#00000080', 'shadowCasting': False, 'shadowReceiving': True,
    'projection': 'orthographic', 'texture': 'fx/glow.png', 'facing': 'upright', 'alphaMode': 'add', 'text': 'Start', 'font': 'fonts/ui.fnt',
    'fovY': 0.9, 'alphaCutoff': 0.25, 'shadowMapSize': 1024, 'innerCone': 0.2, 'outerCone': 0.5}


def gltf(nodes, roots=None):
    """A glTF JSON text of nodes alone, the scene's roots given or every node without a parent."""
    children = {c for n in nodes for c in n.get('children', [])}
    roots = [i for i in range(len(nodes)) if i not in children] if roots is None else roots
    return json.dumps({'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': roots}], 'nodes': nodes})


def glb(text):
    """A GLB holding text as its JSON chunk and nothing else."""
    chunk = text.encode('utf-8')
    chunk += b' ' * (-len(chunk) % 4)
    return struct.pack('<4sII', b'glTF', 2, 20 + len(chunk)) + struct.pack('<II', len(chunk), 0x4e4f534a) + chunk


class Gltf2SceneTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(dir=ROOT / 'build')
        self.dir = Path(self.scratch.name)

    def tearDown(self):
        self.scratch.cleanup()

    def convert(self, text, suffix='.gltf', **kw):
        """The tool's bytes for an export written as text (a .gltf, or a .glb holding it) named export."""
        path = self.dir / f'export{suffix}'
        if suffix == '.glb':
            path.write_bytes(glb(text))
        else:
            path.write_text(text, encoding='utf-8')
        return gltf2scene.convert(path, **kw)

    def round_trip(self, data):
        """data parsed and written back by SceneFile3D under the interpreter."""
        (self.dir / 'RoundTrip.hx').write_text(ROUND_TRIP, encoding='utf-8')
        given, written = self.dir / 'given.scene3d', self.dir / 'written.scene3d'
        given.write_bytes(data)
        subprocess.run(['haxe', '-cp', 'src', '-cp', 'generated/shaders', '-cp', 'generated/fonts', '-cp', str(self.dir),
            '--run', 'RoundTrip', str(given), str(written)], cwd=ROOT, check=True)
        return written.read_bytes()

    def test_fixture(self):
        data = gltf2scene.convert(FIXTURES / 'track.gltf')
        self.assertEqual(data, (FIXTURES / 'track.scene3d').read_bytes())
        self.assertEqual(self.round_trip(data), data)

    def test_glb(self):
        text = (FIXTURES / 'track.gltf').read_text(encoding='utf-8')
        self.assertEqual(self.convert(text, '.glb', file='models/track.gltf', name='track'), (FIXTURES / 'track.scene3d').read_bytes())
        with self.assertRaises(SystemExit):
            self.convert(text[:40], '.glb')

    def test_every_property(self):
        names = re.findall(r'new PropertySchema\("(\w+)"', (ROOT / 'src/helix/scene/SceneSchema.hx').read_text(encoding='utf-8'))
        self.assertEqual(set(names), set(gltf2scene.PROPERTIES))
        self.assertEqual(len(set(gltf2scene.PROPERTIES)), len(gltf2scene.PROPERTIES))
        extras = {f'helix_{name}': TYPED.get(name, 0.5) for name in reversed(gltf2scene.PROPERTIES)}
        extras.update({'helix_enabled': 0, 'helix_visible': True, 'helix_pickable': 1})
        data = self.convert(gltf([{'name': 'all', 'extras': extras}]))
        self.assertEqual(self.round_trip(data), data)
        lines = data.decode('utf-8').splitlines()
        keys = [line.split('"')[1] for line in lines if line.startswith('          "')]
        self.assertEqual(keys, ['enabled', 'visible', 'pickable'] + gltf2scene.PROPERTIES)
        self.assertIn('          "tint": "#ff0000",', lines)
        self.assertIn('          "enabled": false,', lines)

    def test_values(self):
        extras = {'helix_behavior': 'Car', 'helix_enabled': 0, 'helix_speed': 2.5, 'helix_third': 1 / 3, 'helix_sum': 0.1 + 0.2, 'helix_count': 7,
            'helix_minus': -0.000_000_4, 'helix_on': True, 'helix_label': 'Start "here"\n', 'helix_target': '@car',
            'helix_tint': '#FF880080', 'helix_offset': [0, 1.5, -6], 'helix_none': [], 'helix_props_team': 2, 'helix_props_name': 'x'}
        data = self.convert(gltf([{'name': 'body', 'extras': extras}]))
        self.assertEqual(self.round_trip(data), data)
        expected = ['        "body": {', '          "enabled": false,', '          "behaviors": [', '            {', '              "kind": "Car",', '              "props": {',
            '                "count": 7,', '                "label": "Start \\"here\\"\\n",', '                "minus": 0,',
            '                "none": [],', '                "offset": [0, 1.5, -6],', '                "on": true,',
            '                "speed": 2.5,', '                "sum": 0.3,', '                "target": "@car",',
            '                "third": 0.333333,', '                "tint": "#ff880080"', '              }', '            }', '          ],',
            '          "props": {', '            "name": "x",', '            "team": 2', '          }', '        }']
        self.assertEqual(data.decode('utf-8').splitlines()[8:8 + len(expected)], expected)

    def test_no_properties(self):
        data = self.convert(gltf([{'name': 'a', 'children': [1]}, {'name': 'b'}]), name='empty', file='props/empty.glb')
        self.assertEqual(data.decode('utf-8'), '{\n  "helix-scene3d": 1,\n  "nodes": [\n    {\n      "kind": "Model",\n      "name": "empty",\n'
            '      "file": "props/empty.glb"\n    }\n  ]\n}\n')
        self.assertEqual(self.round_trip(data), data)

    def refused(self, text, said):
        with self.assertRaises(SystemExit) as caught:
            self.convert(text)
        self.assertIn(said, str(caught.exception))

    def test_refusals(self):
        self.refused(gltf([{'name': 'gates', 'children': [1, 2]}, {'name': 'gate'}, {'name': 'gate', 'extras': {'helix_index': 1}}]),
            "'gate' is used twice among the children of gates")
        self.refused(gltf([{'name': 'a'}, {'name': 'a'}]), "'a' is used twice among the children of the roots")
        self.refused(gltf([{'children': [1]}, {'name': 'b', 'extras': {'helix_index': 1}}]), 'needs a name')
        self.refused(gltf([{'name': 'a/b', 'extras': {'helix_index': 1}}]), 'needs a name without "/"')
        self.refused(gltf([{'name': 'a', 'extras': {'helix_behavior': ''}}]), 'helix_behavior names a behavior')
        self.refused(gltf([{'name': 'a', 'extras': {'helix_visible': 'yes'}}]), 'helix_visible is true or false')
        self.refused(gltf([{'name': 'a', 'extras': {'helix_group': {'x': 1}}}]), 'helix_group')
        self.refused(gltf([{'name': 'a', 'extras': {'helix_list': [1, 'two']}}]), 'helix_list')
        # Two unnamed leaves without properties aren't siblings sharing a name: nothing addresses them.
        self.convert(gltf([{'name': 'a', 'children': [1, 2]}, {}, {}]))

    def test_check(self):
        tool, export = ROOT / 'tools/gltf2scene.py', FIXTURES / 'track.gltf'
        self.assertEqual(subprocess.run([sys.executable, tool, export, FIXTURES / 'track.scene3d', '--check'], cwd=ROOT).returncode, 0)
        stale = self.dir / 'stale.scene3d'
        self.assertEqual(subprocess.run([sys.executable, tool, export, stale, '--check'], cwd=ROOT, capture_output=True).returncode, 1)
        subprocess.run([sys.executable, tool, export, stale], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
        self.assertEqual(stale.read_bytes(), (FIXTURES / 'track.scene3d').read_bytes())
        stale.write_bytes(stale.read_bytes().replace(b'"index": 3', b'"index": 4'))
        self.assertEqual(subprocess.run([sys.executable, tool, export, stale, '--check'], cwd=ROOT, capture_output=True).returncode, 1)


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]], verbosity=2)
