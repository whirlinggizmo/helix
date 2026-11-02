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

def start(number,width,height):
    """Starts Xvfb on display number; returns its process and environment, or None when another server holds the number."""
    # SDL 3.4 tries Wayland before X11 when the session is Wayland's, which would open the window on the user's desktop: it's told X11.
    display=f':{number}';env=dict(os.environ,DISPLAY=display,SDL_VIDEO_DRIVER='x11');env.pop('XAUTHORITY',None);env.pop('WAYLAND_DISPLAY',None)
    server=subprocess.Popen(['Xvfb',display,'-screen','0',f'{width}x{height}x24','+extension','GLX','+extension','RANDR','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    for _ in range(50):
        # Xvfb exits at once when the number is held (its lock file), so two checks starting together each find their own.
        if server.poll() is not None:return None
        if subprocess.run(['xrandr','--current'],env=env,capture_output=True).returncode==0:return server,env
        time.sleep(.1)
    server.kill();server.wait()
    raise RuntimeError('Xvfb did not start on '+display)

@contextmanager
def private_display(width=1920,height=1080):
    """Yields an environment whose DISPLAY is a private server of its own, one width x height monitor: the first display number from
    140 no X server holds, so checks in several checkouts run at once."""
    for tool in ('Xvfb','xrandr','openbox'):
        if not shutil.which(tool):raise RuntimeError(f'{tool} is needed for a private display')
    started=None
    for number in range(140,200):
        if os.path.exists(f'/tmp/.X11-unix/X{number}') or os.path.exists(f'/tmp/.X{number}-lock'):continue
        started=start(number,width,height)
        if started:break
    if not started:raise RuntimeError('no free display number in 140-199')
    server,env=started
    manager=None
    try:
        manager=subprocess.Popen(['openbox'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);time.sleep(.5)
        yield env
    finally:
        for process in (manager,server):
            if process is None:continue
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill()

if __name__ == '__main__':
    import cli
    cli.module(__doc__)
