#!/usr/bin/env python3
"""Times entrants' programs as they stand (../README.md, "Scoring"): each built with the frame stats' hook in the library under it, and
run at each load for a fixed run of frames, the library printing the stats it recorded.

    python3 score_frames.py <entrant directory>... --helix <checkout> [--enemies 50,100,200] [--seed 1] [--frames 120,1200]
                            [--native | --page] [--headless | --headed]

Each entrant is copied to <entrant>.frames (the entrant's own directory left as it was) and built there, in the entrants' sandbox
(run_entrant.py), as a build runs an entrant's code (its macros, its CMakeLists.txt):
- helix-raylib (a build.hxml): from its own build.hxml with -D helix-raylib-frame-stats, against --helix's haxelib, run with
  --frame_stats=<frames>; and for the page, built for JS as score_page.py builds it (in <entrant>.frames-page) and run in Chromium with
  ?frame_stats=<frames>, its stats read from window.helixResult.
- raylib C (a CMakeLists.txt): with its CMakeLists.txt, in build-frames/, against its own copy of stock raylib 5.5, the link given
  frame_stats_wrap.c's object and GNU ld's wraps of EndDrawing and WindowShouldClose (CMAKE_PROJECT_INCLUDE), so raylib is as
  shipped (Linux). Run with RAYLIB_FRAME_STATS=<frames> in its
  environment. raylib C's draws aren't counted, and it has no page.

--frames W,N records frames W + 1 to N, each from one EndDrawing to the next, and the program closes after frame N. Each run is given
--enemies=<n> and --seed=<seed> (the spec's run options). The stats go to <entrant>.frames/frames.txt, a line a run, and a table of the
mean and p95 is printed.

--native or --page times that kind alone, both by default. --headless, the default, runs them off screen: natively on a private display,
whose software GL makes their times worth comparing with each other only, and the page in headless Chromium. --headed runs them on this
machine's display and GPU, the page in Chromium's own window paced by the display, for times worth reporting: windows open on the
display, so it is run only when the person at it asks. The sandbox then also reaches the display's X authority and the GPU's devices."""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path[:0] = [str(HERE), str(ROOT / 'tools')]
import cli
import run_entrant
import score_page

# The C file linked with the entrant's code, and the link's options that send its EndDrawing and WindowShouldClose through it.
WRAP = Path(__file__).resolve().parent / 'frame_stats_wrap.c'
WRAPPED = 'LINKER:--wrap=EndDrawing LINKER:--wrap=WindowShouldClose'


def stats_of(output):
    """The stats a run printed, or None."""
    for line in output.splitlines():
        if line.startswith('frame_stats '):
            return json.loads(line[len('frame_stats '):])
    return None


def in_sandbox(copy, helix, env, command, timeout, headed=False):
    """Runs a command in the copy, in the entrants' sandbox; when headed, with this machine's display's X authority and the GPU's devices,
    which a window on the display needs."""
    with open(os.devnull, 'rb') as nothing:
        wrap = run_entrant.sandbox(copy, helix, nothing)
        if headed:
            extra = [a for device in sorted(Path('/dev').glob('nvidia*')) + [Path('/dev/dri')] if device.exists()
                     for a in ('--dev-bind', str(device), str(device))]
            if os.environ.get('XAUTHORITY'):
                extra += ['--ro-bind', os.environ['XAUTHORITY'], os.environ['XAUTHORITY']]
                env = dict(env, XAUTHORITY=os.environ['XAUTHORITY'])
            wrap = wrap[:-4] + extra + wrap[-4:]
        return subprocess.run(wrap + command, env=env, pass_fds=(nothing.fileno(),), capture_output=True, text=True, timeout=timeout)


