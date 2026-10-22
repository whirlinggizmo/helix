#!/usr/bin/env python3
"""Checks the tools (docs/CONVENTIONS.md, "Every tool answers --help"): every Python tool (tools/*.py, helix.py) and Node tool (tools/*.cjs)

  1. reads its arguments through a parser, read in its source before anything runs: cli.parser or cli.module (tools/cli.py) or argparse in
     Python, cli.cjs's args in Node; a tool that doesn't is never run here, as it would do its work with --help ignored;
  2. answers --help with a usage line, exiting 0, within SECONDS;
  3. refuses an option no tool takes, exiting non-zero;
  4. is named in BUILDING.md's table of tools, and the table names no tool that isn't there.

The tools run in parallel, from the checkout. Run by helix.py test. Exits 1, listing each problem. Standard library only."""
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cli  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SECONDS = 60
NOT_AN_OPTION = '--not-an-option-of-any-tool'
PARSES = {'.py': re.compile(r'\bcli\.(parser|module)\(|argparse\.ArgumentParser\('), '.cjs': re.compile(r"cli\.cjs'\)\.args\(|require\.main === module")}


def tools():
    """Every tool, relative to the checkout."""
    found = sorted(ROOT.glob('tools/*.py')) + sorted(ROOT.glob('tools/*.cjs')) + [ROOT / 'helix.py']
    return [path.relative_to(ROOT).as_posix() for path in found]


def command(tool, *arguments):
    return ([sys.executable] if tool.endswith('.py') else ['node']) + [tool, *arguments]


def check(tool):
    """The problems with tool, run only once its source shows a parser."""
    source = (ROOT / tool).read_text(encoding='utf-8')
    if not PARSES[Path(tool).suffix].search(source):
        return [f'{tool}: reads no arguments through a parser (tools/cli.py, tools/cli.cjs), so --help would run it; not run']
    problems = []
    try:
        helped = subprocess.run(command(tool, '--help'), cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=SECONDS)
        if helped.returncode != 0 or not helped.stdout.lstrip().startswith('usage:'):
            problems.append(f'{tool}: --help exited {helped.returncode}, printing {helped.stdout.strip()[:80]!r}{helped.stderr.strip()[:200]!r}')
        refused = subprocess.run(command(tool, NOT_AN_OPTION), cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=SECONDS)
        if refused.returncode == 0:
            problems.append(f'{tool}: took {NOT_AN_OPTION} without refusing it')
    except subprocess.TimeoutExpired:
        problems.append(f'{tool}: still running after {SECONDS} s, so it ran rather than answering')
    return problems


def listed():
    """The tools BUILDING.md's table names."""
    text = (ROOT / 'BUILDING.md').read_text(encoding='utf-8')
    return set(re.findall(r'^\| `((?:tools/)?[\w.]+\.(?:py|cjs))` \|', text, re.M))


def problems():
    every = tools()
    with ThreadPoolExecutor() as pool:
        found = [p for ps in pool.map(check, every) for p in ps]
    named = listed()
    found += [f'{tool}: not named in BUILDING.md\'s table of tools' for tool in every if tool not in named]
    found += [f'{tool}: named in BUILDING.md\'s table of tools, but there is no such tool' for tool in sorted(named - set(every))]
    return found


def main():
    cli.parser(__doc__).parse_args()
    found = problems()
    for line in found:
        print(line)
    print(f'check_tools: {"ok" if not found else f"{len(found)} problem(s)"}')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
