"""Portable Haxe/Node/CMake orchestration. Native linking currently implements Linux."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from tools.shader_metadata import generate
from tools.assets import generate as generate_assets

ROOT=Path(__file__).resolve().parent
STUDY=ROOT.parents[2]

def run(args,env=None):
    print('Running:',json.dumps(list(map(str,args))),flush=True)
    subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target',choices=['web','native','all','test'])
    parser.add_argument('--shdc',default=os.environ.get('SOKOL_SHDC'))
    args=parser.parse_args()
    pins=json.loads((ROOT/'dependencies.json').read_text())
    for name,identity in pins['sndfileSDK']['files'].items():
        if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=identity:
            raise RuntimeError('Pinned libsndfile SDK file changed: '+name)
    build=ROOT/'build';generated=build/'generated';generated.mkdir(parents=True,exist_ok=True)
    if args.target=='test':
        generate_assets()
        run([sys.executable,'tests/shader_metadata_test.py','--shdc',args.shdc or shutil.which('sokol-shdc') or 'sokol-shdc'])
        run(['haxe','-cp','framework','-cp','tests','-main','PackageSmoke','--interp'])
        (build/'tests').mkdir(exist_ok=True)
        run(['haxe','-cp','framework','-cp','tests','-main','PackageSmoke','-js',build/'tests/package-smoke.js','-dce','full'])
        run(['node',build/'tests/package-smoke.js'])
        (ROOT.parent/'results/package-smoke.json').write_text(json.dumps({'passed':True,'targets':['interpreter','JS/Node'],'classpaths':['framework','tests'],'sha256':hashlib.sha256((build/'tests/package-smoke.js').read_bytes()).hexdigest()},indent=2)+'\n')
        command=['haxe','-cp','framework','-cp','src','-cp','tests','-main','SimulationTests','--interp']
        result=subprocess.check_output(command,cwd=ROOT,text=True)
        print(result,end='')
        evidence=ROOT.parent/'results';evidence.mkdir(exist_ok=True)
        (evidence/'simulation-tests.log').write_text(result)
        value=json.loads(result[result.index('{'):]);assert value['passed'] and value['checks']>=30
        (evidence/'simulation-tests.json').write_text(json.dumps(value,indent=2)+'\n')
        return
    shdc=args.shdc or shutil.which('sokol-shdc')
    if not shdc:raise RuntimeError('Pass --shdc /path/to/pinned/sokol-shdc (sokol-tools-bin 11d0cf678105d614d675e6d9bd2aaf3eeff12f8c)')
    run([shdc,'-i','shaders/sprite.glsl','-o',generated/'sprite.glsl.h','-l','glsl410:glsl300es','--no-log-cmdline'])
    run([shdc,'-i','shaders/sprite.glsl','-o',generated/'sprite','-l','glsl410:glsl300es','-f','bare_yaml','--no-log-cmdline'])
    generate(generated/'sprite_reflection.yaml',ROOT/'shaders/vertex.json',generated,ROOT)
    assets=generate_assets()
    if args.target in ['web','all']:
        out=build/'web';out.mkdir(exist_ok=True)
        run(['haxe','web.hxml'])
        terser=build/'tools/node_modules/terser/bin/terser'
        if not terser.is_file():raise RuntimeError('Install tools: npm install --prefix '+str(build/'tools')+' terser@5.44.1 playwright@1.64.0 pngjs@7.0.0')
        run(['node',terser,out/'app.js','--compress','--mangle','--output',out/'app.js'])
        shutil.copyfile(ROOT/'web/index.html',out/'index.html')
        if (out/'assets').exists():shutil.rmtree(out/'assets')
        shutil.copytree(assets,out/'assets')
    if args.target in ['native','all']:
        if sys.platform!='linux':raise RuntimeError('Only Linux native linking is implemented; browser build remains portable.')
        archive=build/'native-hal'
        run(['cmake','-S',ROOT,'-B',archive,'-DCMAKE_BUILD_TYPE=Release'])
        run(['cmake','--build',archive,'--config','Release'])
        env=dict(os.environ,HY_ROOT=ROOT.as_posix(),HY_LIBRARY=(archive/'libhybrid.a').as_posix(),HY_CODEC_LIBRARY=json.loads((archive/'codec-link.json').read_text())['library'])
        # Keep hxcpp's cache in the experiment rather than mutating global caches.
        config=build/'hxcpp_config.xml';config.write_text('<xml><set name="HXCPP_COMPILE_CACHE" value="'+(build/'hxcpp-cache').as_posix()+'"/></xml>\n')
        env['HXCPP_CONFIG']=str(config)
        run(['haxe','native.hxml'],env)
    if args.target in ['native','all']:
        if (build/'native/assets').exists():shutil.rmtree(build/'native/assets')
        shutil.copytree(assets,build/'native/assets')
    identities={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'shaders/sprite.glsl',ROOT/'shaders/vertex.json',generated/'sprite.glsl.h',generated/'sprite_reflection.yaml',generated/'shader-contract.json',generated/'GeneratedLayout.hx',generated/'GeneratedShader.hx',generated/'vertex_layout.h']}
    identities['sokol-shdc']=hashlib.sha256(Path(shdc).read_bytes()).hexdigest()
    (build/'shader-identities.json').write_text(json.dumps(identities,indent=2)+'\n')

if __name__=='__main__':main()
