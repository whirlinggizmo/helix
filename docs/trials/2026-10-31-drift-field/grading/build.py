"""Builds a trial game for grading, against the pinned worktree: build.py <game dir> <out dir> web|native [--record]."""
import os, subprocess, sys
from pathlib import Path
RUN = Path(__file__).resolve().parents[1]
HELIX = Path(os.environ.get('HELIX_ROOT', RUN / 'helix'))
sys.path.insert(0, str(HELIX / 'tools'))
import native_build, sdl3
game, out, target = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve(), sys.argv[3]
record = '--record' in sys.argv
out.mkdir(parents=True, exist_ok=True)
args = ['haxe', '-lib', 'helix-ray', '-cp', str(game), '-main', 'Main', '-dce', 'full']
if record:
    args += ['-cp', str(RUN / 'grading/recorder'), '--macro', 'trial.Recorder.install()']
if target == 'web':
    args += ['-js', str(out / 'app.js')]
    env = dict(os.environ)
else:
    args += ['-D', 'HXCPP_COMPILE_THREADS=4', '-cpp', str(out / 'native')]
    env = native_build.env(sdl3.find())
    env['HELIX_PLATFORM'] = str(HELIX / 'platform')
env['HAXELIB_PATH'] = str(HELIX / 'build/haxelib')
sys.exit(subprocess.run(args, env=env, cwd=game).returncode)
