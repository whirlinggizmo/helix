"""HeliX's front door for the tests and the services checks. Python owns external tools; HXML owns Haxe settings.

Examples have their own: tools/example.py."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parent
UNIT={'InputTests':[],'HostTests':[],'AssetTests':[],'Render3DTests':[],'BlocksTests':['examples/blocks/src'],'SimulationTests':['examples/asteroids/src']}

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def test(shdc,native,audio_device):
    """The shader tool tests, the package smoke test on the interpreter and Node, every unit test, and with native the C service tests."""
    sys.path.insert(0,str(ROOT/'tools'))
    from fixtures import generate
    generate()
    run([sys.executable,'tests/shaders/shader_metadata_test.py','--shdc',shdc or shutil.which('sokol-shdc') or 'sokol-shdc'])
    run(['haxe','-cp','src','-cp','tests/consumer','-main','PackageSmoke','--interp'])
    (ROOT/'build/tests').mkdir(parents=True,exist_ok=True)
    run(['haxe','-cp','src','-cp','tests/consumer','-main','PackageSmoke','-js','build/tests/package-smoke.js','-dce','full'])
    run(['node','build/tests/package-smoke.js'])
    for main,classpaths in UNIT.items():
        output=subprocess.check_output(['haxe','-cp','src','-cp','tests/unit',*sum((['-cp',c] for c in classpaths),[]),'-main',main,'--interp'],cwd=ROOT,text=True)
        value=json.loads(output[output.index('{'):]);assert value['passed']
        print(f'{main}: {value["checks"]} checks',flush=True)
    if native:
        from native_build import tool
        print(subprocess.check_output([str(tool('native-services-test'))],text=True),end='')
        if audio_device:print(subprocess.check_output([str(tool('native-audio-probe'))],text=True),end='')

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True,metavar='command')
    tests=sub.add_parser('test',help='Run the tool, package and unit tests; --native adds the native service tests');tests.add_argument('--shdc');tests.add_argument('--native',action='store_true');tests.add_argument('--audio-device',action='store_true')
    services=sub.add_parser('services',help='Check the browser (and optionally native) platform services');services.add_argument('--browser',required=True);services.add_argument('--native',action='store_true')
    a=p.parse_args()
    if a.command=='test':
        if a.audio_device and not a.native:p.error('--audio-device requires --native')
        test(a.shdc,a.native,a.audio_device)
    else:run([sys.executable,ROOT/'tools/services.py','--browser',a.browser,*(['--native'] if a.native else [])])

if __name__=='__main__':main()
