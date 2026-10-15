"""Checks of tools/pack_shader.py against real sokol-shdc output: an app's screen effect packed with its kind, its blocks and their members'
std140 offsets, its textures, both dialects; and the shaders it refuses."""
import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import pack_shader

argparse.ArgumentParser(description=__doc__).parse_args()
import shdc
SHDC = str(shdc.path())

EFFECT = '''@fs fs
@include_block helix_screen
layout(binding=2) uniform params {
    float strength;
    vec3 shift;
    vec4 tint;
    vec4 weights[3];
    mat4 grade;
};
layout(binding=1) uniform texture2D noise_texture;
layout(binding=1) uniform sampler noise_sampler;
void main() {
    vec4 c = helix_screen_color() * texture(sampler2D(noise_texture, noise_sampler), helix_screen_uv);
    helix_output(c.rgb * strength + shift + tint.rgb * weights[2].x + (grade * c).rgb, helix_time());
}
@end
'''


class PackShaderTests(unittest.TestCase):
    def pack(self, source):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
            glsl, out = Path(scratch) / 'effect.glsl', Path(scratch) / 'effect.hxshader'
            glsl.write_text(source, encoding='utf-8')
            pack_shader.pack(SHDC, glsl, out)
            return json.loads(out.read_text(encoding='utf-8'))

    def test_screen_effect(self):
        shader = self.pack(EFFECT)
        self.assertEqual(shader['helixShader'], 1)
        self.assertEqual(shader['kind'], 'screen')
        self.assertEqual(shader['attributes'], [])
        for dialect, version in (('glsl410', '#version 410'), ('glsl300es', '#version 300 es')):
            self.assertTrue(shader[dialect]['vertex'].startswith(version) and shader[dialect]['fragment'].startswith(version))
        blocks = {b['slot']: b for b in shader['uniformBlocks']}
        self.assertEqual((blocks[0]['stage'], blocks[0]['size']), ('vertex', 16))
        self.assertEqual((blocks[1]['stage'], blocks[1]['name']), ('fragment', 'helix_screen_params'))
        members = {m['name']: (m['offset'], m['count']) for m in blocks[2]['members']}
        # std140: vec3 aligns to 16 and a vec4 follows it at 32; array elements are 16 apart; a mat4 aligns to 16.
        self.assertEqual(members, {'strength': (0, 1), 'shift': (16, 1), 'tint': (32, 1), 'weights': (48, 3), 'grade': (96, 1)})
        self.assertEqual(blocks[2]['size'], 160)
        self.assertEqual([(t['slot'], t['name']) for t in shader['textures']], [(0, 'helix_screen_texture'), (1, 'noise_texture')])

    def refused(self, source):
        with self.assertRaises(SystemExit):
            self.pack(source)

    def test_framework_binding_refused(self):
        self.refused(EFFECT.replace('binding=2) uniform params', 'binding=1) uniform params'))

    def test_one_kind_required(self):
        self.refused(EFFECT.replace('@include_block helix_screen', ''))

    def test_fragment_stage_named_fs(self):
        self.refused(EFFECT.replace('@fs fs', '@fs effect'))

    def test_array_of_floats_refused(self):
        self.refused(EFFECT.replace('vec4 weights[3];', 'float weights[3];').replace('weights[2].x', 'weights[2]'))

    def test_unsupported_member_refused(self):
        self.refused(EFFECT.replace('float strength;', 'int strength;').replace('c.rgb * strength', 'c.rgb * float(strength)'))


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]], verbosity=2)
