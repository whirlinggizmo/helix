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
      *(('helix-services',m) for m in ('ConfigTests','TimeTests','InputTests','VirtualGamepadTests','GesturesTests','SavesTests','AssetsTests','AudioTests','ImagesTests','ImageTests','ModelsTests','FontsTests','ScreenTests','ShaderTests')),
      ('helix-render','RenderTests'))

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def result(args,**kw):
    """The JSON a test prints last, its passed asserted."""
    done=subprocess.run(args,cwd=ROOT,stdout=subprocess.PIPE,text=True,encoding='utf-8',**kw);output=done.stdout
    # A test that dies prints its error where its JSON would be, so it's shown before the failure.
    if done.returncode:sys.exit(f'{output}\n{args[0]} exited {done.returncode}')
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
        args=['haxe','-lib',library,'-cp',pins.LIBRARIES[library]/'tests','-main',main,*named(main)]
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
RAYLIB_TESTS=('CountTests','DropTests','AudioStreamTests','RefusalTests','AsyncTests','SkinningTests','RestoreTests','ShaderFileTests','StructTests','TouchTests','SysTests','ModelMergeTests','PbrTests','VirtualGamepadExtraTests','DeviceTests','DebugTests','GuiSkinsTests','SpritesTests','WaitTests')
# The tests' shaders (engines/raylib/tests/shaders): each compiled ahead of time as a program's is (CompileShaderFile), into
# build/tests, and embedded in every test as a resource of its file's name.
TEST_SHADERS=[('glow.vs','glow.fs','glow.shader'),('glow.vs','emissive.fs','emissive.shader'),('own_skinning.vs',None,'own_skinning.shader'),('own_lights.vs','own_lights.fs','own_lights.shader')]

def named(product):
    """The defines naming a test program, which every program sets: the company and the product."""
    return ['-D','helix-company=helix','-D',f'helix-product={product}']

# What each program in engines/raylib/tests/refused must be refused with, each the start of a refusal's message or a compiler error.
# The refused programs calling Haxe's own Sys and sys package, refused only with -D helix-raylib-portable-sys.
PORTABLE_SYS={'FileCalls'}
REFUSED={'FileCalls':('sys.io.File.getContent: Use LoadFileText(fileName:String):Null<String> instead.',
    'sys.io.File.saveContent: Use SaveFileText(fileName:String, text:String):Bool instead.','sys.io.File.getBytes: Use LoadFileData(',
    'sys.io.File.saveBytes: Use SaveFileData(','sys.FileSystem.exists: Use FileExists(fileName:String):Bool instead.',
    'sys.FileSystem.readDirectory: Use LoadDirectoryFiles(','sys.io.Process: Not supported.'),
    'ShaderCalls':('LoadShader: Not supported. Use LoadCompiledShader(compiledShaderFileName:String):Shader instead. It loads a shader precompiled by the CompileShaderFile(vsFileName:Null<String>, fsFileName:Null<String>, compiledShaderFileName:String) macro',
    'LoadShaderFromMemory: Not supported. Use LoadCompiledShader(','or LoadCompiledShaderFromData(compiledShaderData:haxe.io.Bytes) for its bytes',
    'ShaderCalls.hx:11:','CompileShaderFile: A macro that writes the compiled shader to compiledShaderFileName, and gives the program nothing. Load that file with LoadCompiledShader('),
    'GuessedCalls':('GuessedCalls.hx:9: characters 3-19 : TakeScreenshot: Not supported. Use TakeScreenshotAsync(','GuessedCalls.hx:10: characters 3-29 : TakeScreenshot: Not supported.',
    'GuessedCalls.hx:11: characters 16-42 : LoadImageFromTexture: Not supported. Use LoadImageFromTextureAsync(','GuessedCalls.hx:12: characters 16-37 : LoadShader: Not supported. Use LoadCompiledShader(',
    'GuessedCalls.hx:13: characters 15-40 : GetMonitorPhysicalWidth: A monitor','GuessedCalls.hx:14: characters 3-26 : TextCopy: A String can\'t be written into'),
    'WaitCalls':("WaitCalls.hx:10: characters 21-45 : LoadFileText: Not supported in a constructor or a variable's initial value.",
    "WaitCalls.hx:39: characters 11-32 : LoadModel: Not supported in a constructor or a variable's initial value.",
    'WaitCalls.hx:19: characters 19-31 : EndDrawing: Not supported in a function used as a value.',
    'WaitCalls.hx:20: characters 31-48 : LoadTexture: Not supported in a function used as a value.',
    'WaitCalls.hx:21: characters 44-74 : SaveFileText: Not supported in a function used as a value.',
    'WaitCalls.hx:22: characters 21-28 : frame(): Not supported in a function used as a value.',
    'WaitCalls.hx:23: characters 15-20 : frame: Not supported as a value.',
    'WaitCalls.hx:42: lines 42-45 : show(): Not supported in interface WaitShown.',
    'WaitCalls.hx:61: lines 61-63 : update(): Not supported as an override of WaitBase.update.',
    'WaitCalls.hx:75: characters 22-33 : tick(): Not supported in a function used as a value.',
    'WaitCalls.hx:84: characters 4-16 : EndDrawing: Not supported in a function used as a value.')}

