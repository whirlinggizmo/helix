"""Checks of the shader packer, tools/shader/ShaderPacker.hx (run through tools/shader_tool.py, as the repository's tools run it), against
real sokol-shdc output: an app's screen effect packed with its kind, its blocks and their members' std140 offsets, its textures, both
dialects; the shaders it refuses; a surface shader's variants (skinned, and the casters of one with a vertex hook or a discard) and its own
textures after the joints; a sprite shader over the effect2d program's vertices, and its variant over the 3D sprites'; the shader library
(src/helix/shaders) packed for every backend, SDL_GPU's dialects too (glslang and SPIRV-Cross, fetched into the user's cache when
missing); and the library packed into generated Haxe, again only when changed, its classes named for its files, and gone with its source."""
import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import shader_tool

argparse.ArgumentParser(description=__doc__).parse_args()
LIBRARY = ROOT / 'src/helix/shaders'

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


def pack(source, sdl_gpu=False):
    """source (GLSL text) packed as an .hxshader file, read back."""
    with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
        glsl = Path(scratch) / 'shader.glsl'
        glsl.write_text(source, encoding='utf-8')
        return packed(glsl, sdl_gpu=sdl_gpu)


def packed(*sources, sdl_gpu=False):
    """The .hxshader files packed from sources (paths) in one run, read back: one, or a list for several."""
    with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
        outputs = [Path(scratch) / f'{i}.hxshader' for i in range(len(sources))]
        shader_tool.pack(zip(sources, outputs), sdl_gpu)
        shaders = [json.loads(out.read_text(encoding='utf-8')) for out in outputs]
        return shaders[0] if len(shaders) == 1 else shaders


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

    def test_model_space_in_every_variant(self):
        # Where a fragment is on the model at rest (helix_model_position, helix_model_normal) reads alike in the program, its skinned variant
        # and its casters: each vertex stage passes the vertex as the mesh gives it, before skinning moves it.
        shader = self.pack(SURFACE.replace('helix_output(', 'if (helix_model_position().x * helix_model_normal().y < 0.0) discard;\n    helix_output('))
        for name, variant in (('program', shader), ('skinned', shader['skinned']), ('caster', shader['caster']), ('skinnedCaster', shader['skinnedCaster'])):
            with self.subTest(variant=name):
                self.assertRegex(variant['glsl410']['vertex'], r'helix_v_model_position = position;')
                self.assertRegex(variant['glsl410']['vertex'], r'helix_v_model_normal = normal;')
                self.assertIn('helix_v_model_position', variant['glsl410']['fragment'])

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


SPRITE = '''@fs fs
@include_block helix_sprite
layout(binding=2) uniform params {
    vec4 glow;
    float reach;
};
layout(binding=1) uniform texture2D mask;
layout(binding=1) uniform sampler mask_sampler;
void main() {
    vec4 own = helix_sprite_color() * texture(sampler2D(mask, mask_sampler), helix_quad_uv());
    float near = helix_region_texel_at(helix_uv() + helix_texel_size() * reach).a;
    helix_output(mix(own.rgb, glow.rgb, near * helix_time()), own.a);
}
@end
'''


