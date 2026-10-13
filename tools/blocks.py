"""Blocks example: generate its 2D shader, then develop it under hotreload-hx, or build it for web or native."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import urllib.request
from shader_metadata import generate
import fontbake

ROOT=Path(__file__).resolve().parents[1]
GENERATED=ROOT/'build/generated/blocks'
WEB=ROOT/'build/web/blocks'
SHADER=ROOT/'src/helix/render2d/shaders/sprite2d.glsl'

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def shader(shdc):
    """Generate the framework's 2D shader for this example when its source is newer than the output."""
    GENERATED.mkdir(parents=True,exist_ok=True)
    output=GENERATED/'GeneratedShader.hx'
    if output.is_file() and output.stat().st_mtime>=max(SHADER.stat().st_mtime,(SHADER.parent/'vertex.json').stat().st_mtime):return
    remembered=GENERATED/'shdc-path.txt'
    shdc=shdc or (remembered.read_text().strip() if remembered.is_file() else None) or shutil.which('sokol-shdc')
    if not shdc:raise RuntimeError('Pass --shdc /path/to/pinned/sokol-shdc')
    remembered.write_text(shdc+'\n')
    run([shdc,'-i',SHADER,'-o',GENERATED/'sprite.glsl.h','-l','glsl410:glsl300es','--no-log-cmdline'])
    run([shdc,'-i',SHADER,'-o',GENERATED/'sprite','-l','glsl410:glsl300es','-f','bare_yaml','--no-log-cmdline'])
    generate(GENERATED/'sprite_reflection.yaml',SHADER.parent/'vertex.json',GENERATED,ROOT)

def prepare(shdc):
    """The generated shader and font, and the served folder's page."""
    shader(shdc);fontbake.generate()
    (WEB/'assets').mkdir(parents=True,exist_ok=True)
    shutil.copyfile(ROOT/'examples/blocks/web/index.html',WEB/'index.html')
    pilots=ROOT/'examples/blocks/autopilot'
    if pilots.is_dir():
        if (WEB/'assets/autopilot').exists():shutil.rmtree(WEB/'assets/autopilot')
        shutil.copytree(pilots,WEB/'assets/autopilot')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['dev','build','test','autopilot']);p.add_argument('target',nargs='?',choices=['web','native'],default='web')
    p.add_argument('--shdc');p.add_argument('--browser');p.add_argument('--display');p.add_argument('--xauthority');p.add_argument('--script',default='autopilot/smoke.json');p.add_argument('--port',type=int,default=8060);a=p.parse_args()
    if a.action=='test':run(['haxe','-cp','src','-cp','examples/blocks/src','-cp','tests/unit','-main','BlocksTests','--interp']);return
    if a.action=='autopilot':autopilot(a);return
    prepare(a.shdc)
    if a.action=='dev':
        # The edit loop: hotreload-hx rebuilds on save and swaps code and served files into the running page.
        # The dev server watches Haxe source; shader source is regenerated here, and the new GeneratedShader.hx reloads like any Haxe edit.
        server=subprocess.Popen(['haxe','-lib','hotreload-hx','--run','hotreload.DevServer','--port',str(a.port),'examples/blocks/web.hxml'],cwd=ROOT)
        print(f'Open http://localhost:{a.port}/ and edit; Ctrl+C stops.',flush=True)
        try:
            failed=None
            while server.poll() is None:
                # A failed source is retried only once it changes again.
                stamp=SHADER.stat().st_mtime
                if stamp!=failed:
                    try:shader(a.shdc);failed=None
                    except (subprocess.CalledProcessError,RuntimeError) as error:print('blocks: shader generation failed:',error,flush=True);failed=stamp
                time.sleep(.25)
        except KeyboardInterrupt:pass
        finally:
            try:urllib.request.urlopen(f'http://127.0.0.1:{a.port}/__hotreload_stop',timeout=5).read();server.wait(timeout=10)
            except Exception:server.terminate()
        return
    if a.target=='web':
        run(['haxe','examples/blocks/web.hxml'])
        terser=ROOT/'build/tools/node_modules/terser/bin/terser'
        if terser.is_file():run(['node',terser,WEB/'app.js','--compress','--mangle','--output',WEB/'app.js'])
    else:
        from pins import check_hxcpp
        from native_build import env as native_env
        check_hxcpp();env=native_env(GENERATED)
        run(['haxe','examples/blocks/native.hxml'],env)
        if (ROOT/'build/native/blocks/assets').exists():shutil.rmtree(ROOT/'build/native/blocks/assets')
        shutil.copytree(WEB/'assets',ROOT/'build/native/blocks/assets')

def autopilot(a):
    """The same script on the built browser page and the native binary; their final game states must match exactly."""
    import functools,http.server,threading
    from display import awake
    if not a.browser or not a.display or not a.xauthority:sys.exit('autopilot needs --browser, --display and --xauthority')
    out=ROOT/'build/results/blocks';out.mkdir(parents=True,exist_ok=True)
    handler=functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(WEB))
    handler.log_message=lambda *args:None
    server=http.server.ThreadingHTTPServer(('127.0.0.1',0),handler);threading.Thread(target=server.serve_forever,daemon=True).start()
    try:web=json.loads(subprocess.check_output(['node',ROOT/'tools/blocks-autopilot.cjs',a.browser,f'http://127.0.0.1:{server.server_address[1]}/?autopilot={a.script}'],text=True))
    finally:server.shutdown()
    env=dict(os.environ,DISPLAY=a.display,XAUTHORITY=a.xauthority,HELIX_AUTOPILOT=a.script,HELIX_AUTOCLOSE='1',HELIX_AUDIO='0',HELIX_RESULT=str(out/'native-autopilot-result.json'))
    (out/'native-autopilot-result.json').unlink(missing_ok=True)
    with awake(True,env,out):process=subprocess.run([str(ROOT/'build/native/blocks/Main')],env=env,capture_output=True,text=True,timeout=120)
    if process.returncode:sys.exit(process.stdout+process.stderr)
    native=json.loads((out/'native-autopilot-result.json').read_text())
    same=web['result']['game']==native['game']
    report={'script':a.script,'browserErrors':web['errors'],'sameGame':same,'browser':web['result'],'native':native}
    (out/'autopilot.json').write_text(json.dumps(report,indent=2)+'\n')
    print('browser:',{k:web['result']['game'][k] for k in ['state','pieces','score','held']},'| native:',{k:native['game'][k] for k in ['state','pieces','score','held']},'| same final game:',same,flush=True)
    assert same and not web['errors'],'Autopilot outcomes differ; see build/results/blocks/autopilot.json'

if __name__=='__main__':main()
