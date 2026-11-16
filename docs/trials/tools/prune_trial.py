#!/usr/bin/env python3
"""Prunes a trial once it is graded and recorded: deletes its runs' directories, each run's source, builds, saves and the copies
scoring made, keeping its record here and the entrants' transcripts (~/.claude/projects).

    python3 prune_trial.py <record> <runs directory>... [--dry-run]

The record is the trial's folder in docs/trials and must hold results.md. Each runs directory is refused when it is inside a git
repository (it would be a checkout, not runs) or holds a run still going (a run.log whose last line is its start). --dry-run lists what
would be deleted, and its size, and deletes nothing."""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def size(path):
    """The bytes under path, its links not followed."""
    return sum(p.lstat().st_size for p in path.rglob('*') if p.is_file() and not p.is_symlink())


def running(runs):
    """The runs under runs whose run.log ends at its start."""
    going = []
    for log in runs.rglob('run.log'):
        lines = log.read_text(encoding='utf-8', errors='replace').split()
        if lines and lines[-1] == 'start':
            going.append(log.parent)
    return going


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('record', type=Path)
    parser.add_argument('runs', type=Path, nargs='+')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    if not (args.record / 'results.md').is_file():
        sys.exit(f'prune_trial: {args.record} holds no results.md; record the trial before pruning it')
    problems = []
    for runs in args.runs:
        if not runs.is_dir():
            problems.append(f'{runs}: no such directory')
        elif subprocess.run(['git', '-C', str(runs), 'rev-parse'], capture_output=True).returncode == 0:
            problems.append(f'{runs}: inside a git repository, so not a trial\'s runs')
        else:
            problems += [f'{run}: still running' for run in running(runs)]
    if problems:
        sys.exit('prune_trial: ' + '\n'.join(problems))
    total = 0
    for runs in args.runs:
        bytes_ = size(runs)
        total += bytes_
        print(f'{"would delete" if args.dry_run else "deleting"} {runs} ({bytes_ / 1e9:.1f} GB)')
        if not args.dry_run:
            shutil.rmtree(runs)
    print(f'prune_trial: {total / 1e9:.1f} GB {"to free" if args.dry_run else "freed"}')


main()
