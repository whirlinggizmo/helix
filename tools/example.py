"""Examples: develop one under hotreload-hx, or build it for web or native; `all build TARGET` builds every example (`--group I/N`, a share
of them).

An example is examples/<name>/App.hx, or for a larger one examples/<name>/src/App.hx beside its own files. Every example shares the launchers
and page in examples/shared. Each target's examples share one assets folder beside them, build/<target>/assets, which each loads as ../assets:
the files in examples/assets, and each example's own, which may not claim a path the shared files or another example has. A larger example
adds its autopilot/ scripts (as autopilot/<name>/) and its own assets/ folder (a gen_*.py there makes what's missing first); the web target's folder carries manifests (tools/gen_manifest.py), which the
page's asset cache follows. An example's shaders/*.glsl are packed
(tools/pack_shader.py) into shaders/*.hxshader, and in dev packed again as they change, reloading in the page.

autopilot builds both targets and replays each of the example's autopilot scripts on both, with sound off: in a headless browser, and natively
in a window. On Linux the window is on a private display (tools/private_display.py); elsewhere it opens on the desktop, so run it there in a
logged-in session (tools/remote_windows.py --desktop). Both must publish the same final game, and the same samples of the frame (the
autopilot's sample: each point's color within the sample's tolerance per channel, 3 unless the script says, on both targets)."""
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
from shader_metadata import generate,generate_sdl_gpu,manifest
import pack_shader
import gen_manifest
import bake_fonts
from native_build import ARCH

ROOT=Path(__file__).resolve().parents[1]
GENERATED=ROOT/'build/generated/shaders'
# SDL_GPU's dialects of the framework's programs, made only for SDL_GPU builds (tools/gpu_shaders.py), so no other build needs its tools.
GENERATED_SDL_GPU=ROOT/'build/generated/shaders-sdlgpu'
SHADERS=ROOT/'src/helix/graphics/shaders'
SHARED=ROOT/'examples/shared'

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def shader_stamp():
    """The newest change to the framework's shader sources, their manifest, and the tool writing their generated code."""
    return max([p.stat().st_mtime for p in SHADERS.iterdir() if p.suffix in ('.glsl','.json')]+[(ROOT/'tools/shader_metadata.py').stat().st_mtime])

def shader(sdl_gpu=False):
    """Generate the framework's shaders (src/helix/graphics/shaders, listed in shaders.json) when a source is newer than the output, and pack
    the shader library (src/helix/shaders) into generated Haxe beside them (tools/pack_shader.py's pack_library); with sdl_gpu, their SDL_GPU
    dialects too (build/generated/shaders-sdlgpu)."""
    GENERATED.mkdir(parents=True,exist_ok=True)
    pack_shader.pack_library(GENERATED,GENERATED_SDL_GPU if sdl_gpu else None)
    output=GENERATED/'shader-contract.json'
    if not output.is_file() or output.stat().st_mtime<shader_stamp():
        import shdc as compiler
        shdc=compiler.path()
        for spec in manifest(SHADERS/'shaders.json'):
            program=spec['program'];source=SHADERS/f'{program}.glsl'
            run([shdc,'-i',source,'-o',GENERATED/program,'-l','glsl410:glsl300es','-f','bare_yaml','--no-log-cmdline'])
        generate(SHADERS/'shaders.json',GENERATED,ROOT)
    if sdl_gpu:
        import gpu_shaders
        stamp=GENERATED_SDL_GPU/'stamp'
        if not stamp.is_file() or stamp.stat().st_mtime<max(output.stat().st_mtime,gpu_shaders.tool_stamp()):
            generate_sdl_gpu(SHADERS/'shaders.json',GENERATED,GENERATED_SDL_GPU);stamp.write_text('',encoding='utf-8')

def source(name):
    """The example's source folder: examples/<name>/src for a larger example, else examples/<name>."""
    return f'examples/{name}/src' if (ROOT/f'examples/{name}/src/App.hx').is_file() else f'examples/{name}'

def hxml(name,target):
    """The example's build arguments, written where the dev server and haxe read them."""
    launch={'web':'browser-webgl2','native':'native-sokol-gl','native-sdl3':'native-sdl3-gl','native-sdl3-gpu':'native-sdl3-gpu'}[target]
    lines=['-cp src',f'-cp {source(name)}',f'-cp examples/shared/launch/{launch}','-cp examples/shared/src','-cp build/generated/shaders','-cp build/generated/fonts','-main Main',f'-D example={name}','-dce full','-D analyzer-optimize']
    lines+=[f'-js build/web/{name}/app.js'] if target=='web' else [f'-cpp build/{target}/{name}',f'-D {ARCH}','-D HXCPP_COMPILE_THREADS=4']
    # SDL_GPU's programs carry its dialects, which other builds leave out.
    if target=='native-sdl3-gpu':lines+=['-D helix_sdl3_gpu',f'-cp {GENERATED_SDL_GPU.relative_to(ROOT).as_posix()}']
    path=ROOT/f'build/examples/{name}-{target}.hxml';path.parent.mkdir(parents=True,exist_ok=True);path.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    return path.relative_to(ROOT)

