#!/usr/bin/env python3
"""Measures the CPU a program keeps busy: each case's program is run for a while and the processor time its process used (every thread's,
the GPU driver's included, user and kernel) is reported as a share of the wall time. Cases alternate round by round, as runs in different
sessions differ more than runs side by side, and each case's median is given with its runs. A case is `label:program[:NAME=VALUE,...]`,
the program run from its own directory (an example's build, which loads ../assets) with those variables set, sound off.

    python3 tools/measure_cpu.py [--seconds 20] [--runs 3] CASE...

    python3 tools/measure_cpu.py sokol-gl:out/linux-x64/release-sokol-gl/bin/shadows/shadows \\
        sdl3-gl:out/linux-x64/release-sdl3-gl/bin/shadows/shadows \\
        vulkan:out/linux-x64/release-sdl3-gpu/bin/shadows/shadows:SDL_GPU_DRIVER=vulkan

(on Windows out/windows-x64-msvc/..., the programs shadows.exe, and d3d12:...:SDL_GPU_DRIVER=direct3d12 too)

Each run opens the program's window where this runs (on Windows through tools/remote_windows.py --desktop, on Linux under
tools/private_display.py). Lines the program prints naming its GPU (`HeliX SDL_GPU: ...`) are repeated, as a machine may have two.
Standard library only."""
import argparse, os, pathlib, statistics, subprocess, sys, time

ROOT = pathlib.Path(__file__).resolve().parent.parent


def cpu_seconds(process):
    """The processor time the process has used so far, every thread's, user and kernel."""
    if sys.platform == 'win32':
        import ctypes
        from ctypes import wintypes
        class FILETIME(ctypes.Structure):
            _fields_ = [('low', wintypes.DWORD), ('high', wintypes.DWORD)]
        created, exited, kernel, user = FILETIME(), FILETIME(), FILETIME(), FILETIME()
        handle = wintypes.HANDLE(process._handle)
        if not ctypes.windll.kernel32.GetProcessTimes(handle, ctypes.byref(created), ctypes.byref(exited), ctypes.byref(kernel), ctypes.byref(user)):
            raise OSError('GetProcessTimes failed')
        return sum(((t.high << 32) | t.low) * 1e-7 for t in (kernel, user))
    stat = pathlib.Path(f'/proc/{process.pid}/stat').read_text()
    fields = stat[stat.rindex(')') + 2:].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')


def run(label, program, env, seconds):
    """One run: the program for seconds, then its CPU share and the GPU lines it printed."""
    program = (ROOT / program).resolve()
    variables = dict(os.environ, HELIX_AUDIO='0', **env)
    log = ROOT / 'build' / f'measure_cpu-{label}.log'
    with open(log, 'w', encoding='utf-8') as out:
        process = subprocess.Popen([str(program)], cwd=program.parent, env=variables, stdout=out, stderr=subprocess.STDOUT)
        started = time.monotonic()
        try:
            process.wait(seconds)
            raise SystemExit(f'{label}: the program ended on its own after {time.monotonic() - started:.1f} s; see {log}')
        except subprocess.TimeoutExpired:
            pass
        used = cpu_seconds(process)
        wall = time.monotonic() - started
        process.kill()
        process.wait()
    lines = [l.strip() for l in log.read_text(encoding='utf-8', errors='replace').splitlines() if 'SDL_GPU:' in l or 'error' in l.lower()]
    return used / wall * 100, lines


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--seconds', type=float, default=20)
    parser.add_argument('--runs', type=int, default=3)
    parser.add_argument('cases', nargs='+', metavar='CASE', help='label:program[:NAME=VALUE,...]')
    args = parser.parse_args()
    cases = []
    for case in args.cases:
        parts = case.split(':', 2)
        if len(parts) < 2:
            parser.error(f'a case is label:program[:NAME=VALUE,...]: {case}')
        env = dict(v.split('=', 1) for v in parts[2].split(',')) if len(parts) > 2 and parts[2] else {}
        cases.append((parts[0], parts[1], env))
    results = {label: [] for label, _, _ in cases}
    notes = {label: [] for label, _, _ in cases}
    for round_ in range(args.runs):
        for label, program, env in cases:
            share, lines = run(label, program, env, args.seconds)
            results[label].append(share)
            for line in lines:
                if line not in notes[label]:
                    notes[label].append(line)
            print(f'round {round_ + 1} {label}: {share:.1f}%', flush=True)
    print()
    for label, _, _ in cases:
        runs = ', '.join(f'{s:.1f}' for s in results[label])
        print(f'{label}: median {statistics.median(results[label]):.1f}% of a core (runs {runs})')
        for line in notes[label]:
            print(f'  {line}')


if __name__ == '__main__':
    main()
