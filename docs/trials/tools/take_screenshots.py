#!/usr/bin/env python3
"""Takes the screenshots grading.md names of a run's native program, on a private display of 1280 x 720 in the run's own environment.

    python3 take_screenshots.py <run> --helix <checkout> [--click X,Y] [--enemies 10]

Without --click it saves grading/title.png, 4 seconds after start, to find the Play button on. With --click it also clicks there and
saves play.png, move.png (D held), pause.png (after Escape), play-later.png and late.png (after Escape again), then runs the program
again with --enemies=200 for crowd.png. The program is native/wardens (raylib C) or native/Main (Haxe), run from the run's directory
with --enemies=N --seed=1, and stopped after its last shot. What it prints goes to grading/<shot set>.log."""
import argparse
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent

def shot(env, path):
    subprocess.run(['import', '-window', 'root', str(path)], env=env, check=True)

def xdo(env, *args):
    subprocess.run(['xdotool', *args], env=env, check=True)

def run(entrant, env, out, enemies, steps):
    """Starts the program, then plays steps: (seconds to wait, action) with action a shot's name, ('click', x, y), ('down', key),
    ('up', key) or ('key', key)."""
    program = entrant / ('native/wardens' if (entrant / 'native/wardens').exists() else 'native/Main')
    with open(out / f'{steps[-1][1]}.log', 'w') as log:
        process = subprocess.Popen([str(program), f'--enemies={enemies}', '--seed=1'], cwd=entrant, env=env, stdout=log,
                                   stderr=subprocess.STDOUT)
        try:
            for wait, action in steps:
                time.sleep(wait)
                if process.poll() is not None:
                    print(f'shoot: the program ended (exit {process.returncode}) before {action}', file=sys.stderr)
                    break
                if isinstance(action, str):
                    shot(env, out / f'{action}.png')
                # raylib reads input once a frame, so a press and its release are held apart, as a frame on the software renderer is long.
                elif action[0] == 'click':
                    xdo(env, 'mousemove', str(action[1]), str(action[2]))
                    xdo(env, 'mousedown', '1')
                    time.sleep(0.3)
                    xdo(env, 'mouseup', '1')
                elif action[0] == 'down':
                    xdo(env, 'keydown', action[1])
                elif action[0] == 'up':
                    xdo(env, 'keyup', action[1])
                else:
                    xdo(env, 'keydown', action[1])
                    time.sleep(0.3)
                    xdo(env, 'keyup', action[1])
        finally:
            process.kill()
            process.wait()

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('run', type=Path)
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--click')
    parser.add_argument('--enemies', type=int, default=10)
    args = parser.parse_args()
    entrant, helix = args.run.resolve(), args.helix.resolve()
    sys.path.insert(0, str(helix / 'tools'))
    sys.path.insert(0, str(HERE))
    from private_display import private_display
    import run_entrant
    out = entrant / 'grading'
    out.mkdir(exist_ok=True)
    with private_display(1280, 720) as display:
        env = run_entrant.environment(entrant, helix, display)
        if not args.click:
            run(entrant, env, out, args.enemies, [(4, 'title')])
            return
        x, y = args.click.split(',')
        play = ('click', x, y)
        run(entrant, env, out, args.enemies, [
            (4, 'title'), (0, play), (3, 'play'), (0, ('down', 'd')), (0.75, 'move'), (0.75, ('up', 'd')), (0, ('key', 'Escape')),
            (1, 'pause'), (0, ('key', 'Escape')), (8, 'play-later'), (30, 'late')])
        run(entrant, env, out, 200, [(4, 'title-crowd'), (0, play), (20, 'crowd')])

main()
