#!/usr/bin/env python3
"""A Stage3D's work on the CPU by case and model count, natively (hxcpp) and in V8 (Node), after libwgf's shadowbench
(tests/bench/StageBench.hx: a GPU that does nothing, so this is the stage's own work: walking, culling, choosing lights, sorting, records).

Measured in user-mode CPU cycles (perf stat, pinned to one core), since this machine's clock is clamped and milliseconds mean nothing; each
case's setup (the same program run for 0 frames) is taken away, leaving cycles a frame. Compare rows and targets as ratios.

    python3 tools/stagebench.py [--models 100,1000,4000] [--frames 200] [--cases look,away,...] [--core 2]"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASES = ['look', 'away', 'away-nocull', 'each', 'lights', 'shadows', 'pick']
BASE = ['-cp', 'src', '-cp', 'tests/bench', '-cp', 'build/generated/shaders', '-cp', 'build/generated/fonts', '-main', 'StageBench', '-dce',
        'full', '-D', 'analyzer-optimize']


def build():
    """The bench for Node and for hxcpp, as release builds are made."""
    subprocess.run(['haxe', *BASE, '-js', 'build/bench/stagebench.js'], cwd=ROOT, check=True)
    sys.path.insert(0, str(ROOT / 'tools'))
    from pins import check_hxcpp
    from native_build import ARCH
    check_hxcpp()
    subprocess.run(['haxe', *BASE, '-cpp', 'build/bench/stagebench-cpp', '-D', ARCH], cwd=ROOT, check=True, stdout=subprocess.DEVNULL,
                   env={**os.environ, 'HAXELIB_PATH': str(ROOT / 'build/haxelib')})


def cycles(core, command):
    """User-mode cycles of one run of command, pinned to core."""
    out = subprocess.run(['taskset', '-c', str(core), 'perf', 'stat', '-x,', '-e', 'cycles:u', *command], cwd=ROOT, capture_output=True,
                         text=True, encoding='utf-8', check=True)
    # A hybrid CPU reports each kind of core's counter; the pinned core's is the one counted.
    for line in out.stderr.splitlines():
        if 'cycles' in line and line.split(',')[0].isdigit():
            return int(line.split(',')[0])
    raise RuntimeError(out.stderr)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--models', default='100,1000,4000')
    p.add_argument('--frames', type=int, default=200)
    p.add_argument('--cases', default=','.join(CASES))
    p.add_argument('--core', type=int, default=2)
    a = p.parse_args()
    build()
    targets = {'hxcpp': [str(ROOT / 'build/bench/stagebench-cpp/StageBench')], 'V8': ['node', 'build/bench/stagebench.js']}
    counts = [int(n) for n in a.models.split(',')]
    print(f'Mega-cycles a frame (user mode, setup taken away), {a.frames} frames a run\n')
    print('| case | ' + ' | '.join(f'{t} {n}' for t in targets for n in counts) + ' |')
    print('|---|' + '---:|' * (len(targets) * len(counts)))
    for case in a.cases.split(','):
        row = []
        for target, command in targets.items():
            for n in counts:
                setup = cycles(a.core, [*command, case, str(n), '0'])
                total = cycles(a.core, [*command, case, str(n), str(a.frames)])
                row.append(f'{max(total - setup, 0) / a.frames / 1e6:.2f}')
        print(f'| {case} | ' + ' | '.join(row) + ' |', flush=True)


if __name__ == '__main__':
    main()
