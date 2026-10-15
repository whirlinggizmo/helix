"""Examples: develop one under hotreload-hx, or build it for web or native; `all build TARGET` builds every example.

An example is examples/<name>/App.hx, or for a larger one examples/<name>/src/App.hx beside its own files. Every example shares the launchers
and page in examples/shared and the files in examples/assets. A larger example adds its autopilot/ scripts (served as assets/autopilot) and the
files its assets/generate.py makes. An example's shaders/*.glsl are packed (tools/pack_shader.py) into assets/shaders/*.hxshader, and in dev
packed again as they change, reloading in the page.

autopilot builds both targets and replays each of the example's autopilot scripts on both, with sound off: in a headless browser, and natively
in a window. On Linux the window is on a private display (tools/private_display.py); elsewhere it opens on the desktop, so run it there in a
logged-in session (tools/remote_windows.py --desktop). Both must publish the same final game."""
import argparse
from contextlib import nullcontext
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import urllib.request
from shader_metadata import generate,manifest
import pack_shader
import fontbake
from native_build import ARCH

ROOT=Path(__file__).resolve().parents[1]
GENERATED=ROOT/'build/generated/shaders'
SHADERS=ROOT/'src/helix/graphics/shaders'
SHARED=ROOT/'examples/shared'

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def shader_stamp():
    """The newest change to the framework's shader sources, their manifest, and the tool writing their generated code."""
    return max([p.stat().st_mtime for p in SHADERS.iterdir() if p.suffix in ('.glsl','.json')]+[(ROOT/'tools/shader_metadata.py').stat().st_mtime])

def shader():
    """Generate the framework's shaders (src/helix/graphics/shaders, listed in shaders.json) when a source is newer than the output."""
    GENERATED.mkdir(parents=True,exist_ok=True)
    output=GENERATED/'shader-contract.json'
    if output.is_file() and output.stat().st_mtime>=shader_stamp():return
    import shdc as compiler
    shdc=compiler.path()
    for spec in manifest(SHADERS/'shaders.json'):
        program=spec['program'];source=SHADERS/f'{program}.glsl'
        run([shdc,'-i',source,'-o',GENERATED/program,'-l','glsl410:glsl300es','-f','bare_yaml','--no-log-cmdline'])
    generate(SHADERS/'shaders.json',GENERATED,ROOT)

def source(name):
    """The example's source folder: examples/<name>/src for a larger example, else examples/<name>."""
    return f'examples/{name}/src' if (ROOT/f'examples/{name}/src/App.hx').is_file() else f'examples/{name}'

def hxml(name,target):
    """The example's build arguments, written where the dev server and haxe read them."""
    launch='browser-webgl2' if target=='web' else 'native-sokol-gl'
    lines=['-cp src',f'-cp {source(name)}',f'-cp examples/shared/launch/{launch}','-cp examples/shared/src','-cp build/generated/shaders','-cp build/generated/fonts','-main Main',f'-D example={name}','-dce full','-D analyzer-optimize']
    lines+=[f'-js build/web/{name}/app.js'] if target=='web' else [f'-cpp build/native/{name}',f'-D {ARCH}','-D HXCPP_COMPILE_THREADS=4']
    path=ROOT/f'build/examples/{name}-{target}.hxml';path.parent.mkdir(parents=True,exist_ok=True);path.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    return path.relative_to(ROOT)

def prepare(name):
    """The generated shader and font, and the served folder: the page and the shared files."""
    shader();fontbake.generate()
    web=ROOT/f'build/web/{name}';web.mkdir(parents=True,exist_ok=True)
    (web/'index.html').write_text((SHARED/'index.html').read_text(encoding='utf-8').replace('{{name}}',name))
    shutil.copyfile(SHARED/'favicon.png',web/'favicon.png')
    if (web/'assets').is_symlink():(web/'assets').unlink()
    assets(name,web/'assets')
    licenses(web)

