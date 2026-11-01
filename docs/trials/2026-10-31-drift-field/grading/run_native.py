"""Runs a command on a private display, with no sound, no D-Bus session, Wayland or runtime directory: run_native.py <cwd> <command...>."""
import subprocess, sys
sys.path.insert(0, '/home/rknopf/projects/github/whirlinggizmo/helix-2.0/tools')
from private_display import private_display
with private_display(number=96) as env:
    for name in ('DBUS_SESSION_BUS_ADDRESS', 'WAYLAND_DISPLAY', 'XDG_RUNTIME_DIR'):
        env.pop(name, None)
    env['SDL_AUDIO_DRIVER'] = 'dummy'
    sys.exit(subprocess.run(sys.argv[2:], cwd=sys.argv[1], env=env).returncode)
