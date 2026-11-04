#!/usr/bin/env python3
"""helix-raylib's 2D draw speed, measured with raylib's textures_bunnymark (engines/raylib/tests/bunnymark), so a later change to the
renderer is checked against numbers taken the same way.

    python3 tools/bunnymark.py [--runs 3] [--reference] [--ramp] [--display] [--json PATH]

The program is built as a release (-dce full, the analyzer's optimizations) for the browser, and natively for GL and for SDL_GPU, into
build/bunnymark/ under build/.lock. With --reference raylib's own C version of it is built too, against the raylib release
tools/raylib_parity.py builds (build/raylib), and run beside them. Every bunny starts from the same seed in each program.

Each program draws count bunnies for 120 frames to warm up, then times 600, and prints one JSON line. The native programs run at the counts
of --native-counts (1000, 10000, 50000 and 100000), the page at those of --page-counts (100000, 150000 and 200000), each --runs times
(3), and the table gives the median of the runs' mean frame time and of their 95th percentile frame time, in milliseconds. With --ramp each
program also runs in ramp mode: it starts at 1000 bunnies and adds 1000 each 60 frames while those held 59 frames a second, and the table
gives the most it held. An empty --native-counts or --page-counts leaves that side out.

Native runs go on a private display (tools/private_display.py), Mesa's software renderer, so their times are not representative of a
machine's GPU, and the tool says so. --display runs them on the real display instead ($DISPLAY): windows open on it, one at a time.
Native runs always use SDL's dummy audio and no session bus. The page runs in headless Chromium on the GPU (tools/bunnymark.cjs, Playwright
from build/tools, as tools/platform_checks.py's is installed), whatever the display. Runs go one at a time, so quiet the machine first.

  --json PATH  write every run and the medians to PATH

Linux only. Standard library only."""
import json
import os
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cli  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engines/raylib/tests/bunnymark'
OUT = ROOT / 'build/bunnymark'
LOCK = ROOT / 'build/.lock'
NATIVE_COUNTS = [1000, 10000, 50000, 100000]
PAGE_COUNTS = [100000, 150000, 200000]
NATIVE_SECONDS = 180
PAGE_SECONDS = 600
INDEX = ('<!doctype html><html lang="en"><meta charset="utf-8"><title>helix-raylib bunnymark</title><link rel="icon" href="data:,">'
         '<style>html,body{margin:0;background:#1a1d26;overflow:hidden}canvas{display:block;width:800px;height:450px}</style>'
         '<canvas id="canvas"></canvas><script src="app.js"></script></html>\n')


def build_all(reference):
    """Builds the programs under build/.lock; returns {name: native program}. The page is in OUT/web, whose files the native programs read too
    (they look in ../web from their directory)."""
    import fcntl
    import native_build
    import pins
    import sdl3
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    with LOCK.open('w') as lock:
        print('bunnymark: waiting for build/.lock', flush=True)
        fcntl.flock(lock, fcntl.LOCK_EX)
        pins.use_haxelib()
        pins.check_hxcpp()
        env = native_build.env(sdl3.find())
        jobs = f'HXCPP_COMPILE_THREADS={os.cpu_count() or 4}'
        common = ['-lib', 'helix-raylib', '-cp', str(SOURCE), '-main', 'Main', '-dce', 'full', '-D', 'analyzer-optimize']
        programs = {'helix-raylib gl': ('native-gl', []), 'helix-raylib sdl_gpu': ('native-gpu', ['-D', 'sdl_gpu'])}
        for name, (directory, defines) in programs.items():
            print(f'bunnymark: building {name}', flush=True)
            haxe(common + defines + ['-D', jobs, '-cpp', str(OUT / directory)], env)
        print('bunnymark: building helix-raylib page', flush=True)
        page = OUT / 'web'
        page.mkdir(parents=True, exist_ok=True)
        haxe(common + ['-js', str(page / 'app.js')], env)
        (page / 'index.html').write_text(INDEX, encoding='utf-8')
        (page / 'wabbit_alpha.png').write_bytes((SOURCE / 'wabbit_alpha.png').read_bytes())
        paths = {name: OUT / directory / 'Main' for name, (directory, _) in programs.items()}
        if reference:
            paths['raylib C'] = build_reference()
        return paths