def score(entrant, helix, args, display):
    """Builds and times one entrant; its lines for frames.txt."""
    native, page_too = cli.targets(args)
    copy = entrant.parent / (entrant.name + '.frames')
    if copy.exists():
        shutil.rmtree(copy)
    shutil.copytree(entrant, copy, symlinks=True)
    (entrant.parent / '.home' / copy.name).mkdir(parents=True, exist_ok=True)
    env = run_entrant.environment(copy, helix, display)
    helix_arm = (copy / 'build.hxml').is_file()
    found = []
    if not native:
        pass
    elif helix_arm:
        lines = (copy / 'build.hxml').read_text(encoding='utf-8').splitlines()
        (copy / 'frames.hxml').write_text('\n'.join(lines + ['-D helix-raylib-frame-stats']) + '\n', encoding='utf-8')
        built = in_sandbox(copy, helix, env, ['haxe', 'frames.hxml'], 1800)
        program = './native/Main'
    else:
        # The hook built apart and handed to the link with the wraps, so the entrant's CMakeLists.txt, whatever it compiles, links it.
        hook = copy / 'frame_stats_wrap.o'
        made = subprocess.run(['cc', '-O2', '-c', str(WRAP), '-o', str(hook)], capture_output=True, text=True)
        if made.returncode:
            sys.exit(f'score_frames: {WRAP.name} failed to build\n{made.stderr}')
        (copy / 'native/wardens').unlink(missing_ok=True)
        # Read after the entrant's project(), so CMake's check of the compiler links without them, and before its targets, which take
        # them: the object ahead of raylib's library, whose EndDrawing it calls.
        hooked = copy / 'frame_stats_wrap.cmake'
        hooked.write_text(f'add_link_options({WRAPPED})\nlink_libraries("{hook}")\n', encoding='utf-8')
        configured = in_sandbox(copy, helix, env, ['cmake', '-B', 'build-frames', '-DCMAKE_BUILD_TYPE=Release',
                                                   f'-DCMAKE_PROJECT_INCLUDE={hooked}'], 600)
        built = configured if configured.returncode else in_sandbox(copy, helix, env, ['cmake', '--build', 'build-frames'], 1800)
        program = './native/wardens'
    if native:
        print(f'{entrant.name}: native build {"failed" if built.returncode else "ok"}', flush=True)
        if built.returncode:
            print((built.stdout + built.stderr)[-3000:])
        else:
            if not helix_arm:
                env['RAYLIB_FRAME_STATS'] = args.frames
            for enemies in args.enemies.split(','):
                options = [f'--enemies={enemies}', f'--seed={args.seed}'] + ([f'--frame_stats={args.frames}'] if helix_arm else [])
                ran = in_sandbox(copy, helix, env, [program] + options, 1800, args.headed)
                found.append(('native', enemies, stats_of(ran.stdout), ran))
    if page_too and not helix_arm:
        print(f'{entrant.name}: no page (raylib C)', flush=True)
    if page_too and helix_arm:
        page = score_page.build(entrant, helix, ['-D helix-raylib-frame-stats'], '.frames-page')
        if page is not None:
            for enemies in args.enemies.split(','):
                query = f'?enemies={enemies}&seed={args.seed}&frame_stats={args.frames}'
                printed = score_page.run(page, query, page / f'frames-{enemies}.png', headed=args.headed)
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
    parser = cli.parser(__doc__)
    parser.add_argument('entrants', type=Path, nargs='+')
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--enemies', default='50,100,200')
    parser.add_argument('--seed', type=int, default=1)
    parser.add_argument('--frames', default='120,1200')
    cli.runs(parser)
    args = parser.parse_args()
    helix = args.helix.resolve()
    sys.path.insert(0, str(helix / 'tools'))
    from private_display import private_display
    if args.headed:
        display = {'DISPLAY': os.environ['DISPLAY'], 'SDL_VIDEO_DRIVER': os.environ.get('SDL_VIDEO_DRIVER', 'x11')}
        for entrant in args.entrants:
            score(entrant.resolve(), helix, args, display)
    else:
        with private_display() as display:
            for entrant in args.entrants:
                score(entrant.resolve(), helix, args, display)


if __name__ == '__main__':
    main()
