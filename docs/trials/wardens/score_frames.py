#!/usr/bin/env python3
"""Times entrants' programs as they stand (../README.md, "Scoring"): each built with the frame stats' hook in the library under it, and
run at each load for a fixed run of frames, the library printing the stats it recorded.

    python3 score_frames.py <entrant directory>... --helix <checkout> [--enemies 50,100,200] [--seed 1] [--frames 120,1200] [--page]
                            [--desktop]

Each entrant is copied to <entrant>.frames (the entrant's own directory left as it was) and built there, in the entrants' sandbox
(run_entrant.py), as a build runs an entrant's code (its macros, its Makefile):
- helix-raylib (a build.hxml): from its own build.hxml with -D helix-raylib-frame-stats, against --helix's haxelib, run with
  --frame_stats=<frames>. With --page, also built for JS as score_page.py builds it (in <entrant>.frames-page) and run in headless Chromium with
  ?frame_stats=<frames>, its stats read from window.helixResult.
- raylib C (a Makefile): with its Makefile, against its own copy of stock raylib 5.5, the compiler given frame_stats_wrap.c's object
  and the link's wraps of EndDrawing and WindowShouldClose, so raylib is as shipped. Run with RAYLIB_FRAME_STATS=<frames> in its
  environment. raylib C's draws aren't counted.

--frames W,N records frames W + 1 to N, each from one EndDrawing to the next, and the program closes after frame N. Each run is given
--enemies=<n> and --seed=<seed> (the spec's run options). The stats go to <entrant>.frames/frames.txt, a line a run, and a table of the
mean and p95 is printed.

Natively the runs are on a private display, whose software GL makes their times worth comparing with each other only. --desktop runs
them on this machine's display, for times worth reporting: windows open on the desktop, so it is run only when the person at it asks."""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path[:0] = [str(HERE), str(ROOT / 'tools')]
import run_entrant
import score_page

# The C file linked with the entrant's code, and the link's options that send its EndDrawing and WindowShouldClose through it.
WRAP = Path(__file__).resolve().parent / 'frame_stats_wrap.c'
WRAPPED = '-Wl,--wrap=EndDrawing -Wl,--wrap=WindowShouldClose'


def stats_of(output):
    """The stats a run printed, or None."""
    for line in output.splitlines():
        if line.startswith('frame_stats '):
            return json.loads(line[len('frame_stats '):])
    return None


def in_sandbox(copy, helix, env, command, timeout):
    """Runs a command in the copy, in the entrants' sandbox."""
    with open(os.devnull, 'rb') as nothing:
        wrap = run_entrant.sandbox(copy, helix, nothing)
        return subprocess.run(wrap + command, env=env, pass_fds=(nothing.fileno(),), capture_output=True, text=True, timeout=timeout)


def score(entrant, helix, args, display):
    """Builds and times one entrant; its lines for frames.txt."""
    copy = entrant.parent / (entrant.name + '.frames')
    if copy.exists():
        shutil.rmtree(copy)
    shutil.copytree(entrant, copy, symlinks=True)
    (entrant.parent / '.home' / copy.name).mkdir(parents=True, exist_ok=True)
    env = run_entrant.environment(copy, helix, display)
    helix_arm = (copy / 'build.hxml').is_file()
    if helix_arm:
        lines = (copy / 'build.hxml').read_text(encoding='utf-8').splitlines()
        (copy / 'frames.hxml').write_text('\n'.join(lines + ['-D helix-raylib-frame-stats']) + '\n', encoding='utf-8')
        built = in_sandbox(copy, helix, env, ['haxe', 'frames.hxml'], 1800)
        program = './native/Main'
    else:
        # The hook built apart and handed to the compiler with the wrap, so the entrant's Makefile, whatever it compiles, links it.
        hook = copy / 'frame_stats_wrap.o'
        made = subprocess.run(['cc', '-O2', '-c', str(WRAP), '-o', str(hook)], capture_output=True, text=True)
        if made.returncode:
            sys.exit(f'score_frames: {WRAP.name} failed to build\n{made.stderr}')
        (copy / 'native/wardens').unlink(missing_ok=True)
        built = in_sandbox(copy, helix, env, ['make', f'CC=cc {WRAPPED} {hook}'], 1800)
        program = './native/wardens'
    print(f'{entrant.name}: native build {"failed" if built.returncode else "ok"}', flush=True)
    if built.returncode:
        print((built.stdout + built.stderr)[-3000:])
        return []
    if not helix_arm:
        env['RAYLIB_FRAME_STATS'] = args.frames
    found = []
    for enemies in args.enemies.split(','):
        options = [f'--enemies={enemies}', f'--seed={args.seed}'] + ([f'--frame_stats={args.frames}'] if helix_arm else [])
        ran = in_sandbox(copy, helix, env, [program] + options, 1800)
        found.append(('native', enemies, stats_of(ran.stdout), ran))
    if helix_arm and args.page:
        page = score_page.build(entrant, helix, ['-D helix-raylib-frame-stats'], '.frames-page')
        if page is not None:
            for enemies in args.enemies.split(','):
                query = f'?enemies={enemies}&seed={args.seed}&frame_stats={args.frames}'
                printed = score_page.run(page, query, page / f'frames-{enemies}.png')
                found.append(('page', enemies, printed and printed.get('result'), None))
    lines = []
    for target, enemies, stats, ran in found:
        if stats is None:
            detail = f' (exit {ran.returncode})\n{ran.stdout[-1500:]}{ran.stderr[-1500:]}' if ran is not None else ''
            print(f'  {target} enemies={enemies}: no stats{detail}', flush=True)
            continue
        print(f'  {target} enemies={enemies}: {stats["frames"]} frames, mean {stats["meanFrameTime"] * 1000:.2f} ms, '
              f'p95 {stats["p95FrameTime"] * 1000:.2f} ms', flush=True)
        lines.append(json.dumps({'run': entrant.name, 'target': target, 'enemies': int(enemies), 'seed': args.seed, **stats}))
    (copy / 'frames.txt').write_text(''.join(line + '\n' for line in lines), encoding='utf-8')
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('entrants', type=Path, nargs='+')
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--enemies', default='50,100,200')
    parser.add_argument('--seed', type=int, default=1)
    parser.add_argument('--frames', default='120,1200')
    parser.add_argument('--page', action='store_true')
    parser.add_argument('--desktop', action='store_true')
    args = parser.parse_args()
    helix = args.helix.resolve()
    sys.path.insert(0, str(helix / 'tools'))
    from private_display import private_display
    if args.desktop:
        display = {'DISPLAY': os.environ['DISPLAY'], 'SDL_VIDEO_DRIVER': os.environ.get('SDL_VIDEO_DRIVER', 'x11')}
        for entrant in args.entrants:
            score(entrant.resolve(), helix, args, display)
    else:
        with private_display() as display:
            for entrant in args.entrants:
                score(entrant.resolve(), helix, args, display)


if __name__ == '__main__':
    main()