class SpriteTests(unittest.TestCase):
    def test_sprite_kind(self):
        shader = pack(SPRITE)
        self.assertEqual(shader['kind'], 'sprite')
        self.assertEqual(shader['attributes'], ['position', 'uv', 'color', 'region'])
        self.assertFalse({'skinned', 'caster', 'skinnedCaster'} & set(shader), "a sprite shader has none of a surface's variants")
        blocks = {b['slot']: b for b in shader['uniformBlocks']}
        self.assertEqual((blocks[0]['stage'], blocks[0]['size'], blocks[0]['name']), ('vertex', 16, 'helix_sprite_vs_params'))
        self.assertEqual((blocks[1]['stage'], blocks[1]['size'], blocks[1]['name']), ('fragment', 16, 'helix_sprite_params'))
        self.assertEqual([(m['name'], m['offset']) for m in blocks[2]['members']], [('glow', 0), ('reach', 16)])
        self.assertEqual([(t['slot'], t['name']) for t in shader['textures']], [(0, 'helix_sprite_texture'), (1, 'mask')])
        # The region reaches the fragment stage unblended (flat), in both dialects.
        for dialect in ('glsl410', 'glsl300es'):
            self.assertIn('flat out', shader[dialect]['vertex'])

    def test_sprite3d_variant(self):
        shader = pack(SPRITE)
        variant = shader['sprite3D']
        self.assertEqual(variant['attributes'], ['corner', 'i_position', 'i_size', 'i_region', 'i_right', 'i_up', 'i_tint'])
        blocks = {b['slot']: b for b in variant['uniformBlocks']}
        # Block 0 the 3D sprites' uniforms (Sprite3DProgram's), the framework's block and the app's as the 2D program has them.
        self.assertEqual((blocks[0]['stage'], blocks[0]['size'], blocks[0]['name']), ('vertex', 112, 'helix_sprite3d_vs_params'))
        self.assertEqual(blocks[1]['name'], 'helix_sprite_params')
        own = lambda s: [b['members'] for b in s['uniformBlocks'] if b['slot'] == 2]
        self.assertEqual(own(shader), own(variant))
        self.assertEqual([(t['slot'], t['name']) for t in variant['textures']], [(0, 'helix_sprite_texture'), (1, 'mask')])
        # Its output applies the sprite's alpha mode: a mask's discard.
        self.assertIn('discard', variant['glsl300es']['fragment'])
        self.assertNotIn('discard', shader['glsl300es']['fragment'])

    def test_sprite_for_every_backend(self):
        shader = pack(SPRITE, sdl_gpu=True)
        for part in (shader, shader['sprite3D']):
            for dialect in ('spirv', 'msl', 'hlsl'):
                self.assertTrue(part['sdlGpu'][dialect]['vertex'] and part['sdlGpu'][dialect]['fragment'])

    def test_own_texture_at_the_sprites_refused(self):
        with self.assertRaises(SystemExit):
            pack(SPRITE.replace('binding=1) uniform', 'binding=0) uniform'))

    def test_vertices_are_effect2d_s(self):
        # Batch2D packs Effect2DProgram's vertices (the framework's effect2d program, shaders.json) for the kind's vertex stage.
        programs = json.loads((ROOT / 'src/helix/graphics/shaders/shaders.json').read_text(encoding='utf-8'))['programs']
        effect2d = next(p for p in programs if p['program'] == 'effect2d')
        self.assertEqual([a['name'] for a in effect2d['attributes']], pack(SPRITE)['attributes'])

    def test_library_sprite_parameters(self):
        # helix.shaders' sprite classes write these members: their blocks as the reflection lays them out, their textures at these slots.
        expected = {'sprite_outline': ([('outline_color', 0), ('width', 16)], []),
                    'sprite_flash': ([('flash', 0)], []),
                    'sprite_dissolve': ([('edge_color', 0), ('amount', 16), ('edge_width', 20), ('scale', 24)], [(1, 'dissolve_noise')]),
                    'palette_swap': ([('row', 0)], [(1, 'palette')])}
        shaders = packed(*(LIBRARY / f'{stem}.glsl' for stem in expected))
        for (stem, (members, textures)), shader in zip(expected.items(), shaders):
            with self.subTest(shader=stem):
                self.assertEqual(shader['kind'], 'sprite')
                found = {b['slot']: [(m['name'], m['offset']) for m in b['members']] for b in shader['uniformBlocks'] if 'members' in b}
                self.assertEqual(found, {2: members})
                self.assertEqual([(t['slot'], t['name']) for t in shader['textures'] if t['slot'] > 0], textures)


