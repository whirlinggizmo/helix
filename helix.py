"""The front door for the checks: the tools, the libraries' tests, and the native tests. Python owns external tools; HXML owns Haxe
settings. The platform's examples and graphics tests on the GPU are tools/platform_checks.py's; type checks alone tools/check_types.py's."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import pins  # noqa: E402
pins.use_haxelib()
# Each library's tests, run with that library alone on the interpreter and Node, and with --native in hxcpp.
TESTS=(('helix-platform','PlatformTests'),('helix-log','LogTests'),*(('helix-math',m) for m in ('TrigTests','RandomTests','CurveTests','BoundsTests','VectorTests','MatrixTests','Matrix2DTests','Transform2DTests','Quaternion3DTests','Transform3DTests','InterpolateTests','Grid2DTests','ColorTests')),
      *(('helix-geometry',m) for m in ('GeometryTests','Camera2DTests','Frustum3DTests','Camera3DTests','Ray3DTests','Mesh3DTests','AnimationTests')),
      *(('helix-formats',m) for m in ('Utf8TextTests','GltfTests','ObjTests','BmFontTests','TrueTypeTests','DeflateTests','PngTests','QoiTests','QoaTests','GifTests','WavTests','AudioHeaderTests')),
      *(('helix-services',m) for m in ('ConfigTests','TimeTests','InputTests','GesturesTests','SavesTests','AssetsTests','AudioTests','ImagesTests','ImageTests','ModelsTests','FontsTests','ScreenTests','ShaderTests')),
      ('helix-render','RenderTests'))

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def result(args,**kw):
    """The JSON a test prints last, its passed asserted."""
    output=subprocess.check_output(args,cwd=ROOT,text=True,encoding='utf-8',**kw)
    value=json.loads(output[output.index('{'):]);assert value['passed'],output
    return value

def test(native,audio_device):
    """The adapter rule's check, the layers' check, the names' check (tools/check_names.py), the tools' check (tools/check_tools.py), the
    API reference's check (tools/gen_apidoc.py --check), the size ladder's check (tools/measure_sizes.py --check), the doc comments' check
    (tools/check_docs.py); each library's tests on the interpreter and Node, the shader compiler's on the interpreter, Trig's bits across
    targets, helix-raylib's tests on Node; and with native each library's tests, Trig's bits and helix-raylib's tests in hxcpp, and the
    platform's C tests (SDL3's dummy audio driver)."""
    run([sys.executable,'tools/check_adapters.py'])
    run([sys.executable,'tools/check_layers.py'])
    run([sys.executable,'tools/check_names.py'])
    run([sys.executable,'tools/check_tools.py'])
    run([sys.executable,'tools/gen_raylib.py','--check'])
    run([sys.executable,'tools/gen_apidoc.py','--check'])
    run([sys.executable,'tools/measure_sizes.py','--check'])
    run([sys.executable,'tools/check_docs.py'])
    (ROOT/'build/tests').mkdir(parents=True,exist_ok=True)
    if native:
        from pins import check_hxcpp
        from native_build import ARCH
        check_hxcpp()
    for library,main in TESTS:
        args=['haxe','-lib',library,'-cp',pins.LIBRARIES[library]/'tests','-main',main]
        value=result(args+['--interp'])
        run(args+['-js',f'build/tests/{main}.js','-dce','full'])
        result(['node',f'build/tests/{main}.js'])
        if native:
            run(args+['-cpp',f'build/tests/{main}-cpp','-dce','full','-D','analyzer-optimize','-D',ARCH])
            result([str(ROOT/'build/tests'/f'{main}-cpp'/(f'{main}.exe' if sys.platform=='win32' else main))])
        print(f'{main}: {value["checks"]} checks (interpreter, Node{" and hxcpp" if native else ""})',flush=True)
    # The shader compiler runs on the interpreter alone (it runs glslang and SPIRV-Cross, fetched or built into the cache the first time).
    value=result(['haxe','-lib','helix-platform','-cp',pins.LIBRARIES['helix-platform']/'tests','-main','ShaderCompilerTests','--interp'])
    print(f'ShaderCompilerTests: {value["checks"]} checks (interpreter)',flush=True)
    value=result(['haxe','-lib','helix-services','-cp',pins.LIBRARIES['helix-services']/'tests','-main','ManifestTests','--interp'])
    print(f'ManifestTests: {value["checks"]} checks (interpreter)',flush=True)
    trig(native)
    raylib_tests(native)
    if native:
        from native_build import tool
        print(subprocess.check_output([str(tool('native-sdl3mixer-audio-test'))],text=True,encoding='utf-8',env=dict(os.environ,SDL_AUDIO_DRIVER='dummy')),end='')
        print(subprocess.check_output([str(tool('native-sdl3-events-test'))],text=True,encoding='utf-8'),end='')
        if audio_device:print(subprocess.check_output([str(tool('native-sdl3mixer-device-probe'))],text=True,encoding='utf-8'),end='')

# helix-raylib's own tests, built as the parity harnesses are: from its source, without its program loop (tools/raylib_parity.py).
RAYLIB_TESTS=('CountTests','DropTests','AudioStreamTests','RefusalTests','AsyncTests','LoopTests','DeviceTests')

def raylib_tests(native):
    """helix-raylib's tests on Node, and with native in hxcpp: on graphics of their own, without a window."""
    base=[a for lib in ('helix-log','helix-math','helix-geometry','helix-formats','helix-platform','helix-services') for a in ('-lib',lib)]
    base+=['-cp','engines/raylib/src','--macro','helix.raylib.internal.Metadata.register()','-cp','engines/raylib/tests','-cp','libs/services/tests']
    for main in RAYLIB_TESTS:
        run(['haxe',*base,'-main',main,'-js',f'build/tests/{main}.js','-D','js-es=6'])
        value=result(['node',f'build/tests/{main}.js'])
        if native:
            import native_build,sdl3
            found=sdl3.find()
            run(['haxe',*base,'-main',main,'-cpp',f'build/tests/{main}-cpp','-D','analyzer-optimize','-D',native_build.ARCH],env=native_build.env(found))
            # helix-raylib links SDL3 (its runtime's adapters): on Windows its DLL goes beside the program, or the program doesn't start.
            native_build.place_runtimes(ROOT/'build/tests'/f'{main}-cpp',found)
            result([str(ROOT/'build/tests'/f'{main}-cpp'/(f'{main}.exe' if sys.platform=='win32' else main))])
        print(f'{main}: {value["checks"]} checks (Node{" and hxcpp" if native else ""})',flush=True)