def prepare(name):
    """The generated shader and font, and the served folder: the page, and the example's files in the web target's shared assets."""
    shader();bake_fonts.generate()
    web=ROOT/f'build/web/{name}';web.mkdir(parents=True,exist_ok=True)
    # The example's config.json (DECISIONS 131) beside the page, and the page told it has one; none, and the page makes no request.
    config=ROOT/f'examples/{name}/config.json';meta='<meta name="helix-config" content="config.json">' if config.is_file() else ''
    (web/'index.html').write_text((SHARED/'index.html').read_text(encoding='utf-8').replace('{{name}}',name).replace('{{config}}',meta))
    if config.is_file():shutil.copyfile(config,web/'config.json')
    elif (web/'config.json').exists():(web/'config.json').unlink()
    shutil.copyfile(SHARED/'favicon.png',web/'favicon.png')
    assets(name,'web')
    licenses(web)

def assets(name,target):
    """build/<target>/assets, which the target's examples share: the shared files, then the example's own (its autopilot scripts as
    autopilot/<name>/, its own assets/ folder (a gen_*.py there first) and its shaders, with SDL_GPU's dialects for native-sdl3-gpu). The example's own
    files may not claim a path the shared files or another example has. A copy of its own left from before (build/<target>/<name>/assets)
    is removed."""
    out=ROOT/f'build/{target}/assets'
    old=ROOT/f'build/{target}/{name}/assets'
    if old.is_symlink():old.unlink()
    elif old.exists():shutil.rmtree(old)
    shutil.copytree(ROOT/'examples/assets',out,dirs_exist_ok=True)
    pilots=ROOT/f'examples/{name}/autopilot'
    if (out/'autopilot'/name).exists():shutil.rmtree(out/'autopilot'/name)
    if pilots.is_dir():shutil.copytree(pilots,out/'autopilot'/name)
    # The example's own assets (examples/<name>/assets), copied in over the shared ones: a gen_*.py beside them makes what's missing first
    # (Asteroids' sounds are committed, so it makes nothing unless one is gone); the recipes themselves aren't assets.
    own=ROOT/f'examples/{name}/assets'
    if own.is_dir():
        import importlib.util
        for recipe in sorted(own.glob('gen_*.py')):
            spec=importlib.util.spec_from_file_location(f'{name}_{recipe.stem}',recipe);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
            module.generate()
        files=[p for p in own.rglob('*') if p.is_file() and p.suffix!='.py' and '__pycache__' not in p.parts]
        claim(target,name,[p.relative_to(own).as_posix() for p in files])
        for p in files:
            dest=out/p.relative_to(own);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    pack_shaders(name,out,sdl_gpu=target=='native-sdl3-gpu',target=target)
    # The browser's manifests (tools/gen_manifest.py), so a returning page re-fetches exactly what changed; native builds read in place.
    if target=='web':gen_manifest.write(out)

def claim(target,name,paths):
    """Records that the example owns these paths in build/<target>/assets (in build/examples/assets-<target>.json); exits when one is a
    shared file or another example's."""
    record=ROOT/f'build/examples/assets-{target}.json'
    owners=json.loads(record.read_text(encoding='utf-8')) if record.is_file() else {}
    for path in paths:
        if (ROOT/'examples/assets'/path).exists():sys.exit(f'examples/{name}: its {path} is also a shared file (examples/assets/{path})')
        if owners.get(path,name)!=name:sys.exit(f'examples/{name}: its {path} is also examples/{owners[path]}\'s, in their shared assets folder')
        owners[path]=name
    record.parent.mkdir(parents=True,exist_ok=True);record.write_text(json.dumps(owners,indent=1,sort_keys=True)+'\n',encoding='utf-8')

