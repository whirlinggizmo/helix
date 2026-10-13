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

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--shdc', required=True)
SHDC = parser.parse_args().shdc
SHADERS = ROOT / 'src/helix/graphics/shaders'


class ShaderMetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(dir=ROOT / 'build')
        cls.directory = Path(cls.temp.name)
        cls.specs = {spec['program']: spec for spec in manifest(SHADERS / 'shaders.json')}
        cls.baseline = cls.directory / 'baseline'; cls.baseline.mkdir()
        for program in cls.specs:
            cls.compile((SHADERS / f'{program}.glsl').read_text(), cls.baseline, program)
        cls.sprite = cls.baseline / 'sprite2d_reflection.yaml'
        cls.document = yaml.safe_load(cls.sprite.read_text())

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def compile(cls, source, folder, program):
        path = folder / f'{program}-input.glsl'; path.write_text(source)
        subprocess.run([SHDC, '-i', str(path), '-o', str(folder / program), '-l',
                        'glsl410:glsl300es', '-f', 'bare_yaml', '--no-log-cmdline'], check=True, cwd=ROOT)

    def manifest_of(self, folder, specs):
        path = folder / 'shaders.json'; path.write_text(json.dumps({'programs': specs}))
        return path

    def mutated(self, change, source=None):
        document = copy.deepcopy(yaml.safe_load((source or self.sprite).read_text())); change(document)
        path = self.directory / 'mutated.yaml'; path.write_text(yaml.safe_dump(document))
        return path

    def test_real_output_and_paths(self):
        # A misleading old source file must never be chosen by a filename glob.
        (self.baseline / 'old_glsl300es_vertex.glsl').write_text('STALE')
        contracts = generate(SHADERS / 'shaders.json', self.baseline, ROOT)
        sprite, color, lit = contracts
        self.assertEqual((sprite['stride'], [a['offset'] for a in sprite['attributes']]), (32, [0, 8, 16]))
        self.assertEqual((color['stride'], [a['offset'] for a in color['attributes']], color['uniforms'][0]['bytes']), (28, [0, 12], 64))
        self.assertIsNone(color['texture']); self.assertEqual(sprite['uniforms'], [])
        self.assertEqual((lit['stride'], lit['instanceStride'], [u['stage'] for u in lit['uniforms']]), (32, 112, ['vertex', 'fragment']))
        self.assertEqual({a['buffer'] for a in lit['attributes'] if a['name'].startswith('i_')}, {1})
        self.assertNotIn('STALE', (self.baseline / 'GeneratedShader.hx').read_text())
        header = (self.baseline / 'shaders.h').read_text()
        self.assertIn('helix_sprite2d_layout', header); self.assertIn('helix_color3d_layout', header)
        self.assertIn('vertexUniformBytes=64', (self.baseline / 'Color3DLayout.hx').read_text())
        self.assertIn('SG_VERTEXSTEP_PER_INSTANCE', header)

    def test_real_relocated_and_renamed_bindings(self):
        source = (SHADERS / 'sprite2d.glsl').read_text()
        source = source.replace('location=0', 'location=5').replace('location=1', 'location=3').replace('location=2', 'location=1')
        source = source.replace('binding=0) uniform texture', 'binding=4) uniform texture')
        source = source.replace('binding=0) uniform sampler', 'binding=2) uniform sampler')
        source = source.replace('position', 'vertexPosition').replace('atlasSampler', 'pixelSampler').replace('atlas', 'pixels')
        folder = self.directory / 'relocated'; folder.mkdir()
        self.compile(source, folder, 'sprite2d')
        spec = copy.deepcopy(self.specs['sprite2d']); spec['attributes'][0]['name'] = 'vertexPosition'
        contract, = generate(self.manifest_of(folder, [spec]), folder, ROOT)
        self.assertEqual([a['slot'] for a in contract['attributes']], [5, 3, 1])
        texture = contract['texture']
        self.assertEqual((texture['view'], texture['sampler'], texture['textureUniform']), (4, 2, 'pixels_pixelSampler'))
        self.assertIn('layout.attrs[5]', (folder / 'shaders.h').read_text())
        self.assertIn('positionName="vertexPosition"', (folder / 'Sprite2DLayout.hx').read_text())

    def test_duplicate_yaml_key_rejected(self):
        path = self.directory / 'duplicate.yaml'; path.write_text('shaders: []\nshaders: []\n')
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
        block = {'slot': 0, 'stage': 'vertex', 'size': 64, 'struct_name': 'extra', 'inst_name': '_1',
                 'glsl_uniforms': [{'type': 'vec4', 'array_count': 4, 'offset': 0, 'glsl_name': 'extra'}]}
        path = self.mutated(lambda d: [s['programs'][0].update(uniform_blocks=[block]) for s in d['shaders']])
        with self.assertRaisesRegex(MetadataError, 'uniform blocks'): load_contract(path, self.specs['sprite2d'])

    def test_uniform_size_mismatch_rejected(self):
        spec = copy.deepcopy(self.specs['color3d']); spec['uniforms'][0]['bytes'] = 128
        with self.assertRaisesRegex(MetadataError, 'uniform block'): load_contract(self.baseline / 'color3d_reflection.yaml', spec)

    def test_missing_texture_rejected(self):
        spec = copy.deepcopy(self.specs['color3d']); spec['texture'] = True
        with self.assertRaises(MetadataError): load_contract(self.baseline / 'color3d_reflection.yaml', spec)

    def test_inconsistent_resource_pair_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['texture_sampler_pairs'][0].update(view_slot=3))
        with self.assertRaises(MetadataError): load_contract(path, self.specs['sprite2d'])

    def test_source_outside_output_rejected(self):
        folder = self.directory / 'outside'; folder.mkdir()
        document = yaml.safe_load(self.sprite.read_text())
        document['shaders'][1]['programs'][0]['vertex_func']['path'] = str(SHADERS / 'shaders.json')
        (folder / 'sprite2d_reflection.yaml').write_text(yaml.safe_dump(document))
        with self.assertRaises(MetadataError): generate(self.manifest_of(folder, [self.specs['sprite2d']]), folder, ROOT)


if __name__ == '__main__':
    (ROOT / 'build').mkdir(exist_ok=True)
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ShaderMetadataTests))
    sys.exit(0 if result.wasSuccessful() else 1)