def refused(base):
    """Each program in engines/raylib/tests/refused refused for JS and natively (typed alone), each of its refusals in the compiler's
    errors, those of PORTABLE_SYS (Haxe's own calls) with -D helix-raylib-portable-sys and the rest (raylib's calls) without it; FileCalls typed natively without the define, Haxe's own calls; PageSys for JS without it,
    Haxe's error for its Sys call; and AsyncTests typed natively
    with it, with the libraries' own sys.io.File calls in it (the native saves), which aren't refused."""
    for main,messages in REFUSED.items():
        # Haxe's own calls are refused only with the define; helix-raylib's raylib calls are refused with or without it.
        define=['-D','helix-raylib-portable-sys'] if main in PORTABLE_SYS else []
        for target in (['-js',f'build/tests/{main}.js',*define],['-cpp',f'build/tests/{main}-cpp',*define]):
            done=subprocess.run(['haxe',*base,*named(main),'-cp','engines/raylib/tests/refused','-main',main,*target,'--no-output'],
                cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
            missing=[m for m in messages if m not in done.stderr]
            if done.returncode==0 or missing:sys.exit(f'{main} ({target[0]}): built, or refusals missing: {missing}\n{done.stderr}')
        print(f'{main}: {len(messages)} refusals (JS and native{", -D helix-raylib-portable-sys" if define else ", no define"})',flush=True)
    run(['haxe',*base,*named('FileCalls'),'-cp','engines/raylib/tests/refused','-main','FileCalls','-cpp','build/tests/FileCalls-cpp','--no-output'])
    print('FileCalls: Haxe\'s own natively without the define',flush=True)
    # Without the define a page has no Sys of the library's, so Sys is Haxe's error for JS.
    done=subprocess.run(['haxe',*base,*named('PageSys'),'-cp','engines/raylib/tests/refused','-main','PageSys','-js','build/tests/PageSys.js','--no-output'],
        cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    if done.returncode==0 or 'requires a system platform' not in done.stderr:sys.exit(f'PageSys (-js): built, or not Haxe\'s error\n{done.stderr}')
    print('PageSys: no Sys in a page without the define',flush=True)
    run(['haxe',*base,*named('AsyncTests'),'-main','AsyncTests','-cpp','build/tests/AsyncTests-typed','--no-output','-D','helix-raylib-portable-sys'])

def raylib_tests(native):
    """helix-raylib's tests on Node, and with native in hxcpp: on graphics of their own, without a window."""
    base=[a for lib in ('helix-log','helix-math','helix-geometry','helix-formats','helix-platform','helix-services') for a in ('-lib',lib)]
    base+=['-cp','engines/raylib/src','--macro','helix.raylib.internal.Metadata.register()','--macro','helix.raylib.internal.SysCalls.register()','-cp','engines/raylib/tests','-cp','libs/services/tests']
    def path(name,folder):return 'null' if name is None else json.dumps(f'{folder}/{name}')
    run(['haxe',*base,*[a for vs,fs,out in TEST_SHADERS for a in ('--macro',f'helix.raylib.Raylib.CompileShaderFile({path(vs,"engines/raylib/tests/shaders")}, {path(fs,"engines/raylib/tests/shaders")}, {path(out,"build/tests")})')]])
    extra=[a for _,_,out in TEST_SHADERS for a in ('-resource',f'build/tests/{out}@{out}')]
    refused(base)
    for main in RAYLIB_TESTS:
        run(['haxe',*base,*extra,*named(main),'-main',main,'-js',f'build/tests/{main}.js','-D','js-es=6','-D','helix-raylib-portable-sys'])
        value=result(['node',f'build/tests/{main}.js'])
        if native:
            import native_build,sdl3
            found=sdl3.find()
            run(['haxe',*base,*extra,*named(main),'-main',main,'-cpp',f'build/tests/{main}-cpp','-D','analyzer-optimize','-D',native_build.ARCH,'-D','helix-raylib-portable-sys'],env=native_build.env(found))
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
