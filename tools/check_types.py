"""Type-check every Haxe entry point for the browser and native targets without building anything (haxe --no-output).

For refactors: an API change is done when this passes, then the checks that run code. Takes seconds, no C++ compile. With --web, only
the browser's: every example for webgl2 and every test that isn't native's (CI's pushes, while native waits for the daily run).
Each example is also checked as the dev loop builds it (tools/example.py dev): the browser's debug build with hotreload-hx's build macro,
which builds classes in its own order, so code a plain build takes can fail there (decision 155). hotreload-hx is the one haxelib finds,
else the pinned revision installed into build/haxelib (tools/pins.py). The generated code (generated/, committed) is made current first (tools/gen_code.py: sokol-shdc, and glslang and SPIRV-Cross for SDL_GPU's
dialects, as the sdl3-gpu backend is checked too)."""
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
GENERATED={'shaders':'generated/shaders','fonts':'generated/fonts','sdlgpu':'generated/shaders-sdlgpu'}

def targets(web=False):
    """(label, haxe arguments, environment or None) for each entry point and target; with web, the browser's alone."""
    from example import source
    from variants import BACKENDS
    found=[]
    for example in sorted({p.parent.name for p in (ROOT/'examples').glob('*/App.hx')}|{p.parent.parent.name for p in (ROOT/'examples').glob('*/src/App.hx')}):
        # Each backend's launcher (examples/shared/launch/<backend>), as tools/example.py builds it.
        for backend in BACKENDS:
            if web and BACKENDS[backend]!='js':continue
            args=['-cp','src','-cp',source(example),'-cp','examples/shared/launch','-D',f'helix-backend={backend}','-cp',GENERATED['shaders'],'-cp',GENERATED['fonts'],'-main','Main','-D',f'example={example}']+(['-js','build/check_types.js'] if BACKENDS[backend]=='js' else ['-cpp','build/check_types-cpp'])+(['-D','helix_sdl3_gpu','-cp',GENERATED['sdlgpu']] if backend=='sdl3-gpu' else [])
            found.append((f'{example} {backend}',args,None))
            # The dev loop's build: the debug one, with what hotreload-hx's dev server adds to it (its library, hot, and where it says
            # how it was made).
            if BACKENDS[backend]=='js':found.append((f'{example} {backend} dev',args+['-debug','-lib','hotreload-hx','-D','hotreload','-D','hotreload_config=build/check_types-dev.json'],'hotreload'))
    for main,cp in (('SimulationTests',['examples/asteroids/src']),('BlocksTests',['examples/blocks/src']),('InputTests',[]),('ActionsTests',[GENERATED['shaders'],GENERATED['fonts']]),('AudioBusTests',[]),('HostTests',[]),('AssetTests',[]),('Render2DTests',[GENERATED['shaders'],GENERATED['fonts']]),('ParticleTests',[GENERATED['shaders'],GENERATED['fonts']]),('Render3DTests',[GENERATED['shaders'],GENERATED['fonts']]),('PostProcessTests',[GENERATED['shaders'],GENERATED['fonts']]),('EnvironmentTests',[]),('TrigTests',[]),('PngTests',[]),('ShaderLibraryTests',[GENERATED['shaders'],GENERATED['fonts']]),('PickTests',[GENERATED['shaders'],GENERATED['fonts']]),('TiledTests',[GENERATED['shaders'],GENERATED['fonts']]),('UiTests',[GENERATED['shaders'],GENERATED['fonts']]),('AnimationTests',[GENERATED['shaders'],GENERATED['fonts']]),('SceneFileTests',[GENERATED['shaders'],GENERATED['fonts']]),('SceneInstanceTests',[GENERATED['shaders'],GENERATED['fonts']]),('BehaviorTests',[GENERATED['shaders'],GENERATED['fonts']]),('CombatProbeTests',[GENERATED['shaders'],GENERATED['fonts']])):
        found.append((f'unit {main}',['-cp','src','-cp','tests/unit']+sum((['-cp',c] for c in cp),[])+['-main',main,'--interp'],None))
    found.append(('trig bits',['-cp','src','-cp','tests/trig','-main','TrigBits','--interp'],None))
    found.append(('package smoke',['-cp','src','-cp','tests/consumer','-main','PackageSmoke','--interp'],None))
    found.append(('services web',['-cp','src','-cp','tests/services','-cp','tests/services/web','-main','ServiceTests','-js','build/check_types.js'],None))
    if not web:found.append(('services native',['-cp','src','-cp','tests/services','-cp','tests/services/native','-main','ServiceTests','-cpp','build/check_types-cpp'],None))
    return found

def generate(web=False):
    """The generated code when it's missing or older than its source, SDL_GPU's dialects included unless web."""
    import gen_code
    gen_code.generate(sdl_gpu=not web)

def main():
    import argparse
    parser=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--web',action='store_true',help="the browser's alone: every example for webgl2 and every test that isn't native's")
    parser.add_argument('--no-output',action='store_true',help='accepted for the habit: nothing is ever built (haxe --no-output)')
    web=parser.parse_args().web
    generate(web)
    # The adapter rule (docs/ARCHITECTURE.md), checked first: it takes a moment.
    failures=subprocess.run([sys.executable,'tools/check_adapters.py'],cwd=ROOT).returncode!=0
    hotreload=None
    for label,args,env in targets(web):
        if env=='hotreload':
            import pins
            hotreload=hotreload or pins.hotreload_env() or os.environ
        result=subprocess.run(['haxe',*args,'--no-output'],cwd=ROOT,env=hotreload if env else None,capture_output=True,text=True, encoding='utf-8')
        ok=result.returncode==0
        print(('ok   ' if ok else 'FAIL ')+label,flush=True)
        if not ok:failures+=1;print('     '+result.stderr.strip().replace('\n','\n     ')[:4000])
    sys.exit(1 if failures else 0)

if __name__=='__main__':main()
