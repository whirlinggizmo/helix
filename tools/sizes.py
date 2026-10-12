"""Same-compressor delivery accounting, artifact identities and shared-source inventory."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/results/asteroids'

def main():
    files=[];optional=[]
    web=ROOT/'build/web/asteroids'
    for path in sorted(p for p in web.rglob('*') if p.is_file()):
        name=path.relative_to(web).as_posix();data=path.read_bytes()
        brotli=int(subprocess.check_output(['node','-e','const fs=require("fs"),z=require("zlib");console.log(z.brotliCompressSync(fs.readFileSync(process.argv[1]),{params:{[z.constants.BROTLI_PARAM_QUALITY]:11}}).length)',str(path)],text=True))
        value={'file':name,'rawBytes':len(data),'gzipBytes':len(gzip.compress(data,compresslevel=9,mtime=0)),'brotliBytes':brotli,'sha256':hashlib.sha256(data).hexdigest(),'category':'sound' if name.startswith('assets/sounds/') else 'code' if name in ['index.html','app.js'] else 'tooling'}
        (optional if value['category']=='tooling' else files).append(value)
    def totals(values):return {key:sum(f[key] for f in values) for key in ['rawBytes','gzipBytes','brotliBytes']}
    sources={}
    core=[p for p in (ROOT/'src/helix').rglob('*.hx') if 'adapters' not in p.parts and 'profiles' not in p.parts]
    adapters=[p for p in (ROOT/'src/helix/adapters').rglob('*') if p.suffix in ['.hx','.c','.h']]
    native_names={'sokol','haxehttp','filesystem','libsndfile','evdev'}
    native_hx=[p for p in adapters if native_names.intersection(p.relative_to(ROOT/'src/helix/adapters').parts) or p.stem=='SokolNativeBuild']
    for category,paths in [('framework',core),('game',list((ROOT/'examples/asteroids/src').glob('*.hx'))),('webAdapter',[p for p in adapters if p not in native_hx]+[ROOT/'src/helix/profiles/BrowserWebGL2Profile.hx',ROOT/'examples/asteroids/launch/browser-webgl2/Main.hx']),('nativeAdapter',native_hx+[ROOT/'src/helix/profiles/NativeSokolGLProfile.hx',ROOT/'examples/asteroids/launch/native-sokol-gl/Main.hx'])]:
        sources[category]={'files':{str(p.relative_to(ROOT)):len([line for line in p.read_text().splitlines() if line.strip()]) for p in sorted(paths)},'targetConditionals':sum(len(re.findall(r'^\s*#(?:if|elseif)',p.read_text(),re.M)) for p in paths)}
        sources[category]['nonblankPhysicalLines']=sum(sources[category]['files'].values())
    assert sources['framework']['targetConditionals']==sources['game']['targetConditionals']==0
    exe=ROOT/'build/native/asteroids/Main'
    report={'sourceFiles':{name:value for name,value in json.loads((ROOT/'build/source-identities.json').read_text()).items() if '__pycache__' not in Path(name).parts},'compression':'Per-file Python gzip level9 mtime0, Node Brotli quality11; HTML included','files':files,'total':totals(files),'codeTotal':totals([f for f in files if f['category']=='code']),'soundTotal':totals([f for f in files if f['category']=='sound']),'optionalFiles':optional,'optionalTotal':totals(optional),'allDeployedTotal':totals(files+optional),'wasmBytes':0,
            'native':{'file':'Main','rawBytes':exe.stat().st_size,'sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'stripped':False,'excluded':'Assets and dynamically supplied libsndfile/codec dependencies, ALSA, GL, X11, libc/runtime and GPU drivers'},'sourceSplit':sources,'shaders':json.loads((ROOT/'build/shader-identities.json').read_text()),'services':json.loads((ROOT/'dependencies.json').read_text())['sokol']['audio'],
            'audioEncoder':json.loads((ROOT/'build/audio-encoder.json').read_text()),'nativeCodecSDK':json.loads((ROOT/'dependencies.json').read_text())['sndfileSDK']}
    report['native']['dynamicDependencies']=subprocess.check_output(['ldd',str(exe)],text=True)
    assert 'SDL' not in report['native']['dynamicDependencies']
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'shader-contract.json').write_text((ROOT/'build/generated/asteroids/shader-contract.json').read_text())
    (OUT/'sizes.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report['total']))

if __name__=='__main__':main()
