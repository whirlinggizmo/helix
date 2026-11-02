"""Type-check every Haxe entry point of every library on the targets it supports, without building anything (haxe --no-output).

For refactors: an API change is done when this passes, then the checks that run code. Takes seconds, no C++ compile. Each library's
tests on the interpreter; the platform's examples, graphics and audio tests and size ladder for the browser and (unless --web) native, with the
library alone, as their own hxml files build them. The adapter rule and the layers are checked first."""
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import pins  # noqa: E402
pins.use_haxelib()

def targets(web=False):
    """(label, haxe arguments) for each entry point and target; with web, the browser's alone."""
    found=[]
    for main in ('PlatformTests','ShaderCompilerTests'):found.append((f'platform {main}',['-lib','helix-platform','-cp','platform/tests','-main',main,'--interp']))
    found.append(('log LogTests',['-lib','helix-log','-cp','log/tests','-main','LogTests','--interp']))
    for main in ('TrigTests','RandomTests','CurveTests','BoundsTests','VectorTests','TrigBits'):found.append((f'math {main}',['-lib','helix-math','-cp','math/tests','-main',main,'--interp']))
    for main in ('GltfTests','ObjTests','BmFontTests','TrueTypeTests'):found.append((f'formats {main}',['-lib','helix-formats','-cp','formats/tests','-main',main,'--interp']))
    # Each platform example and the graphics and audio tests, with the library alone, on both targets (their own hxml files build them:
    # tools/platform_checks.py).
    for directory,main in [(p.parent,'Main') for p in sorted((ROOT/'platform/examples').glob('*/Main.hx'))]+[(ROOT/'platform/tests/graphics','GraphicsTests'),(ROOT/'platform/tests/audio','AudioTests')]:
        name=f'platform example {directory.name}' if main=='Main' else f'platform {directory.name} tests'
        found.append((f'{name} js',['-lib','helix-platform','-cp',str(directory.relative_to(ROOT)),'-main',main,'-js','build/check_types.js']))
        if not web:found.append((f'{name} cpp',['-lib','helix-platform','-cp',str(directory.relative_to(ROOT)),'-main',main,'-cpp','build/check_types-cpp']))
    # helix-render whole, on both targets; its tests on the interpreter; its examples as their own hxml files build them.
    found.append(('render js',['-lib','helix-render','--macro',"include('helix.render')",'-js','build/check_types.js']))
    if not web:found.append(('render cpp',['-lib','helix-render','--macro',"include('helix.render')",'-cpp','build/check_types-cpp']))
    for main in sorted(p.stem for p in (ROOT/'render/tests').glob('*Tests.hx')):found.append((f'render {main}',['-lib','helix-render','-cp','render/tests','-main',main,'--interp']))
    found.append(('render pixel tests js',['-lib','helix-render','-cp','render/tests/pixels','-main','PixelTests','-js','build/check_types.js']))
    if not web:found.append(('render pixel tests cpp',['-lib','helix-render','-cp','render/tests/pixels','-main','PixelTests','-cpp','build/check_types-cpp']))
    for directory in sorted(p.parent for p in (ROOT/'render/examples').glob('*/Main.hx')):
        found.append((f'render example {directory.name} js',['-lib','helix-render','-cp',str(directory.relative_to(ROOT)),'-main','Main','-js','build/check_types.js']))
        if not web:found.append((f'render example {directory.name} cpp',['-lib','helix-render','-cp',str(directory.relative_to(ROOT)),'-main','Main','-cpp','build/check_types-cpp']))
    # The size ladder's rungs, the browser's (tools/measure_sizes.py builds them so).
    for library in ('platform','services','render'):
        for rung in sorted((ROOT/library/'tests/sizes').glob('*/Main.hx')):
            found.append((f'{library} size {rung.parent.name}',['-lib',f'helix-{library}','-cp',str(rung.parent.relative_to(ROOT)),'-main','Main','-js','build/check_types.js']))
    return found

def main():
    import argparse
    parser=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--web',action='store_true',help="the browser's alone: no native target")
    parser.add_argument('--no-output',action='store_true',help='accepted for the habit: nothing is ever built (haxe --no-output)')
    web=parser.parse_args().web
    # The adapter rule and the layers, checked first.
    failures=subprocess.run([sys.executable,'tools/check_adapters.py'],cwd=ROOT).returncode!=0
    failures+=subprocess.run([sys.executable,'tools/check_layers.py'],cwd=ROOT).returncode!=0
    for label,args in targets(web):
        result=subprocess.run(['haxe',*args,'--no-output'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
        ok=result.returncode==0
        print(('ok   ' if ok else 'FAIL ')+label,flush=True)
        if not ok:failures+=1;print('     '+result.stderr.strip().replace('\n','\n     ')[:4000])
    sys.exit(1 if failures else 0)

if __name__=='__main__':main()
