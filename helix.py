"""Experiment 05 front door. Python owns external tools; HXML owns Haxe settings."""
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
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True)
    build=sub.add_parser('build');build.add_argument('target',choices=['web','native','all'],default='all',nargs='?');build.add_argument('--shdc')
    test=sub.add_parser('test');test.add_argument('--shdc');test.add_argument('--native',action='store_true');test.add_argument('--audio-device',action='store_true')
    services=sub.add_parser('services');services.add_argument('--browser',required=True);services.add_argument('--native',action='store_true')
    audio=sub.add_parser('audio-check');audio.add_argument('--browser',required=True);audio.add_argument('--url',default='http://127.0.0.1:8050/')
    features=sub.add_parser('features');features.add_argument('--clang',required=True);features.add_argument('--wgrender',required=True);features.add_argument('--libwgf',required=True)
    for name in ['check','measure']:
        parser=sub.add_parser(name);display_options(parser)
    pilot=sub.add_parser('autopilot');pilot.add_argument('target',choices=['web','native','all'],default='all',nargs='?');pilot.add_argument('--script',default='autopilot/playthrough.json');display_options(pilot)
    serve=sub.add_parser('serve');serve.add_argument('--port',type=int,default=8050);serve.add_argument('--bind',default='127.0.0.1')
    sub.add_parser('sizes');sub.add_parser('report')
    mixed=sub.add_parser('mixed');mixed.add_argument('action',choices=['build','check','measure','profile','allocations','report']);mixed.add_argument('--shdc');mixed.add_argument('--target',choices=['all','browser','native'],default='all');display_options(mixed)
    record=sub.add_parser('record');record.add_argument('--workload',choices=['asteroids','mixed-submission'],default='asteroids');record.add_argument('--label',required=True)
    a=p.parse_args();OUT.mkdir(parents=True,exist_ok=True)
    if a.command=='build':run([sys.executable,ROOT/'tools/build.py',a.target]+(['--shdc',a.shdc] if a.shdc else []))
    elif a.command=='test':
        if a.audio_device and not a.native:p.error('--audio-device requires --native')
        run([sys.executable,ROOT/'tools/build.py','test']+(['--shdc',a.shdc] if a.shdc else []))
        if a.native:
            run(['cmake','-S',ROOT,'-B',ROOT/'build/native-hal','-DCMAKE_BUILD_TYPE=Release']);run(['cmake','--build',ROOT/'build/native-hal','--target','native-services-test'])
            result=subprocess.check_output([str(ROOT/'build/native-hal/native-services-test')],text=True)
            sources={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['src/helix/adapters/audio/sokol/internal/audio.c','src/helix/adapters/input/sokol/internal/input.c','src/helix/adapters/input/evdev/internal/gamepad_linux.c','src/helix/adapters/input/evdev/internal/gamepad.h','vendor/sokol_audio.h']}
            value=json.loads(result);value['sources']=sources
            (OUT/'native-services.log').write_text(result);(OUT/'native-services.json').write_text(json.dumps(value,indent=2)+'\n');print(result,end='')
            if a.audio_device:
                run(['cmake','--build',ROOT/'build/native-hal','--target','native-audio-probe'])
                result=subprocess.check_output([str(ROOT/'build/native-hal/native-audio-probe')],text=True)
                value=json.loads(result);value['sources']=sources
                (OUT/'native-audio-device.json').write_text(json.dumps(value,indent=2)+'\n');print(result,end='')
    elif a.command=='mixed':
        options=[]
        for name in ['shdc','browser','display','xauthority']:
            value=getattr(a,name)
            if value:options+=['--'+name,value]
        if a.awake:options+=['--awake']
        options+=['--target',a.target]
        tool('mixed.py',a.action,*options)
    elif a.command=='record':tool('record.py','--workload',a.workload,'--label',a.label)
    elif a.command=='services':tool('services.py','--browser',a.browser,*(['--native'] if a.native else []))
    elif a.command=='audio-check':run(['node',ROOT/'tools/thrust-check.cjs','--browser',a.browser,'--url',a.url])
    elif a.command=='features':tool('features.py','--clang',a.clang,'--wgrender',a.wgrender,'--libwgf',a.libwgf)
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
            tool('sizes.py');tool('report.py')
    elif a.command=='autopilot':
        if a.awake:p.error('Use check/measure --awake to own display settings; autopilot does not change them')
        options=['--script',a.script]
        for name in ['browser','display','xauthority']:
            value=getattr(a,name)
            if value:options+=['--'+name,value]
        tool('autopilot.py',a.target,*options)
    elif a.command=='serve':
        handler=functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT/'build/web/asteroids'))
        with http.server.ThreadingHTTPServer((a.bind,a.port),handler) as server:
            print(f'Serving on http://{a.bind}:{a.port}/',flush=True)
            try:server.serve_forever()
            except KeyboardInterrupt:pass
    else:tool(a.command+'.py')

if __name__=='__main__':main()
