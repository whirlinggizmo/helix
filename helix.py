"""HeliX's front door for Asteroids, the tests and the services checks. Python owns external tools; HXML owns Haxe settings.

Catalog examples have their own: tools/example.py. Blocks: tools/blocks.py."""
import argparse
import functools
import http.server
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'build/results/asteroids'

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)
def tool(name,*args):run([sys.executable,ROOT/'tools'/name,*args])

def display_options(parser,browser=True):
    if browser:parser.add_argument('--browser')
    parser.add_argument('--display');parser.add_argument('--xauthority');parser.add_argument('--awake',action='store_true')

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True,metavar='command')
    build=sub.add_parser('build',help='Build the HeliX Asteroids example for web, native or both');build.add_argument('target',choices=['web','native','all'],default='all',nargs='?');build.add_argument('--shdc')
    test=sub.add_parser('test',help='Run unit tests; --native adds native service tests');test.add_argument('--shdc');test.add_argument('--native',action='store_true');test.add_argument('--audio-device',action='store_true')
    services=sub.add_parser('services',help='Check browser (and optionally native) platform services');services.add_argument('--browser',required=True);services.add_argument('--native',action='store_true')
    audio=sub.add_parser('audio-check',help='Check thrust audio against a served browser build');audio.add_argument('--browser',required=True);audio.add_argument('--url',default='http://127.0.0.1:8050/')
    for name,text in [('check','Run Asteroids correctness checks'),('measure','Run checks, then record sizes and performance in build/results/asteroids')]:
        parser=sub.add_parser(name,help=text);display_options(parser)
    pilot=sub.add_parser('autopilot',help='Replay an autopilot script on web, native or both');pilot.add_argument('target',choices=['web','native','all'],default='all',nargs='?');pilot.add_argument('--script',default='autopilot/playthrough.json');display_options(pilot)
    serve=sub.add_parser('serve',help='Serve a built web example with gzip delivery');serve.add_argument('--port',type=int,default=8050);serve.add_argument('--bind',default='127.0.0.1');serve.add_argument('--example',default='asteroids',help='a built web example under build/web')
    sub.add_parser('sizes',help='Record emitted JS/Wasm/native sizes')
    a=p.parse_args();OUT.mkdir(parents=True,exist_ok=True)
    if a.command=='build':run([sys.executable,ROOT/'tools/build.py',a.target]+(['--shdc',a.shdc] if a.shdc else []))
    elif a.command=='test':
        if a.audio_device and not a.native:p.error('--audio-device requires --native')
        run([sys.executable,ROOT/'tools/build.py','test']+(['--shdc',a.shdc] if a.shdc else []))
        if a.native:
            sys.path.insert(0,str(ROOT/'tools'));from native_build import tool as native_tool
            result=subprocess.check_output([str(native_tool('native-services-test'))],text=True)
            sources={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['src/helix/adapters/audio/sokol/internal/audio.c','src/helix/adapters/input/sokol/internal/input.c','src/helix/adapters/input/evdev/internal/gamepad_linux.c','src/helix/adapters/input/evdev/internal/gamepad.h','vendor/sokol_audio.h']}
            value=json.loads(result);value['sources']=sources
            (OUT/'native-services.log').write_text(result);(OUT/'native-services.json').write_text(json.dumps(value,indent=2)+'\n');print(result,end='')
            if a.audio_device:
                result=subprocess.check_output([str(native_tool('native-audio-probe'))],text=True)
                value=json.loads(result);value['sources']=sources
                (OUT/'native-audio-device.json').write_text(json.dumps(value,indent=2)+'\n');print(result,end='')
    elif a.command=='services':tool('services.py','--browser',a.browser,*(['--native'] if a.native else []))
    elif a.command=='audio-check':run(['node',ROOT/'tools/thrust-check.cjs','--browser',a.browser,'--url',a.url])
    elif a.command in ['check','measure']:
        options=[]
        for name in ['browser','display','xauthority']:
            value=getattr(a,name)
            if value:options+=['--'+name,value]
        if not a.browser:p.error('--browser is required for check/measure')
        if a.command=='measure' and not a.display:p.error('Consolidated measurements require --display for the native cohort')
        if a.awake:options+=['--awake']
        tool('run.py','checks' if a.command=='check' else 'all',*options)
        if a.command=='measure':
            tool('sizes.py')
    elif a.command=='autopilot':
        if a.awake:p.error('Use check/measure --awake to own display settings; autopilot does not change them')
        options=['--script',a.script]
        for name in ['browser','display','xauthority']:
            value=getattr(a,name)
            if value:options+=['--'+name,value]
        tool('autopilot.py',a.target,*options)
    elif a.command=='serve':
        from tools.httpd import GzipHandler
        handler=functools.partial(GzipHandler,directory=str(ROOT/'build/web'/a.example))
        with http.server.ThreadingHTTPServer((a.bind,a.port),handler) as server:
            print(f'Serving on http://{a.bind}:{a.port}/',flush=True)
            try:server.serve_forever()
            except KeyboardInterrupt:pass
    else:tool(a.command+'.py')

if __name__=='__main__':main()