def assets(name,out):
    """The shared files, then the example's own: its autopilot scripts and what its assets/generate.py makes."""
    if out.exists():shutil.rmtree(out)
    shutil.copytree(ROOT/'examples/assets',out)
    pilots=ROOT/f'examples/{name}/autopilot'
    if pilots.is_dir():shutil.copytree(pilots,out/'autopilot')
    recipe=ROOT/f'examples/{name}/assets/generate.py'
    if recipe.is_file():
        import importlib.util
        spec=importlib.util.spec_from_file_location(f'{name}_assets',recipe);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        shutil.copytree(module.generate(),out,dirs_exist_ok=True)
    pack_shaders(name,out)

def pack_shaders(name,out,since=0):
    """The example's shaders/*.glsl packed into out/shaders/*.hxshader: those changed since `since` (a time), all by default. Returns the newest
    source's time."""
    newest=since
    for source in sorted((ROOT/f'examples/{name}/shaders').glob('*.glsl')):
        stamp=source.stat().st_mtime;newest=max(newest,stamp)
        if stamp>since:pack_shader.pack(pack_shader.shdc_path(),source,out/'shaders'/(source.stem+'.hxshader'))
    return newest

def licenses(out):
    """HeliX's license, the third-party notices and the license texts they name, which go with every build (THIRD_PARTY_NOTICES.md)."""
    target=out/'licenses'
    if target.exists():shutil.rmtree(target)
    target.mkdir(parents=True)
    shutil.copyfile(ROOT/'THIRD_PARTY_NOTICES.md',target/'THIRD_PARTY_NOTICES.md')
    for name,source in [('HeliX-MIT.txt','LICENSE'),('sokol-zlib.txt','vendor/LICENSE'),('sokol_utils-zlib.txt','vendor/sokol_utils/LICENSE'),('JetBrainsMono-OFL.txt','vendor/fonts/JetBrainsMono/OFL.txt'),('libsndfile-LGPL-2.1.txt','vendor/sndfile/COPYING')]:
        shutil.copyfile(ROOT/source,target/name)

def build(name,target):
    """Builds the example for target ('web' or 'native') into build/<target>/<name>."""
    prepare(name)
    if target=='web':
        run(['haxe',hxml(name,'web')])
        terser=ROOT/'build/tools/node_modules/terser/bin/terser';js=ROOT/f'build/web/{name}/app.js'
        if terser.is_file():run(['node',terser,js,'--compress','--mangle','--output',js])
    else:
        from pins import check_hxcpp,check_sokol
        from native_build import codec_runtime,env as native_env
        check_hxcpp();check_sokol(ROOT);env=native_env()
        run(['haxe',hxml(name,'native')],env)
        # On Windows, the libsndfile the program loads goes beside it.
        runtime=codec_runtime()
        if runtime:shutil.copy2(runtime,ROOT/f'build/native/{name}')
        out=ROOT/f'build/native/{name}/assets'
        assets(name,out)
        licenses(out.parent)

