"""A private X display for driving native windows in checks: Xvfb with one monitor, managed by Openbox.

Checks that press keys in a native window must not run on the user's desktop: the new window takes the keyboard focus,
so the user's typing lands in it and the window steals their focus. GL is Mesa's software renderer here, so this is for
behavior (windows, input), not for images or timing compared with a real GPU. Xvfb's RandR can't define monitors (xrandr --setmonitor is
ignored), so moving between monitors is not covered here."""
from contextlib import contextmanager
import os
import shutil
import subprocess
import time

@contextmanager
def private_display(number=91,width=1920,height=1080):
    """Yields an environment whose DISPLAY is the private server, one width x height monitor."""
    for tool in ('Xvfb','xrandr','openbox'):
        if not shutil.which(tool):raise RuntimeError(f'{tool} is needed for a private display')
    # SDL 3.4 tries Wayland before X11 when the session is Wayland's, which would open the window on the user's desktop: it's told X11.
    display=f':{number}';env=dict(os.environ,DISPLAY=display,SDL_VIDEO_DRIVER='x11');env.pop('XAUTHORITY',None);env.pop('WAYLAND_DISPLAY',None)
    server=subprocess.Popen(['Xvfb',display,'-screen','0',f'{width}x{height}x24','+extension','GLX','+extension','RANDR','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    manager=None
    try:
        for _ in range(50):
            if subprocess.run(['xrandr','--current'],env=env,capture_output=True).returncode==0:break
            time.sleep(.1)
        else:raise RuntimeError('Xvfb did not start on '+display)
        manager=subprocess.Popen(['openbox'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);time.sleep(.5)
        yield env
    finally:
        for process in (manager,server):
            if process is None:continue
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill()