def haxe(arguments, env):
    """Runs haxe in the checkout; stops with its output when it fails."""
    done = subprocess.run(['haxe'] + arguments, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8')
    if done.returncode:
        sys.exit(f'bunnymark: haxe failed\n{done.stdout[-3000:]}{done.stderr[-3000:]}')


def build_reference():
    """raylib's C bunnymark, linked with the library of raylib_parity's release (-O2 for the program, the library's own -O1); its path."""
    import raylib_parity
    source = raylib_parity.raylib('5.5')
    directory = OUT / 'raylib-c'
    (directory / 'resources').mkdir(parents=True, exist_ok=True)
    (directory / 'resources/wabbit_alpha.png').write_bytes((SOURCE / 'wabbit_alpha.png').read_bytes())
    print('bunnymark: building raylib C', flush=True)
    done = subprocess.run(['cc', '-O2', '-std=c99', '-D_GNU_SOURCE', '-DPLATFORM_DESKTOP', '-I', str(source / 'src'), str(SOURCE / 'bunnymark.c'),
                           str(source / 'src/libraylib.a'), *raylib_parity.LINK, '-o', str(directory / 'bunnymark')], capture_output=True, text=True)
    if done.returncode:
        sys.exit(f'bunnymark: raylib C failed to build\n{done.stderr[-3000:]}')
    return directory / 'bunnymark'


def native_run(program, option, display):
    """One native run in the program's directory; its JSON line, or None with the output's tail."""
    env = dict(display, SDL_AUDIO_DRIVER='dummy')
    env.pop('DBUS_SESSION_BUS_ADDRESS', None)
    try:
        done = subprocess.run([str(program), '--' + option], cwd=program.parent, env=env, capture_output=True, text=True, encoding='utf-8',
                              timeout=NATIVE_SECONDS)
        return found(done.stdout), (done.stdout + done.stderr)[-600:]
    except subprocess.TimeoutExpired:
        return None, f'no result in {NATIVE_SECONDS} s'


def page_run(option, browser):
    """One page run in headless Chromium; its JSON line, or None with what went wrong."""
    try:
        done = subprocess.run(['node', str(ROOT / 'tools/bunnymark.cjs'), browser, str(OUT / 'web'), option, str(PAGE_SECONDS)], capture_output=True,
                              text=True, encoding='utf-8', timeout=PAGE_SECONDS + 120)
    except subprocess.TimeoutExpired:
        return None, 'the page runner timed out'
    try:
        printed = json.loads(done.stdout.strip().splitlines()[-1])
    except (IndexError, ValueError):
        return None, (done.stdout + done.stderr)[-600:]
    return printed['result'], '; '.join(printed['errors']) + f' (renderer: {printed["renderer"]})'


def found(output):
    """The program's JSON line in its output, or None."""
    lines = [line for line in output.splitlines() if line.startswith('{') and '"contender"' in line]
    return json.loads(lines[-1]) if lines else None


def median(rows, key):
    """The median of key over the runs that printed it."""
    values = [row['result'][key] for row in rows if row['result'] and key in row['result']]
    return statistics.median(values) if values else None


def main():
    parser = cli.parser(__doc__)
    parser.add_argument('--runs', type=int, default=3, help='runs of each program and count (default 3)')
    parser.add_argument('--reference', action='store_true', help="also build and run raylib's C bunnymark, natively")
    parser.add_argument('--ramp', action='store_true', help='also run each program in ramp mode')
    parser.add_argument('--display', action='store_true', help='run the native programs on $DISPLAY, not on a private display')
    parser.add_argument('--native-counts', type=int, nargs='*', default=NATIVE_COUNTS, metavar='N', help='bunnies for the native runs')
    parser.add_argument('--page-counts', type=int, nargs='*', default=PAGE_COUNTS, metavar='N', help='bunnies for the page runs')
    parser.add_argument('--browser', default='', help="a Chromium to run the page in (default Playwright's own)")
    parser.add_argument('--json', metavar='PATH', help="write every run and the medians to PATH")
    a = parser.parse_args()
    if not sys.platform.startswith('linux'):
        print('bunnymark: Linux only')
        return 1
    if a.display and not os.environ.get('DISPLAY'):
        print('bunnymark: --display needs $DISPLAY')
        return 1
    programs = build_all(a.reference)
    modes = [f'count={n}' for n in a.native_counts] + (['ramp=1'] if a.ramp else [])
    page_modes = [f'count={n}' for n in a.page_counts] + (['ramp=1'] if a.ramp else [])
    rows = []

    def record(where, program, mode, run, result, note):
        rows.append({'where': where, 'program': program, 'mode': mode, 'run': run, 'result': result, 'note': None if result else note,
                     'loadavg': os.getloadavg()[0]})
        print(f'  {where} {program} {mode} run {run}: ' + (f'{result["mean_ms"]:.2f} ms' if result and 'mean_ms' in result else
              f'held {result["ramp_max"]}' if result else f'FAILED {note}'), flush=True)

    def native(display):
        # Round-robin, so a drift in the machine's state spreads over every program.
        for run in range(1, a.runs + 1):
            for mode in modes:
                for name, program in programs.items():
                    record('native', name, mode, run, *native_run(program, mode, display))

    if modes:
        if a.display:
            print('bunnymark: native runs on the real display, $DISPLAY=' + os.environ['DISPLAY'], flush=True)
            native(dict(os.environ))
        else:
            from private_display import private_display
            print('bunnymark: native runs on a private display (software GL): these times are not representative', flush=True)
            with private_display() as display:
                native(display)
    for run in range(1, a.runs + 1):
        for mode in page_modes:
            record('page', 'helix-raylib', mode, run, *page_run(mode, a.browser))

    table = []
    for where, program, mode in dict.fromkeys((r['where'], r['program'], r['mode']) for r in rows):
        group = [r for r in rows if (r['where'], r['program'], r['mode']) == (where, program, mode)]
        ok = sum(1 for r in group if r['result'])
        if mode == 'ramp=1':
            values = (median(group, 'ramp_max'), None)
        else:
            values = (median(group, 'mean_ms'), median(group, 'p95_ms'))
        table.append({'where': where, 'program': program, 'mode': mode, 'runs': ok, 'mean_ms': values[0] if mode != 'ramp=1' else None,
                      'p95_ms': values[1], 'ramp_max': values[0] if mode == 'ramp=1' else None})
    print()
    print(f'{"where":7} {"program":22} {"mode":13} {"runs":>4} {"mean ms":>9} {"p95 ms":>9} {"held":>8}')
    for t in table:
        cell = lambda v, f: f'{v:{f}}' if v is not None else '-'  # noqa: E731
        print(f'{t["where"]:7} {t["program"]:22} {t["mode"]:13} {t["runs"]:>4} {cell(t["mean_ms"], ".2f"):>9} {cell(t["p95_ms"], ".2f"):>9} '
              f'{cell(t["ramp_max"], ".0f"):>8}')
    if modes and not a.display:
        print('\nThe native times above are from a private display (software GL), not representative. Pass --display for a real one.')
    if a.json:
        commit = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
        Path(a.json).write_text(json.dumps({'commit': commit, 'date': time.strftime('%Y-%m-%d %H:%M:%S'), 'display': 'real' if a.display else 'private',
                                            'runs': a.runs, 'medians': table, 'rows': rows}, indent=1) + '\n', encoding='utf-8')
    return 1 if any(not r['result'] for r in rows) else 0


if __name__ == '__main__':
    sys.exit(main())
