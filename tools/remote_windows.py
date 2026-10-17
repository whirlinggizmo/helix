#!/usr/bin/env python3
"""Build and check this checkout on a Windows machine over ssh, as it is, committed or not, and leave nothing behind there.

    python3 tools/remote_windows.py HOST [--then "TOOL ARGS"]... [--env NAME=VALUE]... [--desktop] [--keep]

Packs the working tree (tracked files and new ones git doesn't ignore) with what npm made here
(build/fixtures), the examples' generated sounds (build/generated/*/assets) and the node tools (build/tools/node_modules, plain JavaScript).
The Windows machine needn't have FFmpeg. It copies the archive with scp into a scratch folder in the remote user's profile and runs each
--then there as `python TOOL ARGS` in the copied tree (default: the hello example's native build). The scratch folder and the archive are
deleted afterwards, also when a step fails, unless --keep.

--env sets a variable for every step (SDL_GPU_DRIVER=vulkan, say).

--desktop runs the steps in the session logged in at the machine's screen, not the ssh session, which has no desktop: windows open there,
on its GPU. A scheduled task that runs only interactively starts them, and its output is printed when they end. Someone must be logged in.

HOST is an ssh destination whose shell is cmd.exe, with Python 3.12 or later first on its PATH, Haxe 4.3.7 and Visual Studio's C++ tools
(hxcpp finds them itself). The pinned hxcpp is installed into the copy's build/haxelib, as on Linux. Exits 0 when every step passed.
After libwgt's tools/run_remote_windows.py, with libwgf's --then. Standard library only."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ()
OPTIONAL = ('build/generated/*/assets', 'build/tools/node_modules')
DEFAULT = ['tools/example.py app-hello build native']


def working_tree():
    """Every file to send: tracked, new ones not ignored, and what GENERATED names (nothing today: the fixtures are tracked)."""
    listed = subprocess.run(['git', 'ls-files', '-co', '--exclude-standard', '-z'], cwd=ROOT, check=True,
                            stdout=subprocess.PIPE).stdout.decode()
    names = [name for name in listed.split('\0') if name and (ROOT / name).is_file()]
    for generated in GENERATED:
        path = ROOT / generated
        if not path.exists():
            raise SystemExit(f'remote_windows: {generated} is missing; make it here first')
        names += [p.relative_to(ROOT).as_posix() for p in ([path] if path.is_file() else path.rglob('*')) if p.is_file()]
    for pattern in OPTIONAL:
        for folder in ROOT.glob(pattern):
            names += [p.relative_to(ROOT).as_posix() for p in folder.rglob('*') if p.is_file()]
    return names


def desktop(steps, env):
    """The .bat the desktop's scheduled task runs: env set, each step, its output in log.txt, and a done.txt saying whether all passed."""
    lines = ['@echo off', 'cd /d "%~dp0"', 'set FAILED=0'] + [f'set "{pair}"' for pair in env]
    for step in steps:
        lines += [f'echo remote_windows: python {step} >> log.txt', f'python {step} >> log.txt 2>&1', 'if errorlevel 1 set FAILED=1']
    # Redirection first: "echo 0> f" would redirect stream 0. Renamed once written, so done.txt is never seen empty.
    lines += ['>status.txt echo %FAILED%', 'ren status.txt done.txt']
    return '\r\n'.join(lines) + '\r\n'


def script(folder, archive, steps, env, keep, on_desktop):
    """The .bat run there: unpack, each step (in the desktop session with on_desktop), clean up, and exit with whether every step passed."""
    lines = ['@echo off',
             'rem written by HeliX tools/remote_windows.py; it deletes itself',
             f'set ROOT=%USERPROFILE%\\{folder}',
             'set FAILED=0',
             'if exist "%ROOT%" rmdir /s /q "%ROOT%"',
             'mkdir "%ROOT%"',
             'cd /d "%ROOT%"',
             f'tar -xzf "%USERPROFILE%\\{archive}"',
             'if errorlevel 1 (echo remote_windows: unpacking failed & set FAILED=1 & goto done)']
    if on_desktop:
        # schtasks /it: only when the user is logged on, in their session. The start time is required and unused; /run starts it now.
        task = folder
        lines += [f'schtasks /create /tn {task} /tr "%ROOT%\\desktop.bat" /sc once /st 00:00 /it /f /ru %USERNAME% >nul 2>&1',
                  f'schtasks /run /tn {task} >nul',
                  'if errorlevel 1 (echo remote_windows: the desktop task did not start & set FAILED=1 & goto removetask)',
                  ':wait',
                  'if not exist done.txt (python -c "import time;time.sleep(2)" & goto wait)',
                  'type log.txt',
                  'set /p STATUS=<done.txt',
                  'if not "%STATUS%"=="0" set FAILED=1',
                  ':removetask',
                  f'schtasks /delete /tn {task} /f >nul 2>&1']
    else:
        lines += [f'set "{pair}"' for pair in env]
        for step in steps:
            lines += [f'echo remote_windows: python {step}', f'python {step}', 'if errorlevel 1 set FAILED=1']
    lines += [':done', 'cd /d "%USERPROFILE%"']
    if not keep:
        lines += ['rmdir /s /q "%ROOT%"', f'del "%USERPROFILE%\\{archive}"']
    # Deletes this .bat as it ends.
    lines += ['(goto) 2>nul & del "%~f0" & exit /b %FAILED%']
    return '\r\n'.join(lines) + '\r\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('host')
    parser.add_argument('--then', action='append', metavar='TOOL', help='a tool and its arguments, run there as python TOOL; repeatable')
    parser.add_argument('--env', action='append', default=[], metavar='NAME=VALUE', help='a variable set for every step; repeatable')
    parser.add_argument('--desktop', action='store_true', help='run the steps in the logged-in desktop session, where windows can open')
    parser.add_argument('--keep', action='store_true', help='leave the scratch folder there, to look into it')
    args = parser.parse_args()
    steps = args.then or DEFAULT
    tag = f'helix-remote-{os.getpid()}'
    archive, bat = f'{tag}.tgz', f'{tag}.bat'
    with tempfile.TemporaryDirectory() as scratch:
        local_archive, local_bat = Path(scratch) / archive, Path(scratch) / bat
        with tarfile.open(local_archive, 'w:gz') as tar:
            for name in working_tree():
                tar.add(ROOT / name, arcname=name)
            if args.desktop:
                inner = Path(scratch) / 'desktop.bat'
                inner.write_bytes(desktop(steps, args.env).encode())
                tar.add(inner, arcname='desktop.bat')
        local_bat.write_bytes(script(tag, archive, steps, args.env, args.keep, args.desktop).encode())
        print(f'remote_windows: {len(steps)} step(s) on {args.host}', flush=True)
        if subprocess.run(['scp', '-q', str(local_archive), str(local_bat), f'{args.host}:']).returncode != 0:
            print('remote_windows: copying to the host failed')
            return 1
    ran = subprocess.run(['ssh', args.host, bat])
    if args.keep:
        print(f'remote_windows: kept in %USERPROFILE%\\{tag} on {args.host}')
    print('remote_windows: ' + ('PASS' if ran.returncode == 0 else 'FAIL'))
    return 0 if ran.returncode == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
