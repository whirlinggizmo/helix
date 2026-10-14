"""Type-check every Haxe entry point for the browser and native targets without building anything (haxe --no-output).

For refactors: an API change is done when this passes, then the checks that run code. Takes seconds, no C++ compile.
Generated shader code missing from a fresh checkout is made first, with --shdc or SOKOL_SHDC."""
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
GENERATED={'shaders':'build/generated/shaders','fonts':'build/generated/fonts'}

def targets():
    """(label, haxe arguments) for each entry point and target."""
    from example import source
    found=[]
    for example in sorted({p.parent.name for p in (ROOT/'examples').glob('*/App.hx')}|{p.parent.parent.name for p in (ROOT/'examples').glob('*/src/App.hx')}):
        for target,launch in (('web','browser-webgl2'),('native','native-sokol-gl')):
            found.append((f'{example} {target}',['-cp','src','-cp',source(example),'-cp',f'examples/shared/launch/{launch}','-cp',GENERATED['shaders'],'-cp',GENERATED['fonts'],'-main','Main','-D',f'example={example}']+(['-js','build/typecheck.js'] if target=='web' else ['-cpp','build/typecheck-cpp'])))
    for main,cp in (('SimulationTests',['examples/asteroids/src']),('BlocksTests',['examples/blocks/src']),('InputTests',[]),('HostTests',[]),('AssetTests',[]),('Render2DTests',[GENERATED['shaders'],GENERATED['fonts']]),('ParticleTests',[GENERATED['shaders'],GENERATED['fonts']]),('Render3DTests',[GENERATED['shaders'],GENERATED['fonts']]),('EnvironmentTests',[]),('TrigTests',[])):
        found.append((f'unit {main}',['-cp','src','-cp','tests/unit']+sum((['-cp',c] for c in cp),[])+['-main',main,'--interp']))
    found.append(('trig bits',['-cp','src','-cp','tests/trig','-main','TrigBits','--interp']))
    found.append(('package smoke',['-cp','src','-cp','tests/consumer','-main','PackageSmoke','--interp']))
    found.append(('services web',['-cp','src','-cp','tests/services','-cp','tests/services/web','-main','ServiceTests','-js','build/typecheck.js']))
    found.append(('services native',['-cp','src','-cp','tests/services','-cp','tests/services/native','-main','ServiceTests','-cpp','build/typecheck-cpp']))
    return found

def generate():
    """The generated font, and the shaders' generated code when it's missing or older than its source."""
    import example,fontbake
    fontbake.generate()
    shdc=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--shdc=')),None) or os.environ.get('SOKOL_SHDC')
    example.shader(shdc)

def main():
    generate()
    # The adapter rule (docs/ARCHITECTURE.md), checked first: it takes a moment.
    failures=subprocess.run([sys.executable,'tools/adaptercheck.py'],cwd=ROOT).returncode!=0
    for label,args in targets():
        result=subprocess.run(['haxe',*args,'--no-output'],cwd=ROOT,capture_output=True,text=True)
        ok=result.returncode==0
        print(('ok   ' if ok else 'FAIL ')+label,flush=True)
        if not ok:failures+=1;print('     '+result.stderr.strip().replace('\n','\n     ')[:4000])
    sys.exit(1 if failures else 0)

if __name__=='__main__':main()
