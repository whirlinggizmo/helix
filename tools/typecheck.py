"""Type-check every Haxe entry point for the browser and native targets without building anything (haxe --no-output).

For refactors: an API change is done when this passes, then the checks that run code. Takes seconds, no C++ compile."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
GENERATED={'asteroids':'build/generated/asteroids','blocks':'build/generated/blocks','sprite2d':'build/generated/sprite2d'}

def targets():
    """(label, haxe arguments) for each entry point and target."""
    found=[]
    for name in ('asteroids','blocks'):
        for target in ('web','native'):found.append((f'{name} {target}',[f'examples/{name}/{target}.hxml']))
    for target in ('web','native'):found.append((f'mixed-submission {target}',[f'benchmarks/mixed-submission/{target}.hxml']))
    for example in sorted(p.parent.name for p in (ROOT/'examples').glob('*/App.hx')):
        for target,launch in (('web','browser-webgl2'),('native','native-sokol-gl')):
            found.append((f'{example} {target}',['-cp','src','-cp',f'examples/{example}','-cp',f'examples/shared/launch/{launch}','-cp',GENERATED['sprite2d'],'-main','Main','-D',f'example={example}']+(['-js','build/typecheck.js'] if target=='web' else ['-cpp','build/typecheck-cpp'])))
    parity=['-cp','src','-cp','examples/asteroids-parity/src','-cp','examples/asteroids-parity/game','-cp',GENERATED['asteroids']]
    found.append(('asteroids-parity web',parity+['-cp','examples/asteroids-parity/launch/browser-webgl2','-main','Launch','-js','build/typecheck.js']))
    found.append(('asteroids-parity native',parity+['-cp','examples/asteroids-parity/launch/native-sokol-gl','-main','Launch','-cpp','build/typecheck-cpp']))
    for main,cp in (('SimulationTests',['examples/asteroids/src']),('BlocksTests',['examples/blocks/src']),('InputTests',[])):
        found.append((f'unit {main}',['-cp','src','-cp','tests/unit']+sum((['-cp',c] for c in cp),[])+['-main',main,'--interp']))
    found.append(('package smoke',['-cp','src','-cp','tests/consumer','-main','PackageSmoke','--interp']))
    found.append(('services web',['-cp','src','-cp','tests/services','-cp','tests/services/web','-main','ServiceTests','-js','build/typecheck.js']))
    found.append(('services native',['-cp','src','-cp','tests/services','-cp','tests/services/native','-main','ServiceTests','-cpp','build/typecheck-cpp']))
    return found

def main():
    failures=0
    for label,args in targets():
        result=subprocess.run(['haxe',*args,'--no-output'],cwd=ROOT,capture_output=True,text=True)
        ok=result.returncode==0
        print(('ok   ' if ok else 'FAIL ')+label,flush=True)
        if not ok:failures+=1;print('     '+result.stderr.strip().replace('\n','\n     ')[:4000])
    sys.exit(1 if failures else 0)

if __name__=='__main__':main()
