"""Catalog examples (examples/<name>/App.hx): develop one under hotreload-hx, or build it for web or native.

Every example shares the launchers and page in examples/shared and the files in examples/assets."""
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
GENERATED=ROOT/'build/generated/sprite2d'
SHADER=ROOT/'src/helix/render2d/shaders/sprite2d.glsl'
SHARED=ROOT/'examples/shared'

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def shader(shdc):
    """Generate the framework's 2D shader when its source is newer than the output."""
    GENERATED.mkdir(parents=True,exist_ok=True)
    output=GENERATED/'GeneratedShader.hx'
    if output.is_file() and output.stat().st_mtime>=max(SHADER.stat().st_mtime,(SHADER.parent/'vertex.json').stat().st_mtime):return
    remembered=ROOT/'build/generated/shdc-path.txt'
    shdc=shdc or (remembered.read_text().strip() if remembered.is_file() else None) or shutil.which('sokol-shdc')
    if not shdc:raise RuntimeError('Pass --shdc /path/to/pinned/sokol-shdc')
    remembered.write_text(shdc+'\n')
    run([shdc,'-i',SHADER,'-o',GENERATED/'sprite.glsl.h','-l','glsl410:glsl300es','--no-log-cmdline'])
    run([shdc,'-i',SHADER,'-o',GENERATED/'sprite','-l','glsl410:glsl300es','-f','bare_yaml','--no-log-cmdline'])
    generate(GENERATED/'sprite_reflection.yaml',SHADER.parent/'vertex.json',GENERATED,ROOT)

def hxml(name,target):
    """The example's build arguments, written where the dev server and haxe read them."""
    launch='browser-webgl2' if target=='web' else 'native-sokol-gl'
    lines=['-cp src',f'-cp examples/{name}',f'-cp examples/shared/launch/{launch}','-cp examples/shared/src','-cp build/generated/sprite2d','-cp build/generated/fonts','-main Main',f'-D example={name}','-dce full','-D analyzer-optimize']
    lines+=[f'-js build/web/{name}/app.js'] if target=='web' else [f'-cpp build/native/{name}','-D HXCPP_M64','-D HXCPP_COMPILE_THREADS=4']
    path=ROOT/f'build/examples/{name}-{target}.hxml';path.parent.mkdir(parents=True,exist_ok=True);path.write_text('\n'.join(lines)+'\n')
    return path.relative_to(ROOT)

def prepare(name,shdc):
    """The generated shader and font, and the served folder: the page and the shared files."""
    shader(shdc);fontbake.generate()
    web=ROOT/f'build/web/{name}';web.mkdir(parents=True,exist_ok=True)
    (web/'index.html').write_text((SHARED/'index.html').read_text().replace('{{name}}',name))
    if (web/'assets').is_symlink() or (web/'assets').exists():
        if (web/'assets').is_symlink():(web/'assets').unlink()
        else:shutil.rmtree(web/'assets')
    shutil.copytree(ROOT/'examples/assets',web/'assets')
    licenses(web)

def licenses(out):
    """HeliX's license, the third-party notices and the license texts they name, which go with every build (THIRD_PARTY_NOTICES.md)."""
    target=out/'licenses'
    if target.exists():shutil.rmtree(target)
    target.mkdir(parents=True)
    shutil.copyfile(ROOT/'THIRD_PARTY_NOTICES.md',target/'THIRD_PARTY_NOTICES.md')
    for name,source in [('HeliX-MIT.txt','LICENSE'),('sokol-zlib.txt','vendor/LICENSE'),('sokol_utils-zlib.txt','vendor/sokol_utils/LICENSE'),('JetBrainsMono-OFL.txt','vendor/fonts/JetBrainsMono/OFL.txt'),('libsndfile-LGPL-2.1.txt','vendor/sndfile/COPYING')]:
        shutil.copyfile(ROOT/source,target/name)

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('name');p.add_argument('action',choices=['dev','build']);p.add_argument('target',nargs='?',choices=['web','native'],default='web')
    p.add_argument('--shdc');p.add_argument('--port',type=int,default=8060);a=p.parse_args()
    if not (ROOT/f'examples/{a.name}/App.hx').is_file():sys.exit(f'No examples/{a.name}/App.hx')
    prepare(a.name,a.shdc)
    if a.action=='dev':
        # The edit loop: hotreload-hx rebuilds on save and swaps code and served files into the running page.
        # The dev server watches Haxe source; shader source is regenerated here, and the new GeneratedShader.hx reloads like any Haxe edit.
        server=subprocess.Popen(['haxe','-lib','hotreload-hx','--run','hotreload.DevServer','--port',str(a.port),hxml(a.name,'web')],cwd=ROOT)
        print(f'Open http://localhost:{a.port}/ and edit; Ctrl+C stops.',flush=True)
        try:
            failed=None
            while server.poll() is None:
                # A failed source is retried only once it changes again.
                stamp=SHADER.stat().st_mtime
                if stamp!=failed:
                    try:shader(a.shdc);failed=None
                    except (subprocess.CalledProcessError,RuntimeError) as error:print('example: shader generation failed:',error,flush=True);failed=stamp
                time.sleep(.25)
        except KeyboardInterrupt:pass
        finally:
            try:urllib.request.urlopen(f'http://127.0.0.1:{a.port}/__hotreload_stop',timeout=5).read();server.wait(timeout=10)
            except Exception:server.terminate()
        return
    if a.target=='web':
        run(['haxe',hxml(a.name,'web')])
        terser=ROOT/'build/tools/node_modules/terser/bin/terser';js=ROOT/f'build/web/{a.name}/app.js'
        if terser.is_file():run(['node',terser,js,'--compress','--mangle','--output',js])
    else:
        from pins import check_hxcpp,check_sokol
        from native_build import env as native_env
        check_hxcpp();check_sokol(ROOT);env=native_env(GENERATED)
        run(['haxe',hxml(a.name,'native')],env)
        out=ROOT/f'build/native/{a.name}/assets'
        if out.exists():shutil.rmtree(out)
        shutil.copytree(ROOT/'examples/assets',out)
        licenses(out.parent)

if __name__=='__main__':main()