def autopilot(name,browser):
    """Replays every examples/<name>/autopilot script on both targets; returns the scripts whose final games differ or that failed."""
    import functools,http.server,threading
    if sys.platform.startswith('linux'):from private_display import private_display
    scripts=sorted(p.name for p in (ROOT/f'examples/{name}/autopilot').glob('*.json'))
    if not scripts:sys.exit(f'examples/{name}/autopilot has no scripts')
    for target in ('web','native'):build(name,target)
    out=ROOT/f'build/results/{name}';out.mkdir(parents=True,exist_ok=True)
    class Quiet(http.server.SimpleHTTPRequestHandler):
        def log_message(self,*args):pass
    handler=functools.partial(Quiet,directory=str(ROOT/f'build/web/{name}'))
    server=http.server.ThreadingHTTPServer(('127.0.0.1',0),handler);threading.Thread(target=server.serve_forever,daemon=True).start()
    failed=[];program=ROOT/f'build/native/{name}'/('Main.exe' if os.name=='nt' else 'Main')
    try:
        with private_display() if sys.platform.startswith('linux') else nullcontext(dict(os.environ)) as env:
            for script in scripts:
                options={'autopilot':f'autopilot/{script}','autoclose':'1','audio':'0','fast':'1'}
                query='&'.join(f'{k}={v}' for k,v in options.items())
                web=json.loads(subprocess.check_output(['node',ROOT/'tools/autopilot.cjs',browser,f'http://127.0.0.1:{server.server_address[1]}/?{query}'],cwd=ROOT,text=True, encoding='utf-8'))
                result=out/f'native-{script}';result.unlink(missing_ok=True)
                child=dict(env,HELIX_RESULT=str(result),**{'HELIX_'+k.upper():v for k,v in options.items()})
                process=subprocess.run([str(program)],cwd=ROOT/f'build/native/{name}',env=child,capture_output=True,text=True, encoding='utf-8',timeout=300)
                if process.returncode or not result.is_file():failed.append(script);print(f'{script}: native run failed\n{process.stdout}{process.stderr}',flush=True);continue
                native=json.loads(result.read_text(encoding='utf-8'));same=web['result']['game']==native['game'] and not web['errors']
                (out/f'autopilot-{script}').write_text(json.dumps({'script':script,'sameGame':same,'browserErrors':web['errors'],'browser':web['result'],'native':native},indent=2)+'\n', encoding='utf-8')
                print(f'{script}: same final game on both targets: {same}',flush=True)
                if not same:failed.append(script)
    finally:server.shutdown()
    return failed

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('name');p.add_argument('action',choices=['dev','build','autopilot']);p.add_argument('target',nargs='?',choices=['web','native'],default='web')
    p.add_argument('--port',type=int,default=8060);p.add_argument('--browser',help='Chromium for autopilot');a=p.parse_args()
    if a.name=='all':
        if a.action!='build':p.error('all only builds')
        names=sorted(d.name for d in (ROOT/'examples').iterdir() if (ROOT/source(d.name)/'App.hx').is_file())
        failed=[]
        for name in names:
            try:build(name,a.target)
            except subprocess.CalledProcessError:failed.append(name)
        print(f'built {len(names)-len(failed)} of {len(names)} examples for {a.target}',flush=True)
        if failed:sys.exit('Failed: '+', '.join(failed))
        return
    if not (ROOT/source(a.name)/'App.hx').is_file():sys.exit(f'No examples/{a.name}/App.hx or examples/{a.name}/src/App.hx')
    if a.action=='autopilot':
        if not a.browser:p.error('autopilot needs --browser')
        failed=autopilot(a.name,a.browser)
        if failed:sys.exit('Autopilot outcomes differ: '+', '.join(failed)+f'; see build/results/{a.name}')
        return
    if a.action=='dev':
        prepare(a.name)
        # The edit loop: hotreload-hx rebuilds on save and swaps code and served files into the running page.
        # The dev server watches Haxe source; shader source is regenerated here, and the new layouts (Sprite2DLayout.hx and the rest) reload like any Haxe edit.
        server=subprocess.Popen(['haxe','-lib','hotreload-hx','--run','hotreload.DevServer','--port',str(a.port),hxml(a.name,'web')],cwd=ROOT)
        print(f'Open http://localhost:{a.port}/ and edit; Ctrl+C stops.',flush=True)
        try:
            failed=None;packed=time.time()
            while server.poll() is None:
                # The example's shaders, packed again as they change; the page reloads the asset.
                try:packed=pack_shaders(a.name,ROOT/f'build/web/{a.name}/assets',packed)
                except SystemExit as error:print('example: shader packing failed:',error,flush=True);packed=time.time()
                # A failed source is retried only once it changes again.
                stamp=shader_stamp()
                if stamp!=failed:
                    try:shader();failed=None
                    except (subprocess.CalledProcessError,RuntimeError) as error:print('example: shader generation failed:',error,flush=True);failed=stamp
                time.sleep(.25)
        except KeyboardInterrupt:pass
        finally:
            try:urllib.request.urlopen(f'http://127.0.0.1:{a.port}/__hotreload_stop',timeout=5).read();server.wait(timeout=10)
            except Exception:server.terminate()
        return
    build(a.name,a.target)

if __name__=='__main__':main()