class LibraryTests(unittest.TestCase):
    def test_every_library_shader_packs_for_every_backend(self):
        sources = sorted(LIBRARY.glob('*.glsl'))
        self.assertTrue(len(sources) > 1)
        for source, shader in zip(sources, packed(*sources, sdl_gpu=True)):
            with self.subTest(shader=source.name):
                self.assertIn(shader['kind'], ('screen', 'surface', 'sprite'))
                for dialect, version in (('glsl410', '#version 410'), ('glsl300es', '#version 300 es')):
                    self.assertTrue(shader[dialect]['vertex'].startswith(version) and shader[dialect]['fragment'].startswith(version))
                for dialect in ('spirv', 'msl', 'hlsl'):
                    self.assertTrue(shader['sdlGpu'][dialect]['vertex'] and shader['sdlGpu'][dialect]['fragment'])

    def test_unlit_parameters(self):
        shader = packed(LIBRARY / 'unlit.glsl')
        blocks = {b['slot']: b for b in shader['uniformBlocks']}
        # helix.shaders.Unlit's color field writes this member: the block at binding 2, a vec4 at its start.
        self.assertEqual([(m['name'], m['type'], m['offset'], m['count']) for m in blocks[2]['members']], [('color', 'vec4', 0, 1)])

    def test_library_parameters(self):
        # helix.shaders' classes write these members: Toon's, Dissolve's and Water's blocks as the reflection lays them out.
        expected = {'toon': {2: [('shadow_color', 0), ('bands', 16)]},
                    'dissolve': {2: [('edge_color', 0), ('amount', 16), ('edge_width', 20), ('scale', 24)]},
                    'water': {2: [('deep_color', 0), ('shallow_color', 16), ('sky_color', 32), ('shininess', 48)],
                              3: [('amplitude', 0), ('wavelength', 4), ('wave_speed', 8)]}}
        shaders = packed(*(LIBRARY / f'{stem}.glsl' for stem in expected))
        for (stem, blocks), shader in zip(expected.items(), shaders):
            with self.subTest(shader=stem):
                found = {b['slot']: [(m['name'], m['offset']) for m in b['members']] for b in shader['uniformBlocks'] if 'members' in b}
                self.assertEqual(found, blocks)
                self.assertEqual('caster' in shader, stem != 'toon')

    def test_pack_library(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as scratch:
            scratch = Path(scratch)
            sources, out, gpu = scratch / 'sources', scratch / 'out', scratch / 'gpu'
            sources.mkdir()
            (sources / 'film_grain.glsl').write_text(EFFECT, encoding='utf-8')
            (sources / 'color-lut.glsl').write_text(EFFECT, encoding='utf-8')
            self.assertEqual(shader_tool.pack_library(out, gpu, sources), ['color-lut', 'film_grain'])
            # Each class named for its file, its words capitalized.
            self.assertTrue((out / 'ColorLutPacked.hx').is_file() and (gpu / 'ColorLutPackedSdlGpu.hx').is_file())
            (sources / 'color-lut.glsl').unlink()
            base, dialects = (out / 'FilmGrainPacked.hx').read_text(encoding='utf-8'), (gpu / 'FilmGrainPackedSdlGpu.hx').read_text(encoding='utf-8')
            self.assertIn('#if helix_sdl3_gpu\n  return FilmGrainPackedSdlGpu.text();', base)
            # The literal is the .hxshader's JSON as a string: Haxe's escapes are JSON's.
            text = json.loads(json.loads(base.split('  return ', 2)[2].split(';\n', 1)[0]))
            self.assertEqual((text['helixShader'], text['kind']), (2, 'screen'))
            self.assertNotIn('sdlGpu', text)
            self.assertIn('sdlGpu', json.loads(json.loads(dialects.split('  return ', 1)[1].split(';\n', 1)[0])))
            self.assertIn('"film_grain" => () -> FilmGrainPacked.text()', (out / 'PackedShaders.hx').read_text(encoding='utf-8'))
            self.assertEqual(shader_tool.pack_library(out, gpu, sources), [], 'packed again only when changed')
            self.assertFalse((out / 'ColorLutPacked.hx').exists() or (gpu / 'ColorLutPackedSdlGpu.hx').exists())
            (sources / 'film_grain.glsl').unlink()
            self.assertEqual(shader_tool.pack_library(out, gpu, sources), [])
            self.assertFalse((out / 'FilmGrainPacked.hx').exists() or (gpu / 'FilmGrainPackedSdlGpu.hx').exists())
            self.assertIn('return new Map();', (out / 'PackedShaders.hx').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]], verbosity=2)
