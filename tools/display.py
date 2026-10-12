"""Temporary authorized X11 awake state, restored even when a cohort fails."""
from contextlib import contextmanager
import json
import re
import subprocess

@contextmanager
def awake(enabled, env, out):
    if not enabled:
        yield
        return
    def xset(*args):return subprocess.check_output(['xset',*args],env=env,text=True)
    before=xset('q');saver=re.search(r'timeout:\s*(\d+)\s+cycle:\s*(\d+)',before);dpms=re.search(r'Standby:\s*(\d+)\s+Suspend:\s*(\d+)\s+Off:\s*(\d+)',before)
    if not saver or not dpms:raise RuntimeError('Could not read display settings')
    state={'before':before,'authorization':'Existing user permission: disable blanking and restore prior settings','restored':False}
    def save():(out/'display-control.json').write_text(json.dumps(state,indent=2)+'\n')
    try:
        xset('dpms','force','on');xset('-dpms');xset('s','off');state['awake']=xset('q');save()
        yield
        state['completed']=True
    finally:
        xset('s',saver[1],saver[2]);xset('s','blank' if 'prefer blanking:  yes' in before else 'noblank');xset('s','expose' if 'allow exposures:  yes' in before else 'noexpose')
        xset('dpms',dpms[1],dpms[2],dpms[3]);xset('+dpms' if 'DPMS is Enabled' in before else '-dpms')
        if 'Monitor is Off' in before and 'DPMS is Enabled' in before:xset('dpms','force','off')
        state['after']=xset('q');state['restored']=state['before']==state['after'];save()
        if not state['restored']:raise RuntimeError('Display settings differed after restoration')
