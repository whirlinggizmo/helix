"""Run one packaged JSON autopilot on both real graphics targets."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/results/asteroids'

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('target',choices=['web','native','all']);p.add_argument('--script',default='autopilot/playthrough.json');p.add_argument('--browser');p.add_argument('--display');p.add_argument('--xauthority');a=p.parse_args();a.script=a.script.removeprefix("examples/asteroids/")
    if a.target in ['web','all']:
        subprocess.run(['node',str(ROOT/'tools/browser.cjs'),'--action','autopilot','--script',a.script]+(['--browser',a.browser] if a.browser else []),check=True)
    if a.target in ['native','all']:
        result=OUT/'native-autopilot-result.json';result.unlink(missing_ok=True)
        env=dict(os.environ,HELIX_AUTOPILOT=a.script,HELIX_FAST='1',HELIX_AUDIO='0',HELIX_RESULT=str(result),HELIX_CAPTURE=str(OUT/'native-autopilot.ppm'))
        if a.display:env['DISPLAY']=a.display
        if a.xauthority:env['XAUTHORITY']=a.xauthority
        process=subprocess.run([str(ROOT/'build/native/asteroids/Main')],env=env,capture_output=True,text=True,timeout=40)
        (OUT/'native-autopilot.log').write_text(process.stdout+process.stderr)
        if process.returncode:raise RuntimeError(process.stdout+process.stderr)
        value=json.loads(result.read_text());assert value['autopilot']['completed']
        report={'completed':True,'script':a.script,'sha256':hashlib.sha256((ROOT/'build/native/asteroids/Main').read_bytes()).hexdigest(),'result':value}
        if a.target=='all':
            browser=json.loads((OUT/'browser-autopilot.json').read_text());assert browser['completed'] and browser['result']['game']==value['game'];assert browser['result']['autopilot']==value['autopilot']
            report['difference']=json.loads(subprocess.check_output(['node',str(ROOT/'tools/images.cjs'),str(OUT/'native-autopilot.ppm'),str(OUT/'browser-autopilot.png'),str(OUT/'native-autopilot.png')],text=True));assert report['difference']['maxRgbDifference']==0
        (OUT/'native-autopilot.ppm').unlink(missing_ok=True)
        (OUT/'native-autopilot.json').write_text(json.dumps(report,indent=2)+'\n');print('Autopilot native completed:',value['autopilot']['ticks'],'ticks')

if __name__=='__main__':main()