def pack_shaders(name,out,since=0,sdl_gpu=False,target='web'):
    """The example's shaders/*.glsl packed into out/shaders/*.hxshader (with SDL_GPU's dialects when sdl_gpu), claimed in the target's
    shared assets: those changed since `since` (a time), all by default. Returns the newest source's time."""
    newest=since;sources=sorted((ROOT/f'examples/{name}/shaders').glob('*.glsl'))
    claim(target,name,[f'shaders/{source.stem}.hxshader' for source in sources])
    for source in sources:
        stamp=source.stat().st_mtime;newest=max(newest,stamp)
        if stamp>since:pack_shader.pack(pack_shader.shdc_path(),source,out/'shaders'/(source.stem+'.hxshader'),sdl_gpu)
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
    """Builds the example for target ('web'; 'native' for the sokol profile; 'native-sdl3' for the SDL3 one with sokol_gfx on GL,
    'native-sdl3-gpu' with SDL_GPU) into build/<target>/<name>."""
    prepare(name)
    if target=='web':
        run(['haxe',hxml(name,'web')])
        terser=ROOT/'build/tools/node_modules/terser/bin/terser';js=ROOT/f'build/web/{name}/app.js'
        if terser.is_file():run(['node',terser,js,'--compress','--mangle','--output',js])
    else:
        from pins import check_hxcpp,check_sokol
        from native_build import env as native_env,place_runtimes
        check_hxcpp();check_sokol(ROOT)
        sdl3=None
        if target.startswith('native-sdl3'):
            import sdl3 as finder
            sdl3=finder.find();print(f'sdl3: {sdl3.origin}',flush=True)
        if target=='native-sdl3-gpu':shader(sdl_gpu=True)
        run(['haxe',hxml(name,target)],native_env(sdl3))
        folder=ROOT/f'build/{target}/{name}'
        place_runtimes(folder,sdl3)
        config=ROOT/f'examples/{name}/config.json'
        if config.is_file():shutil.copyfile(config,folder/'config.json')
        elif (folder/'config.json').exists():(folder/'config.json').unlink()
        assets(name,target)
        licenses(folder)

def compare_samples(browser,native,tolerance=3):
    """What differs between the samples the browser and the native run published (the autopilot's snapshot's samples: by name, the points,
    the colors as [r, g, b, a] and the tolerance, tolerance when it gives none): a sample one side lacks, another number of points, or a
    point's channel further apart than its tolerance. Empty when they agree."""
    problems=[]
    for sample in sorted(set(browser)|set(native)):
        if sample not in browser or sample not in native:
            problems.append(f'{sample}: only in the {"browser" if sample in browser else "native run"}');continue
        a,b=browser[sample]['colors'],native[sample]['colors'];allowed=browser[sample].get('tolerance',tolerance)
        if len(a)!=len(b):problems.append(f'{sample}: {len(a)} points in the browser, {len(b)} natively');continue
        for i,(seen,there) in enumerate(zip(a,b)):
            apart=max(abs(x-y) for x,y in zip(seen,there))
            if apart>allowed:problems.append(f'{sample} point {i} {browser[sample]["points"][i]}: browser {seen}, native {there}, {apart} apart (tolerance {allowed})')
    return problems

