"""Keeps this machine's screen on while a headed run uses it (--headed): a blanked or powered-off monitor has no vertical blank to pace
frames by and a browser may throttle a page it can't show, so a frame time taken then is wrong, and a locked session hides the windows.

On Linux under X11, for the run: X's screen saver and power management off (xset) and the monitor woken; XFCE's power manager, when it
runs, in its presentation mode, as it applies its own blanking over xset's; GNOME's idle delay 0, when a GNOME daemon runs. Each setting
is put back as it was afterwards, also when the run fails. A locked session refuses the run, as its windows would be behind the lock.
Elsewhere, or for a run that isn't headed, it does nothing. Imported by the tools, not run. Standard library only."""
from contextlib import contextmanager
import os
import re
import subprocess
import sys


def _run(*command):
    """A command's output, or None when it fails or isn't there."""
    try:
        done = subprocess.run(command, capture_output=True, text=True)
    except OSError:
        return None
    return done.stdout if done.returncode == 0 else None


def _running(*names):
    """Whether a process of one of these names runs."""
    out = _run('ps', '-eo', 'comm') or ''
    return any(line.strip() in names for line in out.splitlines())


def locked():
    """Whether this user's graphical session is locked (logind's LockedHint)."""
    sessions = _run('loginctl', 'list-sessions', '--no-legend') or ''
    for line in sessions.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == os.environ.get('USER'):
            hint = _run('loginctl', 'show-session', parts[0], '-p', 'LockedHint', '-p', 'Type') or ''
            if 'Type=x11' in hint or 'Type=wayland' in hint:
                return 'LockedHint=yes' in hint
    return False


@contextmanager
def kept_on(headed):
    """Keeps the screen on for the run within, when headed; puts each setting back after it."""
    if not headed or not sys.platform.startswith('linux') or not os.environ.get('DISPLAY'):
        yield
        return
    if locked():
        sys.exit('screen_power: the session is locked, so a headed run\'s windows would be behind the lock: unlock it, or run headless')
    query = _run('xset', 'q') or ''
    saver = re.search(r'prefer blanking:\s+(\w+).*?timeout:\s+(\d+)\s+cycle:\s+(\d+)', query, re.S)
    dpms = re.search(r'Standby:\s+(\d+)\s+Suspend:\s+(\d+)\s+Off:\s+(\d+)\s+DPMS is (\w+)', query, re.S)
    xfce = _running('xfce4-power-man', 'xfce4-power-manager')
    presentation = _run('xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/presentation-mode') if xfce else None
    gnome = _running('gsd-power', 'gnome-shell', 'gnome-screensaver')
    idle = _run('gsettings', 'get', 'org.gnome.desktop.session', 'idle-delay') if gnome else None
    try:
        if xfce:
            _run('xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/presentation-mode', '-n', '-t', 'bool', '-s', 'true')
        if gnome and idle is not None:
            _run('gsettings', 'set', 'org.gnome.desktop.session', 'idle-delay', '0')
        _run('xset', 'dpms', 'force', 'on')
        _run('xset', 's', 'off')
        _run('xset', 's', 'reset')
        _run('xset', '-dpms')
        yield
    finally:
        if saver:
            _run('xset', 's', saver.group(2), saver.group(3))
            _run('xset', 's', 'blank' if saver.group(1) == 'yes' else 'noblank')
        if dpms:
            _run('xset', 'dpms', dpms.group(1), dpms.group(2), dpms.group(3))
            _run('xset', '+dpms' if dpms.group(4) == 'Enabled' else '-dpms')
        if xfce:
            if presentation is None:
                _run('xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/presentation-mode', '-r')
            else:
                _run('xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/presentation-mode', '-s', presentation.strip())
        if gnome and idle is not None:
            _run('gsettings', 'set', 'org.gnome.desktop.session', 'idle-delay', idle.split()[-1])


if __name__ == '__main__':
    import cli
    cli.module(__doc__)
