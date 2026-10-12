"""Regression checks against real shdc output, including moved/renamed bindings."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.shader_metadata import MetadataError, generate, load_contract, yaml

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--shdc', required=True)
SHDC = parser.parse_args().shdc


class ShaderMetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(dir=ROOT / 'build')
        cls.directory = Path(cls.temp.name)
        cls.schema = ROOT / 'shaders/vertex.json'
        cls.metadata = cls.compile((ROOT / 'shaders/sprite.glsl').read_text(), 'baseline')
        cls.document = yaml.safe_load(cls.metadata.read_text())

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def compile(cls, source, label):
        folder = cls.directory / label; folder.mkdir()
        path = folder / 'input.glsl'; path.write_text(source)
        subprocess.run([SHDC, '-i', str(path), '-o', str(folder / 'sprite'), '-l',
                        'glsl410:glsl300es', '-f', 'bare_yaml', '--no-log-cmdline'], check=True, cwd=ROOT)
        return folder / 'sprite_reflection.yaml'

    def mutated(self, change):
        document = copy.deepcopy(self.document); change(document)
        path = self.directory / 'mutated.yaml'; path.write_text(yaml.safe_dump(document))
        return path

    def test_real_output_and_paths(self):
        # A misleading old source file must never be chosen by a filename glob.
        (self.metadata.parent / 'old_glsl300es_vertex.glsl').write_text('STALE')
        contract = generate(self.metadata, self.schema, self.metadata.parent, ROOT)
        self.assertEqual(contract['stride'], 32)
        self.assertEqual([a['offset'] for a in contract['attributes']], [0, 8, 16])
        self.assertNotIn('STALE', (self.metadata.parent / 'GeneratedShader.hx').read_text())

    def test_real_relocated_and_renamed_bindings(self):
        source = (ROOT / 'shaders/sprite.glsl').read_text()
        source = source.replace('location=0', 'location=5').replace('location=1', 'location=3').replace('location=2', 'location=1')
        source = source.replace('binding=0) uniform texture', 'binding=4) uniform texture')
        source = source.replace('binding=0) uniform sampler', 'binding=2) uniform sampler')
        source = source.replace('position', 'vertexPosition').replace('atlasSampler', 'pixelSampler').replace('atlas', 'pixels')
        metadata = self.compile(source, 'relocated')
        schema = json.loads(self.schema.read_text()); schema['attributes'][0]['name'] = 'vertexPosition'
        schema_path = metadata.parent / 'vertex.json'; schema_path.write_text(json.dumps(schema))
        contract = generate(metadata, schema_path, metadata.parent, ROOT)
        self.assertEqual([a['slot'] for a in contract['attributes']], [5, 3, 1])
        self.assertEqual((contract['view'], contract['sampler'], contract['uniform']), (4, 2, 'pixels_pixelSampler'))
        self.assertIn('layout.attrs[5]', (metadata.parent / 'vertex_layout.h').read_text())
        self.assertIn('positionName="vertexPosition"', (metadata.parent / 'GeneratedLayout.hx').read_text())

    def test_duplicate_yaml_key_rejected(self):
        path = self.directory / 'duplicate.yaml'; path.write_text('shaders: []\nshaders: []\n')
        with self.assertRaises(MetadataError): load_contract(path, self.schema)

    def test_type_mismatch_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][0].update(type='vec4'))
        with self.assertRaises(MetadataError): load_contract(path, self.schema)

    def test_dialect_disagreement_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][0].update(slot=5))
        with self.assertRaisesRegex(MetadataError, 'disagree'): load_contract(path, self.schema)

    def test_duplicate_attribute_slot_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['attrs'][1].update(slot=0))
        with self.assertRaises(MetadataError): load_contract(path, self.schema)

    def test_new_resource_kind_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0].update(uniform_blocks=[]))
        with self.assertRaises(MetadataError): load_contract(path, self.schema)

    def test_inconsistent_resource_pair_rejected(self):
        path = self.mutated(lambda d: d['shaders'][0]['programs'][0]['texture_sampler_pairs'][0].update(view_slot=3))
        with self.assertRaises(MetadataError): load_contract(path, self.schema)

    def test_source_outside_output_rejected(self):
        path = self.mutated(lambda d: d['shaders'][1]['programs'][0]['vertex_func'].update(path=str(self.schema)))
        with self.assertRaises(MetadataError): generate(path, self.schema, self.metadata.parent, ROOT)


if __name__ == '__main__':
    (ROOT / 'build').mkdir(exist_ok=True)
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ShaderMetadataTests))
    evidence = {'checks': result.testsRun, 'passed': result.wasSuccessful(),
                'realCompilerFixture': 'Renamed position/texture/sampler; attribute slots 5/3/1, view4, sampler2',
                'parser': 'PyYAML ' + yaml.__version__ + ' SafeLoader with duplicate-key rejection'}
    (ROOT.parent / 'results/shader-metadata-tests.json').write_text(json.dumps(evidence, indent=2) + '\n')
    sys.exit(0 if result.wasSuccessful() else 1)
