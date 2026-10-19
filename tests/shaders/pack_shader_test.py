"""Checks of tools/pack_shader.py against real sokol-shdc output: an app's screen effect packed with its kind, its blocks and their members'
std140 offsets, its textures, both dialects; the shaders it refuses; a surface shader's variants (skinned, and the casters of one with a
vertex hook or a discard) and its own textures after the joints; the shader library (src/helix/shaders) packed for every backend, SDL_GPU's
dialects too (glslang and SPIRV-Cross, fetched by tools/gpu_shaders.py when missing); and the library packed into generated Haxe, again only
when changed, and gone with its source."""
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


def pack(source):
    """source packed as an .hxshader file would be, read back."""
    with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
        glsl, out = Path(scratch) / 'shader.glsl', Path(scratch) / 'shader.hxshader'
        glsl.write_text(source, encoding='utf-8')
        pack_shader.pack(SHDC, glsl, out)
        return json.loads(out.read_text(encoding='utf-8'))


class PackShaderTests(unittest.TestCase):
    def pack(self, source):
        return pack(source)

    def test_screen_effect(self):
        shader = self.pack(EFFECT)
        self.assertEqual(shader['helixShader'], 2)
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


SURFACE = '''@fs fs
@include_block helix_surface
layout(binding=2) uniform params {
    vec4 tint;
};
void main() {
    vec4 base = helix_base() * tint;
    helix_output(helix_shade(helix_normal(), base), base.a);
}
@end
'''
HOOK = '''@block vertex
layout(binding=3) uniform swell {
    float height;
};
void helix_vertex(inout vec3 position, inout vec3 normal) {
    position += normal * height;
}
@end
'''


class SurfaceTests(unittest.TestCase):
    def pack(self, source):
        return pack(source)

    def test_skinned_variant(self):
        shader = self.pack(SURFACE)
        self.assertEqual(shader['kind'], 'surface')
        skinned = shader['skinned']
        self.assertEqual(skinned['attributes'][-2:], ['joints', 'weights'])
        self.assertEqual(skinned['attributes'][:-2], shader['attributes'])
        joints = [t for t in skinned['textures'] if t['slot'] == 5]
        self.assertEqual([(t['name'], t['stage'], t['data']) for t in joints], [('helix_joint_texture', 'vertex', True)])
        self.assertNotIn(5, [t['slot'] for t in shader['textures']])
        # The same parameters, at the same offsets, in both.
        own = lambda s: [b['members'] for b in s['uniformBlocks'] if b['slot'] == 2]
        self.assertEqual(own(shader), own(skinned))
        self.assertIn('helix_joint_texture', skinned['glsl300es']['vertex'])

    def test_no_caster_without_hook_or_discard(self):
        shader = self.pack(SURFACE.replace('void main() {', '// a discard in a comment is no discard\nvoid main() {'))
        self.assertNotIn('caster', shader)
        self.assertNotIn('skinnedCaster', shader)

    def test_caster_for_discard(self):
        shader = self.pack(SURFACE.replace('helix_output(', 'if (base.a < 0.5) discard;\n    helix_output('))
        for name in ('caster', 'skinnedCaster'):
            caster = shader[name]
            fragment = caster['glsl300es']['fragment']
            # The fragment stage runs for its discard alone: no color written.
            self.assertIn('discard', fragment)
            self.assertNotIn('out highp vec4', fragment)
            self.assertNotIn('out mediump vec4', fragment)
        self.assertIn('helix_joint_texture', shader['skinnedCaster']['glsl300es']['vertex'])

    def test_caster_for_vertex_hook(self):
        shader = self.pack(HOOK + SURFACE)
        self.assertIn('caster', shader)
        blocks = {b['slot']: b for b in shader['caster']['uniformBlocks']}
        self.assertEqual([m['name'] for m in blocks[3]['members']], ['height'])
        self.assertEqual(blocks[3]['stage'], 'vertex')

    def test_own_texture_after_the_joints(self):
        texture = '''layout(binding=5) uniform texture2D grain;
layout(binding=5) uniform sampler grain_sampler;
'''
        sampled = SURFACE.replace('void main() {', texture + 'void main() {').replace('* tint;', '* tint * texture(sampler2D(grain, grain_sampler), helix_uv());')
        with self.assertRaises(SystemExit):
            self.pack(sampled)
        shader = self.pack(sampled.replace('binding=5', 'binding=6'))
        self.assertIn((6, 'grain'), [(t['slot'], t['name']) for t in shader['skinned']['textures']])


