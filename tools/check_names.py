#!/usr/bin/env python3
"""Checks the naming rules a tool can (docs/CONVENTIONS.md): that 2D and 3D are named apart, so no one has to guess whether a type is
one kind's (1 to 3), and that a call made on its own is a property (4):

  1. Every public type in a package of one kind (a package whose name ends in 2d or 3d: helix.render2d, helix.render3d) ends in that
     kind, a counterpart of the other kind or not, but for those holding both kinds or neither (NEUTRAL, each with its reason).
  2. Every public type in a module named for a kind (Node3D.hx, AnimationClip3D.hx) ends in that kind, in every library: a module's
     subtypes are its kind's too (Attachment3D, Track3D).
  3. 2D code names no 3D type: a 2d package's code (its comments aside) uses nothing ending in 3D, so a type both kinds use is a neutral
     one, living outside the kinds, and a 2D program never reaches 3D through a name.
  4. No method is named onX: a call made on its own is an `onX` property (`window.onClose = save`), assigned, not passed to a method.

Run by helix.py test. Exits 1, listing each type, when one breaks a rule. Standard library only."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [ROOT / 'platform/src/helix', ROOT / 'log/src/helix', ROOT / 'math/src/helix', ROOT / 'services/src/helix']

# The types of a kind's package that are neither kind's alone, each with its reason (none yet: no library draws).
NEUTRAL = {}

DECLARATION = re.compile(r'^(?:@:[^\n]*?\s+)*(private\s+)?(?:extern\s+)?(?:final\s+)?'
                         r'(?:class|interface|enum abstract|enum|abstract class|abstract|typedef)\s+(\w+)', re.M)


def declared(path):
    """The public types declared at path's top level."""
    text = path.read_text(encoding='utf-8')
    return [m.group(2) for m in DECLARATION.finditer(text) if not m.group(1)]


# A comment, line or block, which may name what the code doesn't.
COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)
# A type of the 3D kind, named in code.
THREE_D = re.compile(r'\b[A-Z]\w*3D\b')
# A method named onX, declared in code.
ON_METHOD = re.compile(r'\bfunction\s+(on[A-Z]\w*)')


def problems():
    found = []
    for path in sorted(p for source in SOURCES for p in source.rglob('*.hx') if p.parent.name.endswith('2d')):
        code = COMMENT.sub('', path.read_text(encoding='utf-8'))
        for name in sorted(set(THREE_D.findall(code))):
            found.append(f'{path.relative_to(ROOT).as_posix()}: names {name}, a 3D type, in 2D code: use or make a neutral type')
    for path in sorted(p for source in SOURCES for p in source.rglob('*.hx')):
        relative = path.relative_to(ROOT).as_posix()
        for name in ON_METHOD.findall(COMMENT.sub('', path.read_text(encoding='utf-8'))):
            found.append(f'{relative}: {name} is a method: a call made on its own is a property, var {name}:Null<...->Void>')
        package = path.parent.name
        module = path.stem
        for name in declared(path):
            kind = '2D' if package.endswith('2d') else '3D' if package.endswith('3d') else None
            if kind and not name.endswith(kind) and name not in NEUTRAL:
                found.append(f'{relative}: {name} is in helix.{package}: name it {name}{kind}, or list it in NEUTRAL with why')
                continue
            for suffix in ('2D', '3D'):
                if module.endswith(suffix) and not name.endswith(suffix) and name not in NEUTRAL:
                    found.append(f"{relative}: {name} is in {module}'s module: name it {name}{suffix}")
    return found


def main():
    import cli
    cli.parser(__doc__).parse_args()
    found = problems()
    for line in found:
        print(line)
    print(f'check_names: {"ok" if not found else f"{len(found)} name(s) against the rules"}')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
