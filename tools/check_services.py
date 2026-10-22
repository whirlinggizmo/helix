#!/usr/bin/env python3
"""Checks that game code calls the program's services through their static classes (docs/CONVENTIONS.md): `Input.isDown(Key.A)`,
`Screen.visibleWidth`, not `Input.instance.isDown(Key.A)` or `var input = Input.instance; input.isDown(Key.A)`.

In the examples and the starter (what a game's code looks like), a service's static (a class of src/helix/ with `public static var instance`):

  1. isn't reached through its instance: `Service.instance.member` is refused;
  2. isn't aliased: `var name = Service.instance` (untyped) is refused.

The object itself stays allowed where a game needs it as a value: passed as an argument (`step(Input.instance, dt)`), or held as an
interface on purpose (`var source:IInput = Input.instance`, an input an autopilot may replace). Run by helix.py test. Exits 1, listing
each line, when one breaks a rule. Standard library only."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME_CODE = [ROOT / 'examples', ROOT / 'templates']
STATIC = re.compile(r'public\s+static\s+var\s+instance\b')
COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)


def services():
    """The names of the static classes standing over a service."""
    return sorted(path.stem for path in (ROOT / 'src/helix').rglob('*.hx') if STATIC.search(path.read_text(encoding='utf-8')))


def problems():
    names = '|'.join(services())
    through = re.compile(r'\b(' + names + r')\.instance\.\w')
    alias = re.compile(r'\b(?:var|final)\s+\w+\s*=\s*(' + names + r')\.instance\b')
    found = []
    for directory in GAME_CODE:
        for path in sorted(directory.rglob('*.hx')):
            code = COMMENT.sub(lambda m: '\n' * m.group(0).count('\n'), path.read_text(encoding='utf-8'))
            for number, line in enumerate(code.split('\n'), 1):
                relative = path.relative_to(ROOT).as_posix()
                for m in through.finditer(line):
                    found.append(f'{relative}:{number}: {m.group(1)}.instance.…: call {m.group(1)}.… directly')
                for m in alias.finditer(line):
                    found.append(f'{relative}:{number}: an alias of {m.group(1)}.instance: call {m.group(1)}.… directly')
    return found


def main():
    found = problems()
    for line in found:
        print(line)
    print(f'check_services: {"ok" if not found else f"{len(found)} use(s) of a service around its static"}')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
