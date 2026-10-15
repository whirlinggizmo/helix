#!/usr/bin/env python3
"""Build and check this checkout on a Windows machine over ssh, as it is, committed or not, and leave nothing behind there.

    python3 tools/remote_windows.py HOST [--then "TOOL ARGS"]... [--keep]

Packs the working tree (tracked files and new ones git doesn't ignore) with the test fixtures (build/fixtures: FFmpeg encodes them, which the
Windows machine needn't have), copies it with scp into a scratch folder in the remote user's profile, and runs each --then there as
`python TOOL ARGS` in the copied tree (default: the hello example's native build). The scratch folder and the archive are deleted
afterwards, also when a step fails, unless --keep.

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
GENERATED = ('build/fixtures',)
DEFAULT = ['tools/example.py app-hello build native']


def working_tree():
    """Every file to send: tracked, new ones not ignored, and the fixtures."""
    listed = subprocess.run(['git', 'ls-files', '-co', '--exclude-standard', '-z'], cwd=ROOT, check=True,
                            stdout=subprocess.PIPE).stdout.decode()
    names = [name for name in listed.split('\0') if name and (ROOT / name).is_file()]
    for folder in GENERATED:
        if not (ROOT / folder).is_dir():
            raise SystemExit(f'remote_windows: {folder} is missing; run python3 tools/fixtures.py here first')
        names += [p.relative_to(ROOT).as_posix() for p in (ROOT / folder).rglob('*') if p.is_file()]
    return names


def script(folder, archive, steps, keep):
    """The .bat run there: unpack, each step, clean up, and exit with whether every step passed."""
    lines = ['@echo off',
             'rem written by HeliX tools/remote_windows.py; it deletes itself',
             f'set ROOT=%USERPROFILE%\\{folder}',
             'set FAILED=0',
             'if exist "%ROOT%" rmdir /s /q "%ROOT%"',
             'mkdir "%ROOT%"',
             'cd /d "%ROOT%"',
             f'tar -xzf "%USERPROFILE%\\{archive}"',
             'if errorlevel 1 (echo remote_windows: unpacking failed & set FAILED=1 & goto done)']
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
        local_bat.write_bytes(script(tag, archive, steps, args.keep).encode())
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
