"""Linux Sokol/hxcpp frozen captures, real input, and uninstrumented CPU trials."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/results/asteroids'
EXE=ROOT/'build/native/asteroids/Main'

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--action',choices=['checks','cpu'],default='checks');p.add_argument('--display',default=os.environ.get('DISPLAY'));p.add_argument('--xauthority',default=os.environ.get('XAUTHORITY'));p.add_argument('--repeats',type=int,default=3);args=p.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    report={'action':args.action,'date':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'completed':False,'platform':platform.platform(),'display':args.display,'sha256':hashlib.sha256(EXE.read_bytes()).hexdigest(),'checks':[],'runs':[]}
    destination=OUT/('native-'+args.action+'.json')
    def save():destination.write_text(json.dumps(report,indent=2)+'\n')
    env=dict(os.environ,HELIX_AUDIO='0',HELIX_AUTOCLOSE='1')
    if args.display:env['DISPLAY']=args.display
    if args.xauthority:env['XAUTHORITY']=args.xauthority
    for repeat in range(args.repeats if args.action=='cpu' else 1):
        for tick in ([0,180,600,1200,2400] if args.action=='checks' else [-1]):
            stem=f'native-{tick if tick>=0 else "cpu-"+str(repeat)}';result=OUT/(stem+'.json');result.unlink(missing_ok=True)
            child=dict(env,HELIX_TICK=str(tick),HELIX_REPLAY='1',HELIX_FRAMES='600',HELIX_RESULT=str(result))
            if args.action=='checks':child['HELIX_CAPTURE']=str(OUT/(stem+'.ppm'))
            proc=subprocess.run([str(EXE)],env=child,text=True,capture_output=True,timeout=40)
            (OUT/(stem+'.log')).write_text((proc.stdout+'\n'+proc.stderr).rstrip()+'\n')
            if proc.returncode:raise RuntimeError(proc.stderr+'\n'+proc.stdout)
            value=json.loads(result.read_text());assert not any(x in value['host']['renderer'].lower() for x in ['software','llvmpipe','swiftshader'])
            if tick>=0:
                browser=json.loads((OUT/'browser-checks.json').read_text());expected=next(c['result'] for c in browser['checks'] if c['tick']==tick)
                assert value['game']==expected['game'],f'Native game state differs at {tick}'
                assert value['geometryHash']==expected['geometryHash'],f'Native prepared vertex bytes differ at {tick}'
                difference=json.loads(subprocess.check_output(['node',str(ROOT/'tools/images.cjs'),str(OUT/(stem+'.ppm')),str(OUT/f'browser-{tick}.png'),str(OUT/(stem+'.png'))],text=True))
                assert difference['unmatchedPixels']/(800*600)<0.001 and difference['meanAbsRgbDifference']<0.5,difference
                (OUT/(stem+'.ppm')).unlink()  # PNG retains all capture pixels losslessly.
                report['checks'].append({'tick':tick,'difference':difference,'result':value})
            else:
                assert value['inputTick']==660 and value['measuredFrames']==600
                expected=json.loads((OUT/'browser-cpu.json').read_text())['runs'][0]['game'];assert value['game']==expected
                report['runs'].append({'repeat':repeat,**value})
            save();print('Checked' if tick>=0 else 'Measured',stem,flush=True)
    if args.action=='checks':
        live=OUT/'native-live.json';live.unlink(missing_ok=True);child=dict(env,HELIX_AUTOCLOSE='0',HELIX_AUDIO='1',HELIX_FRAMES='3600',HELIX_LIVE=str(live))
        with (OUT/'native-input.log').open('w') as log:
            proc=subprocess.Popen([str(EXE)],env=child,stdout=log,stderr=subprocess.STDOUT)
            try:
                def state():
                    try:return json.loads(live.read_text())
                    except (OSError,json.JSONDecodeError):return None
                def wait(predicate):
                    deadline=time.monotonic()+8
                    while time.monotonic()<deadline:
                        s=state()
                        if s and predicate(s):return s
                        if proc.poll() is not None:raise RuntimeError('Native input process exited')
                        time.sleep(.03)
                    raise RuntimeError('Native input check timed out')
                wait(lambda s:s['frames']>0)
                def xdo(*a):return subprocess.check_output(['xdotool',*map(str,a)],env=child,text=True).strip()
                wid=xdo('search','--pid',proc.pid,'--name','^HeliX Haxe$').splitlines()[-1]
                xdo('windowfocus','--sync',wid);xdo('mousemove','--window',wid,400,345);xdo('mousedown',1);before=wait(lambda s:s['game']['state']=='playing');xdo('mouseup',1)
                xdo('keydown','--window',wid,'w','space');after=wait(lambda s:s['game']['shots']>=3);xdo('keyup','--window',wid,'w','space')
                assert before['game']['ship']!=after['game']['ship']
                assert after['host']['audioAvailable'] and after['host']['audioPlayed']>=3
                assert after['host']['audioBackend']=='sokol-audio' and after['host']['audioCallbacks']>0
                wait(lambda s:s['host']['audioLoops']==0)
                xdo('windowsize',wid,1000,700);wait(lambda s:s['width']==1000 and s['height']==700)
                report['interactive']={'start':True,'thrust':True,'fire':True,'resize':True,'pointerStart':True,'loopStopped':True,'audioOutput':'Sokol ALSA device/callback active; no audible-output claim'}
            finally:
                proc.terminate()
                try:proc.wait(timeout=2)
                except subprocess.TimeoutExpired:proc.kill();proc.wait(timeout=5)
        live.unlink(missing_ok=True)
    report['completed']=True;save()

if __name__=='__main__':main()