def trig(native):
    """helix.math.Trig's bits over fixed inputs: the same hash under the interpreter, in JS (Node) and, with native, in hxcpp. When they
    differ, the parts' hashes say where."""
    def lines(args,**kw):return [l for l in subprocess.check_output(args,cwd=ROOT,text=True,encoding='utf-8',**kw).splitlines() if l.startswith('trig ')]
    base=['-lib','helix-math','-cp','libs/math/tests','-main','TrigBits']
    outputs={'interpreter':lines(['haxe',*base,'--interp'])}
    run(['haxe',*base,'-js','build/tests/trigbits.js','-dce','full','-D','analyzer-optimize'])
    outputs['js']=lines(['node','build/tests/trigbits.js'])
    if native:
        from pins import check_hxcpp
        from native_build import ARCH
        check_hxcpp()
        run(['haxe',*base,'-cpp','build/tests/trigbits-cpp','-dce','full','-D','analyzer-optimize','-D',ARCH],env={**os.environ,'HAXELIB_PATH':str(ROOT/'build/haxelib')})
        outputs['hxcpp']=lines([str(ROOT/'build/tests/trigbits-cpp'/('TrigBits.exe' if sys.platform=='win32' else 'TrigBits'))])
    hashes={target:out[0] for target,out in outputs.items()}
    if len(set(hashes.values()))!=1:
        for parts in zip(*outputs.values()):
            if len(set(parts))!=1:print('differs: '+'  '.join(f'{target}: {part}' for target,part in zip(outputs,parts)))
        sys.exit(f'helix.math.Trig differs between targets: {hashes}')
    print(f'Trig bits: the same on {", ".join(hashes)}: {next(iter(hashes.values()))}',flush=True)

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True,metavar='command')
    tests=sub.add_parser('test',help="Run the tools' checks and the libraries' tests; --native adds the libraries' tests in hxcpp and the platform's C tests");tests.add_argument('--native',action='store_true');tests.add_argument('--audio-device',action='store_true',help='with --native, probe the audio device too (makes no sound)')
    a=p.parse_args()
    if a.audio_device and not a.native:p.error('--audio-device requires --native')
    test(a.native,a.audio_device)

if __name__=='__main__':main()
