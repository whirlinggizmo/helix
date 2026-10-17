"""HeliX's front door for the tests and the services checks. Python owns external tools; HXML owns Haxe settings.

Examples have their own: tools/example.py."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parent
UNIT={'InputTests':[],'HostTests':[],'AssetTests':[],'AssetCacheTests':[],'Render2DTests':['build/generated/shaders','build/generated/fonts'],'ParticleTests':['build/generated/shaders','build/generated/fonts'],'Render3DTests':['build/generated/shaders','build/generated/fonts'],'EnvironmentTests':[],'TrigTests':[],'RandomTests':[],'TimeTests':[],'TweenTests':[],'CurveTests':[],'PresentationTests':['build/generated/shaders','build/generated/fonts'],'PngTests':[],'PickTests':['build/generated/shaders','build/generated/fonts'],'UiTests':['build/generated/shaders','build/generated/fonts'],'AnimationTests':['build/generated/shaders','build/generated/fonts'],'OutfitTests':['build/generated/shaders','build/generated/fonts','examples/dressing-room/src'],'BlocksTests':['examples/blocks/src'],'SimulationTests':['examples/asteroids/src']}

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def test(native,audio_device):
    """The adapter rule's check, the shader tool tests, the package smoke test on the interpreter and Node, every unit test, and with native the C service tests."""
    sys.path.insert(0,str(ROOT/'tools'))
    from gen_fixtures import generate
    import example,bake_fonts
    generate()
    # The generated shader and font code the unit tests compile against, made when missing or stale.
    example.shader();bake_fonts.generate()
    run([sys.executable,'tools/check_adapters.py'])
    for test in ('shader_metadata_test','pack_shader_test'):run([sys.executable,f'tests/shaders/{test}.py'])
    run(['haxe','-cp','src','-cp','tests/consumer','-main','PackageSmoke','--interp'])
    (ROOT/'build/tests').mkdir(parents=True,exist_ok=True)
    run(['haxe','-cp','src','-cp','tests/consumer','-main','PackageSmoke','-js','build/tests/package-smoke.js','-dce','full'])
    run(['node','build/tests/package-smoke.js'])
    for main,classpaths in UNIT.items():
        output=subprocess.check_output(['haxe','-cp','src','-cp','tests/unit',*sum((['-cp',c] for c in classpaths),[]),'-main',main,'--interp'],cwd=ROOT,text=True, encoding='utf-8')
        value=json.loads(output[output.index('{'):]);assert value['passed']
        print(f'{main}: {value["checks"]} checks',flush=True)
    trig(native)
    if native and not sys.platform.startswith('linux'):
        print('Native C service tests: skipped here (they feed Linux input_event records and build with cc)',flush=True)
    elif native:
        from native_build import tool
        print(subprocess.check_output([str(tool('native-services-test'))],text=True, encoding='utf-8'),end='')
        print(subprocess.check_output([str(tool('native-sdl3-input-test'))],text=True, encoding='utf-8'),end='')
        if audio_device:print(subprocess.check_output([str(tool('native-audio-probe'))],text=True, encoding='utf-8'),end='')

def trig(native):
    """helix.math.Trig's bits over fixed inputs: the same hash under the interpreter, in JS (Node) and, with native, in hxcpp. When they
    differ, the parts' hashes say where."""
    def lines(args, **kw):return [l for l in subprocess.check_output(args, cwd=ROOT, text=True, encoding='utf-8', **kw).splitlines() if l.startswith('trig ')]
    base = ['-cp', 'src', '-cp', 'tests/trig', '-main', 'TrigBits']
    outputs = {'interpreter': lines(['haxe', *base, '--interp'])}
    run(['haxe', *base, '-js', 'build/tests/trigbits.js', '-dce', 'full', '-D', 'analyzer-optimize'])
    outputs['js'] = lines(['node', 'build/tests/trigbits.js'])
    if native:
        from pins import check_hxcpp
        from native_build import ARCH
        check_hxcpp()
        run(['haxe', *base, '-cpp', 'build/tests/trigbits-cpp', '-dce', 'full', '-D', 'analyzer-optimize', '-D', ARCH],
            env={**os.environ, 'HAXELIB_PATH': str(ROOT / 'build/haxelib')})
        outputs['hxcpp'] = lines([str(ROOT / 'build/tests/trigbits-cpp' / ('TrigBits.exe' if sys.platform == 'win32' else 'TrigBits'))])
    hashes = {target: out[0] for target, out in outputs.items()}
    if len(set(hashes.values())) != 1:
        for parts in zip(*outputs.values()):
            if len(set(parts)) != 1:print('differs: ' + '  '.join(f'{target}: {part}' for target, part in zip(outputs, parts)))
        sys.exit(f'helix.math.Trig differs between targets: {hashes}')
    print(f'Trig bits: the same on {", ".join(hashes)}: {next(iter(hashes.values()))}', flush=True)

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True,metavar='command')
    tests=sub.add_parser('test',help='Run the tool, package and unit tests; --native adds the native service tests');tests.add_argument('--native',action='store_true');tests.add_argument('--audio-device',action='store_true')
    services=sub.add_parser('services',help='Check the browser (and optionally native) platform services');services.add_argument('--browser',required=True);services.add_argument('--native',action='store_true');services.add_argument('--native-profile',choices=['sokol','sdl3'],default='sokol')
    a=p.parse_args()
    if a.command=='test':
        if a.audio_device and not a.native:p.error('--audio-device requires --native')
        test(a.native,a.audio_device)
    else:run([sys.executable,ROOT/'tools/services.py','--browser',a.browser,*(['--native','--native-profile',a.native_profile] if a.native else [])])

if __name__=='__main__':main()