class LibraryTests(unittest.TestCase):
    def test_every_library_shader_packs_for_every_backend(self):
        sources = sorted(pack_shader.LIBRARY.glob('*.glsl'))
        self.assertTrue(sources)
        for source in sources:
            with self.subTest(shader=source.name):
                shader = pack_shader.packed(SHDC, source, sdl_gpu=True)
                self.assertIn(shader['kind'], ('screen', 'surface'))
                for dialect, version in (('glsl410', '#version 410'), ('glsl300es', '#version 300 es')):
                    self.assertTrue(shader[dialect]['vertex'].startswith(version) and shader[dialect]['fragment'].startswith(version))
                for dialect in ('spirv', 'msl', 'hlsl'):
                    self.assertTrue(shader['sdlGpu'][dialect]['vertex'] and shader['sdlGpu'][dialect]['fragment'])

    def test_unlit_parameters(self):
        shader = pack_shader.packed(SHDC, pack_shader.LIBRARY / 'unlit.glsl')
        blocks = {b['slot']: b for b in shader['uniformBlocks']}
        # helix.shaders.Unlit's color field writes this member: the block at binding 2, a vec4 at its start.
        self.assertEqual([(m['name'], m['type'], m['offset'], m['count']) for m in blocks[2]['members']], [('color', 'vec4', 0, 1)])

    def test_library_parameters(self):
        # helix.shaders' classes write these members: Toon's, Dissolve's and Water's blocks as the reflection lays them out.
        expected = {'toon': {2: [('shadow_color', 0), ('bands', 16)]},
                    'dissolve': {2: [('edge_color', 0), ('amount', 16), ('edge_width', 20), ('scale', 24)]},
                    'water': {2: [('deep_color', 0), ('shallow_color', 16), ('sky_color', 32), ('shininess', 48)],
                              3: [('amplitude', 0), ('wavelength', 4), ('wave_speed', 8)]}}
        for stem, blocks in expected.items():
            with self.subTest(shader=stem):
                shader = pack_shader.packed(SHDC, pack_shader.LIBRARY / f'{stem}.glsl')
                found = {b['slot']: [(m['name'], m['offset']) for m in b['members']] for b in shader['uniformBlocks'] if 'members' in b}
                self.assertEqual(found, blocks)
                self.assertEqual('caster' in shader, stem != 'toon')

    def test_pack_library(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
            scratch = Path(scratch)
            sources, out, gpu = scratch / 'sources', scratch / 'out', scratch / 'gpu'
            sources.mkdir()
            (sources / 'film_grain.glsl').write_text(EFFECT, encoding='utf-8')
            self.assertEqual(pack_shader.pack_library(out, gpu, sources, SHDC), ['film_grain'])
            base, dialects = (out / 'FilmGrainPacked.hx').read_text(encoding='utf-8'), (gpu / 'FilmGrainPackedSdlGpu.hx').read_text(encoding='utf-8')
            self.assertIn('#if helix_sdl3_gpu\n  return FilmGrainPackedSdlGpu.text();', base)
            # The literal is the .hxshader's JSON as a string: Haxe's escapes are JSON's.
            text = json.loads(json.loads(base.split('  return ', 2)[2].split(';\n', 1)[0]))
            self.assertEqual((text['helixShader'], text['kind']), (2, 'screen'))
            self.assertNotIn('sdlGpu', text)
            self.assertIn('sdlGpu', json.loads(json.loads(dialects.split('  return ', 1)[1].split(';\n', 1)[0])))
            self.assertIn('"film_grain" => () -> FilmGrainPacked.text()', (out / 'PackedShaders.hx').read_text(encoding='utf-8'))
            self.assertEqual(pack_shader.pack_library(out, gpu, sources, SHDC), [], 'packed again only when changed')
            (sources / 'film_grain.glsl').unlink()
            self.assertEqual(pack_shader.pack_library(out, gpu, sources, SHDC), [])
            self.assertFalse((out / 'FilmGrainPacked.hx').exists() or (gpu / 'FilmGrainPackedSdlGpu.hx').exists())
            self.assertIn('return new Map();', (out / 'PackedShaders.hx').read_text(encoding='utf-8'))

    def test_class_names(self):
        self.assertEqual([pack_shader.class_name(s) for s in ('unlit', 'color_lut', 'chromatic-aberration')], ['Unlit', 'ColorLut', 'ChromaticAberration'])


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]], verbosity=2)
