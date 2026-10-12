"""Own sequential browser/native cohorts and restore authorized display overrides."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent/'results'

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('phase',choices=['checks','cpu','autopilot','all']);p.add_argument('--browser',required=True);p.add_argument('--display');p.add_argument('--xauthority');p.add_argument('--awake',action='store_true');p.add_argument('--script',default='autopilot/playthrough.json');a=p.parse_args()
    env=dict(os.environ)
    if a.display:env['DISPLAY']=a.display
    if a.xauthority:env['XAUTHORITY']=a.xauthority
    OUT.mkdir(exist_ok=True);state=None
    def xset(*args):return subprocess.check_output(['xset',*args],env=env,text=True)
    if a.awake:
        if not a.display:p.error('--awake requires --display')
        before=xset('q');saver=re.search(r'timeout:\s*(\d+)\s+cycle:\s*(\d+)',before);dpms=re.search(r'Standby:\s*(\d+)\s+Suspend:\s*(\d+)\s+Off:\s*(\d+)',before)
        if not saver or not dpms:raise RuntimeError('Could not read display settings')
        state={'before':before,'authorization':'Existing user permission: disable blanking and restore prior settings','restored':False}
    def save():
        if state:(OUT/'display-control.json').write_text(json.dumps(state,indent=2)+'\n')
    def run(cmd,label):
        print('Running',label,flush=True)
        with (OUT/(label+'.log')).open('w') as log:result=subprocess.run(list(map(str,cmd)),cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        if result.returncode:raise RuntimeError((OUT/(label+'.log')).read_text()[-4000:])
        print('Completed',label,flush=True)
    try:
        if state:xset('dpms','force','on');xset('-dpms');xset('s','off');state['awake']=xset('q');save()
        for action in (['checks','cpu','autopilot'] if a.phase=='all' else [a.phase]):
            if action=='autopilot':
                run([sys.executable,ROOT/'tools/autopilot.py','all' if a.display else 'web','--script',a.script,'--browser',a.browser]+(['--display',a.display] if a.display else [])+(['--xauthority',a.xauthority] if a.xauthority else []),'autopilot-run')
                continue
            run(['node',ROOT/'tools/browser.cjs','--action',action,'--browser',a.browser],'browser-'+action+'-run')
            if a.display:run([sys.executable,ROOT/'tools/native.py','--action',action,'--display',a.display]+(['--xauthority',a.xauthority] if a.xauthority else []),'native-'+action+'-run')
        if state:state['completed']=True
    finally:
        if state:
            xset('s',saver[1],saver[2]);xset('s','blank' if 'prefer blanking:  yes' in before else 'noblank');xset('s','expose' if 'allow exposures:  yes' in before else 'noexpose')
            xset('dpms',dpms[1],dpms[2],dpms[3]);xset('+dpms' if 'DPMS is Enabled' in before else '-dpms')
            if 'Monitor is Off' in before and 'DPMS is Enabled' in before:xset('dpms','force','off')
            state['after']=xset('q');state['restored']=True;save();print('Restored display settings',flush=True)

if __name__=='__main__':main()
