#!/usr/bin/env python3
"""Checks the rule that 2D and 3D are named apart (docs/CONVENTIONS.md), so no one has to guess whether a type is one kind's:

  1. Every public type in helix.render2d ends in 2D and every one in helix.render3d in 3D, a counterpart of the other kind or not, but for
     those holding both kinds or neither (NEUTRAL, each with its reason).
  2. Every public type in a module named for a kind (Node3D.hx, AnimationClip3D.hx) ends in that kind, anywhere under src/helix/: a
     module's subtypes are its kind's too (Attachment3D, Track3D).
  3. Every public type of the scene file family (helix.scene's Scene*) ends in 3D, the only kind a scene file has yet, but for those both
     kinds' files will share (SHARED).
  4. 2D code names no 3D type: helix.render2d's code (its comments aside) uses nothing ending in 3D, so a type both kinds use is a neutral
     one (helix.graphics.AlphaMode), and a 2D program never reaches 3D through a name.

Run by helix.py test. Exits 1, listing each type, when one breaks a rule. Standard library only."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'src/helix'

# The types of render2d and render3d that are neither kind's alone.
NEUTRAL = {
    'Stage': 'the one display, holding 2D and the 3D views',
    'StageService': "the class Stage stands over",
    'View': "View2D's and View3D's shared base",
    'ViewFrame': "what a frame's views of both kinds hand the stage",
    'ChainCalls': "a post-processing chain's calls, over either kind",
    'Ktx': 'a texture file format',
    'TrueType': 'a font file format',
    'GlyphOutline': "a TrueType glyph's outline, as the format holds it",
    'Hdr': 'an image file format',
    'Gltf': 'a model file format',
    'Mat4': 'a matrix: its size is its name',
    'Tonemap': 'tone mapping, applied to any HDR picture',
}

# The scene file family's types both kinds' files will share.
SHARED = {
    'SceneBehavior': 'a behavior attached by name with its props',
    'SceneValue': "a file's value, JSON's shapes",
}

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


def problems():
    found = []
    for path in sorted((SOURCES / 'render2d').rglob('*.hx')):
        code = COMMENT.sub('', path.read_text(encoding='utf-8'))
        for name in sorted(set(THREE_D.findall(code))):
            found.append(f'{path.relative_to(ROOT).as_posix()}: names {name}, a 3D type, in 2D code: use or make a neutral type')
    for path in sorted(SOURCES.rglob('*.hx')):
        relative = path.relative_to(ROOT).as_posix()
        package = path.parent.name
        module = path.stem
        for name in declared(path):
            kind = '2D' if package == 'render2d' else '3D' if package == 'render3d' else None
            if kind and not name.endswith(kind) and name not in NEUTRAL:
                found.append(f'{relative}: {name} is in helix.{package}: name it {name}{kind}, or list it in NEUTRAL with why')
                continue
            for suffix in ('2D', '3D'):
                if module.endswith(suffix) and not name.endswith(suffix) and name not in NEUTRAL:
                    found.append(f"{relative}: {name} is in {module}'s module: name it {name}{suffix}")
            if package == 'scene' and name.startswith('Scene') and not name.endswith('3D') and name not in SHARED:
                found.append(f'{relative}: {name} is of the scene file family: name it {name}3D, or list it in SHARED with why')
    return found


def main():
    found = problems()
    for line in found:
        print(line)
    print(f'check_names: {"ok" if not found else f"{len(found)} type(s) named against the rule"}')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