def autopilot(name,browser,profile='native'):
    """Replays every examples/<name>/autopilot script in the browser and natively (profile: 'native', the sokol profile, 'native-sdl3' or
    'native-sdl3-gpu');
    returns the scripts whose final games or samples differ or that failed."""
    import functools,http.server,threading
    if sys.platform.startswith('linux'):from private_display import private_display
    scripts=sorted(p.name for p in (ROOT/f'examples/{name}/autopilot').glob('*.json'))
    if not scripts:sys.exit(f'examples/{name}/autopilot has no scripts')
    for target in ('web',profile):build(name,target)
    out=ROOT/f'build/results/{name}';out.mkdir(parents=True,exist_ok=True)
    class Quiet(http.server.SimpleHTTPRequestHandler):
        def log_message(self,*args):pass
    handler=functools.partial(Quiet,directory=str(ROOT/'build/web'))
    server=http.server.ThreadingHTTPServer(('127.0.0.1',0),handler);threading.Thread(target=server.serve_forever,daemon=True).start()
    failed=[];program=ROOT/f'build/{profile}/{name}'/('Main.exe' if os.name=='nt' else 'Main')
    try:
        with private_display() if sys.platform.startswith('linux') else nullcontext(dict(os.environ)) as env:
            for script in scripts:
                options={'autopilot':f'autopilot/{name}/{script}','autoclose':'1','audio':'0','fast':'1'}
                query='&'.join(f'{k}={v}' for k,v in options.items())
                # The native program's Vulkan driver choice (lavapipe, for SDL_GPU on a private display) isn't Chrome's: there it leaves WebGL2 out.
                browser_env={k:v for k,v in os.environ.items() if k not in ('VK_DRIVER_FILES','VK_ICD_FILENAMES')}
                web=json.loads(subprocess.check_output(['node',ROOT/'tools/autopilot.cjs',browser,f'http://127.0.0.1:{server.server_address[1]}/{name}/?{query}'],cwd=ROOT,env=browser_env,text=True, encoding='utf-8'))
                result=out/f'{profile}-{script}';result.unlink(missing_ok=True)
                child=dict(env,HELIX_RESULT=str(result),**{'HELIX_'+k.upper():v for k,v in options.items()})
                process=subprocess.run([str(program)],cwd=ROOT/f'build/{profile}/{name}',env=child,capture_output=True,text=True, encoding='utf-8',timeout=300)
                if process.returncode or not result.is_file():failed.append(script);print(f'{script}: native run failed\n{process.stdout}{process.stderr}',flush=True);continue
                # What the native graphics said it runs on (SDL_GPU's backend), as SDL chooses it.
                for line in process.stderr.splitlines():
                    if line.startswith('HeliX SDL_GPU: '):print(f'{script}: {line}',flush=True)
                native=json.loads(result.read_text(encoding='utf-8'));same=web['result']['game']==native['game'] and not web['errors']
                samples=compare_samples(web['result'].get('autopilot',{}).get('samples',{}),native.get('autopilot',{}).get('samples',{}))
                (out/f'autopilot-{profile}-{script}').write_text(json.dumps({'script':script,'sameGame':same,'sampleDifferences':samples,'browserErrors':web['errors'],'browser':web['result'],'native':native},indent=2)+'\n', encoding='utf-8')
                ran=web.get('renderer')+(f', after the GPU gave none: {web["fallback"]}' if web.get('fallback') else '')
                print(f'{script}: same final game in the browser and {profile}: {same} (the browser on {ran})',flush=True)
                count=len(web['result'].get('autopilot',{}).get('samples',{}))
                if count:print(f'{script}: {count} samples alike within their tolerances: {not samples}'+''.join(f'\n  {problem}' for problem in samples),flush=True)
                if not same or samples:failed.append(script)
    finally:server.shutdown()
    return failed

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('name');p.add_argument('action',choices=['dev','build','autopilot']);p.add_argument('target',nargs='?',choices=['web','native','native-sdl3','native-sdl3-gpu'],default='web')
    p.add_argument('--port',type=int,default=8060);p.add_argument('--browser',help='Chromium for autopilot')
    p.add_argument('--group',help='with all: build only group I of N (I/N, from 1), every Nth example in name order, so N runners share them');a=p.parse_args()
    if a.name=='all':
        if a.action!='build':p.error('all only builds')
        names=sorted(d.name for d in (ROOT/'examples').iterdir() if (ROOT/source(d.name)/'App.hx').is_file())
        if a.group:
            index,count=map(int,a.group.split('/'))
            if not 1<=index<=count:p.error('--group is I/N with 1 <= I <= N')
            names=names[index-1::count]
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
        failed=autopilot(a.name,a.browser,a.target if a.target!='web' else 'native')
        if failed:sys.exit('Autopilot outcomes or samples differ: '+', '.join(failed)+f'; see build/results/{a.name}')
        return
    if a.action=='dev':
        prepare(a.name)
        # The edit loop: hotreload-hx rebuilds on save and swaps code and served files into the running page.
        # The dev server watches Haxe source; shader source is regenerated here, and the new layouts (Sprite2DLayout.hx and the rest) reload like any Haxe edit.
        # The page loads ../assets/, which from the served root is /assets/: the web target's shared assets, mounted there.
        server=subprocess.Popen(['haxe','-lib','hotreload-hx','--run','hotreload.DevServer','--port',str(a.port),'--mount','/assets=build/web/assets',hxml(a.name,'web')],cwd=ROOT)
        print(f'Open http://localhost:{a.port}/ and edit; Ctrl+C stops.',flush=True)
        try:
            failed=None;library_failed=None;packed=time.time()
            packer=Path(pack_shader.__file__).stat().st_mtime
            while server.poll() is None:
                # The packer itself edited: loaded again, and every shader packed again with it (the library's as its tool is newer).
                if Path(pack_shader.__file__).stat().st_mtime!=packer:
                    import importlib
                    packer=Path(pack_shader.__file__).stat().st_mtime
                    try:importlib.reload(pack_shader);packed=0;library_failed=None
                    except Exception as error:print('example: the shader packer failed to load, kept as it was:',error,flush=True)
                # The example's shaders, packed again as they change; the page reloads the asset.
                try:
                    repacked=pack_shaders(a.name,ROOT/'build/web/assets',packed)
                    # A repacked shader changes its manifest, or the next page load would refuse it.
                    if repacked!=packed:gen_manifest.write(ROOT/'build/web/assets')
                    packed=repacked
                except SystemExit as error:print('example: shader packing failed:',error,flush=True);packed=time.time()
                # The shader library's sources, packed into generated Haxe again as they change: the dev server rebuilds, and the reload
                # builds the changed ones again in place (helix.shaders.ShaderLibrary). A failed source is retried once it changes again.
                library=max((p.stat().st_mtime for p in pack_shader.LIBRARY.glob('*.glsl')),default=0)
                if library!=library_failed:
                    try:pack_shader.pack_library(GENERATED);library_failed=None
                    except SystemExit as error:print('example: library shader packing failed:',error,flush=True);library_failed=library
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
