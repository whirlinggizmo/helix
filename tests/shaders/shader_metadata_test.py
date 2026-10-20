"""Regression checks against real shdc output for the framework shaders, including moved/renamed bindings."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.shader_metadata import MetadataError, generate, load_contract, manifest, yaml

argparse.ArgumentParser(description=__doc__).parse_args()
from tools import shdc
SHDC = str(shdc.path())
SHADERS = ROOT / 'src/helix/graphics/shaders'


class ShaderMetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(dir=ROOT / 'build')
        cls.directory = Path(cls.temp.name)
        cls.specs = {spec['program']: spec for spec in manifest(SHADERS / 'shaders.json')}
        cls.baseline = cls.directory / 'baseline'; cls.baseline.mkdir()
        for program in cls.specs:
            cls.compile((SHADERS / f'{program}.glsl').read_text(encoding='utf-8'), cls.baseline, program)
        cls.sprite = cls.baseline / 'sprite2d_reflection.yaml'
        cls.document = yaml.safe_load(cls.sprite.read_text(encoding='utf-8'))

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def compile(cls, source, folder, program):
        # The framework's shared pieces (@include lit3d_shared.glsl, skinning.glsl) resolve beside the input.
        for shared in SHADERS.glob('*.glsl'):
            if not (folder / shared.name).exists():
                (folder / shared.name).write_text(shared.read_text(encoding='utf-8'))
        path = folder / f'{program}-input.glsl'; path.write_text(source, encoding='utf-8')
        subprocess.run([SHDC, '-i', str(path), '-o', str(folder / program), '-l',
                        'glsl410:glsl300es', '-f', 'bare_yaml', '--no-log-cmdline'], check=True, cwd=ROOT)

    def manifest_of(self, folder, specs):
        path = folder / 'shaders.json'; path.write_text(json.dumps({'programs': specs}), encoding='utf-8')
        return path

    def mutated(self, change, source=None):
        document = copy.deepcopy(yaml.safe_load((source or self.sprite).read_text(encoding='utf-8'))); change(document)
        path = self.directory / 'mutated.yaml'; path.write_text(yaml.safe_dump(document), encoding='utf-8')
        return path

    def test_real_output_and_paths(self):
        # A misleading old source file must never be chosen by a filename glob.
        (self.baseline / 'old_glsl300es_vertex.glsl').write_text('STALE', encoding='utf-8')
        contracts = generate(SHADERS / 'shaders.json', self.baseline, ROOT)
        by = {c['program']: c for c in contracts}
        self.assertEqual(list(by), ['sprite2d', 'effect2d', 'color3d', 'lit3d', 'sprite3d', 'particle3d', 'depth3d', 'background3d', 'skinned3d',
                                    'skinneddepth3d', 'flat3d', 'skinnedflat3d'])
        sprite, color, lit, depth, background = by['sprite2d'], by['color3d'], by['lit3d'], by['depth3d'], by['background3d']
        # A model's flat passes read the mesh's pass vertices (a position and an averaged normal) and the lit models' instance records, the
        # normals' rows where the lit's are.
        flat = by['flat3d']
        self.assertEqual((flat['stride'], flat['instanceStride'], [a['offset'] for a in flat['attributes'] if a['buffer'] == 1]),
                         (24, 144, [0, 16, 32, 48, 64, 80]))
        self.assertEqual([a['offset'] for a in flat['attributes'] if a['buffer'] == 0], [0, 12])
        self.assertEqual((sprite['stride'], [a['offset'] for a in sprite['attributes']]), (32, [0, 8, 16]))
        # A sprite drawn through an effect: sprite2d's vertex and its region after it.
        effect = by['effect2d']
        self.assertEqual((effect['stride'], [(a['role'], a['offset']) for a in effect['attributes']]),
                         (48, [('position', 0), ('uv', 8), ('color', 16), ('region', 32)]))
        self.assertEqual((color['stride'], [a['offset'] for a in color['attributes']], color['uniforms'][0]['bytes']), (28, [0, 12], 64))
        self.assertEqual(color['textures'], []); self.assertEqual([(u['stage'], u['bytes']) for u in sprite['uniforms']], [('vertex', 16)])
        self.assertEqual([(t['role'], t['depthArray'], t['cube']) for t in lit['textures']],
                         [('base', False, False), ('normal', False, False), ('shadow', True, False), ('environment', False, True), ('brdf', False, False)])
        # The background draws a triangle from its vertex index: no attributes, no vertex layout; one cube.
        self.assertEqual((background['attributes'], [t['cube'] for t in background['textures']]), ([], [True]))
        # The depth program reads the lit models' vertices: their stride, its own positions' offset.
        self.assertEqual((depth['stride'], depth['attributes'][0]['offset'], depth['instanceStride']), (48, 0, 48))
        self.assertEqual((lit['stride'], lit['instanceStride'], [u['stage'] for u in lit['uniforms']]), (48, 144, ['vertex', 'fragment']))
        self.assertEqual({a['buffer'] for a in lit['attributes'] if a['name'].startswith('i_')}, {1})
        # Programs reach adapters as Haxe data only: no C header, no GLSL ES class, whatever an older build left.
        self.assertFalse([p.name for p in self.baseline.iterdir() if p.name in ('shaders.h', 'GeneratedShader.hx') or p.name.endswith('.glsl.h')])
        self.assertIn('vertexUniformBytes=64', (self.baseline / 'Color3DProgram.hx').read_text(encoding='utf-8'))
        self.assertIn('instanced: true', (self.baseline / 'Lit3DProgram.hx').read_text(encoding='utf-8'))
        self.assertIn('return [];', (self.baseline / 'Background3DProgram.hx').read_text(encoding='utf-8'))

    def test_real_relocated_and_renamed_bindings(self):
        source = (SHADERS / 'sprite2d.glsl').read_text(encoding='utf-8')
        # Reordered (slots run from 0 without gaps, as ShaderSource lists attributes by slot).
        source = source.replace('location=0', 'location=#2').replace('location=1', 'location=#0').replace('location=2', 'location=#1').replace('location=#', 'location=')
        source = source.replace('binding=0) uniform texture', 'binding=4) uniform texture')
        source = source.replace('binding=0) uniform sampler', 'binding=2) uniform sampler')
        source = source.replace('position', 'vertexPosition').replace('atlasSampler', 'pixelSampler').replace('atlas', 'pixels')
        folder = self.directory / 'relocated'; folder.mkdir()
        self.compile(source, folder, 'sprite2d')
        spec = copy.deepcopy(self.specs['sprite2d']); spec['attributes'][0]['name'] = 'vertexPosition'; spec['textures'][0]['name'] = 'pixels'
        contract, = generate(self.manifest_of(folder, [spec]), folder, ROOT)
        self.assertEqual([a['slot'] for a in contract['attributes']], [2, 0, 1])
        texture, = contract['textures']
        self.assertEqual((texture['view'], texture['sampler'], texture['uniform']), (4, 2, 'pixels_pixelSampler'))
        program = (folder / 'Sprite2DProgram.hx').read_text(encoding='utf-8')
        self.assertIn('{slot: 2, componentCount: 2, offset: 0}', program)
        self.assertIn('"vertexPosition"', program)

    def test_attribute_slot_gap_rejected(self):
        source = (SHADERS / 'sprite2d.glsl').read_text(encoding='utf-8').replace('location=2', 'location=5')
        folder = self.directory / 'gap'; folder.mkdir()
        self.compile(source, folder, 'sprite2d')
        with self.assertRaisesRegex(MetadataError, 'without gaps'): generate(self.manifest_of(folder, [self.specs['sprite2d']]), folder, ROOT)

    def test_duplicate_yaml_key_rejected(self):
        path = self.directory / 'duplicate.yaml'; path.write_text('shaders: []\nshaders: []\n', encoding='utf-8')
        with self.assertRaises(MetadataError): load_contract(path, self.specs['sprite2d'])

    def test_type_mismatch_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][0].update(type='vec4'))
        with self.assertRaises(MetadataError): load_contract(path, self.specs['sprite2d'])

    def test_dialect_disagreement_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][0].update(slot=5))
        with self.assertRaisesRegex(MetadataError, 'disagree'): load_contract(path, self.specs['sprite2d'])

    def test_duplicate_attribute_slot_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][1].update(slot=0))
        with self.assertRaises(MetadataError): load_contract(path, self.specs['sprite2d'])

    def test_undeclared_uniform_block_rejected(self):
        # One more block than the manifest declares (sprite2d has only its vertex block, at slot 0).
        block = {'slot': 1, 'stage': 'fragment', 'size': 64, 'struct_name': 'extra', 'inst_name': '_1',
                 'glsl_uniforms': [{'type': 'vec4', 'array_count': 4, 'offset': 0, 'glsl_name': 'extra'}]}
        path = self.mutated(lambda d: [s['programs'][0].update(uniform_blocks=s['programs'][0]['uniform_blocks'] + [block]) for s in d['shaders']])
        with self.assertRaisesRegex(MetadataError, 'uniform blocks'): load_contract(path, self.specs['sprite2d'])

    def test_uniform_size_mismatch_rejected(self):
        spec = copy.deepcopy(self.specs['color3d']); spec['uniforms'][0]['bytes'] = 128
        with self.assertRaisesRegex(MetadataError, 'uniform block'): load_contract(self.baseline / 'color3d_reflection.yaml', spec)

    def test_missing_texture_rejected(self):
        spec = copy.deepcopy(self.specs['color3d']); spec['textures'] = [{'role': 'base', 'name': 'missing'}]
        with self.assertRaises(MetadataError): load_contract(self.baseline / 'color3d_reflection.yaml', spec)

    def test_inconsistent_resource_pair_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['texture_sampler_pairs'][0].update(view_slot=3))
        with self.assertRaises(MetadataError): load_contract(path, self.specs['sprite2d'])

    def test_source_outside_output_rejected(self):
        folder = self.directory / 'outside'; folder.mkdir()
        document = yaml.safe_load(self.sprite.read_text(encoding='utf-8'))
        document['shaders'][1]['programs'][0]['vertex_func']['path'] = str(SHADERS / 'shaders.json')
        (folder / 'sprite2d_reflection.yaml').write_text(yaml.safe_dump(document), encoding='utf-8')
        with self.assertRaises(MetadataError): generate(self.manifest_of(folder, [self.specs['sprite2d']]), folder, ROOT)


if __name__ == '__main__':
    (ROOT / 'build').mkdir(exist_ok=True)
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ShaderMetadataTests))
    sys.exit(0 if result.wasSuccessful() else 1)
