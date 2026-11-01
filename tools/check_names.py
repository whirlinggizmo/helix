#!/usr/bin/env python3
"""Checks the naming rules a tool can (docs/CONVENTIONS.md): that 2D and 3D are named apart, so no one has to guess whether a type is
one kind's (1 to 3), that a call made on its own is a property (4), that removing (5) and looking for (6) name what they're about, and
that counts and indices say they are (7):

  1. Every public type in a package of one kind (a package whose name ends in 2d or 3d: helix.render2d, helix.render3d) ends in that
     kind, a counterpart of the other kind or not, but for those holding both kinds or neither (NEUTRAL, each with its reason).
  2. Every public type in a module named for a kind (Node3D.hx, AnimationClip3D.hx) ends in that kind, in every library: a module's
     subtypes are its kind's too (Attachment3D, Track3D).
  3. 2D code names no 3D type: a 2d package's code (its comments aside) uses nothing ending in 3D, so a type both kinds use is a neutral
     one, living outside the kinds, and a 2D program never reaches 3D through a name.
  4. No method is named onX: a call made on its own is an `onX` property (`window.onClose = save`), assigned, not passed to a method.
  5. No method is named clear: removing one or all names what goes (`files.deleteFile`, `deleteFiles`; `assets.clearCache()`).
  6. No method is named has: whether something is there names what it looks for (`saves.hasKey`, `config.hasOption`).
  7. A public field, property or parameter of a whole number (Int, or an array of them) whose doc comment calls it an index ends in
     Index, or Indices for an array, but for a mesh's vertex indices, `indices`; one whose doc comment calls it a number of things
     ("the number of", "how many") ends in Count, or Counts for an array. Read through the compiler: Haxe's XML description of every
     library on both targets (tools/gen_apidoc.py's), each member's doc comment and each parameter's @param, so a name the doc
     comment doesn't call an index or a count isn't judged. helix-ray is left out: its names are raylib's (DECISIONS 24).

Run by helix.py test. Exits 1, listing each type, when one breaks a rule. Standard library only."""
import re
import sys
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [ROOT / 'platform/src/helix', ROOT / 'log/src/helix', ROOT / 'math/src/helix', ROOT / 'geometry/src/helix', ROOT / 'formats/src/helix', ROOT / 'services/src/helix']

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
# A method named clear alone, declared in code.
CLEAR_METHOD = re.compile(r'\bfunction\s+clear\s*\(')
# A method named has alone, declared in code.
HAS_METHOD = re.compile(r'\bfunction\s+has\s*\(')


# A doc comment calling what it describes an index, or a number of things (rule 7).
# A number of bytes is a size, named for its unit (`capacityBytes`, `usedBytes`), not a count; "by index" says how an array is laid out,
# not that it holds indices.
INDEX_DOC = re.compile(r'(?<!by )\b(index|indices)\b(?! buffer)', re.I)
COUNT_DOC = re.compile(r'^(gets (or sets )?)?((the )?((largest|smallest) )?number of|how many)\b(?! bytes)', re.I)
# Packages left out of rule 7, each with its reason.
UNJUDGED = {'helix.ray': "raylib's names (DECISIONS 24)"}


def whole_numbers(node):
    """'one' for an Int (or Null<Int>), 'many' for an array of them, else None: a member's or a parameter's type in Haxe's XML."""
    while node is not None and node.get('path') == 'Null' and len(node):
        node = node[0]
    if node is None:
        return None
    if node.get('path') == 'Int':
        return 'one'
    if node.get('path') == 'Array' and len(node) and whole_numbers(node[0]) == 'one':
        return 'many'
    return None


def named_wrongly(name, kind, doc):
    """Why a whole number's name breaks rule 7, by what its doc comment calls it, or None."""
    doc = ' '.join(doc.split())
    if COUNT_DOC.search(doc):
        if kind == 'one' and not name.endswith('Count'):
            return 'a count: name it ...Count'
        if kind == 'many' and not name.endswith('Counts'):
            return 'counts: name it ...Counts'
    elif INDEX_DOC.search(doc):
        if kind == 'one' and not name.endswith('Index'):
            return 'an index: name it ...Index'
        if kind == 'many' and not name.endswith('Indices') and name != 'indices':
            return 'indices: name it ...Indices'
    return None


def params(doc):
    """{name: text} of a doc comment's @param tags."""
    return {m.group(1): m.group(2) for m in re.finditer(r'@param\s+(\w+)\s+(.*?)(?=@\w+|$)', doc, re.S)}


def describe(target):
    """Haxe's XML description of every library on one target, as tools/gen_apidoc.py makes it."""
    import gen_apidoc
    gen_apidoc.describe(target)
    return gen_apidoc.OUT / 'xml' / f'{target}.xml'


def counts_and_indices():
    """Rule 7's problems, over both targets' descriptions."""
    found = set()
    with ThreadPoolExecutor(2) as pool:
        files = list(pool.map(describe, ('js', 'cpp')))
    for file in files:
        for node in ET.parse(file).getroot():
            path = node.get('path') or ''
            if not path.startswith('helix.') or '._' in path or node.get('private') == '1' or any(path.startswith(p + '.') for p in UNJUDGED):
                continue
            for member in node:
                if member.tag in ('haxe_doc', 'meta') or (member.get('public') != '1' and member.tag != 'new') or hidden(member):
                    continue
                kids = [c for c in member if c.tag not in ('haxe_doc', 'meta', 'overloads')]
                if not kids:
                    continue
                doc = member.findtext('haxe_doc') or ''
                if kids[0].tag == 'f':
                    names = [n.lstrip('?') for n in kids[0].get('a', '').split(':')] if kids[0].get('a') else []
                    tags = params(doc)
                    for name, kind in zip(names, (whole_numbers(k) for k in kids[0])):
                        why = kind and named_wrongly(name, kind, tags.get(name, ''))
                        if why:
                            found.add(f'{path}.{member.tag}: its parameter {name} is {why}')
                elif member.get('set') != 'method':
                    kind = whole_numbers(kids[0])
                    why = kind and named_wrongly(member.tag, kind, doc.strip().split('\n\n')[0])
                    if why:
                        found.add(f'{path}.{member.tag} is {why}')
    return sorted(found)


def hidden(node):
    """Whether a type or member is marked @:noCompletion, a library's own."""
    meta = node.find('meta')
    return meta is not None and any(m.get('n') == ':noCompletion' for m in meta)


def problems():
    found = counts_and_indices()
    for path in sorted(p for source in SOURCES for p in source.rglob('*.hx') if p.parent.name.endswith('2d')):
        code = COMMENT.sub('', path.read_text(encoding='utf-8'))
        for name in sorted(set(THREE_D.findall(code))):
            found.append(f'{path.relative_to(ROOT).as_posix()}: names {name}, a 3D type, in 2D code: use or make a neutral type')
    for path in sorted(p for source in SOURCES for p in source.rglob('*.hx')):
        relative = path.relative_to(ROOT).as_posix()
        code = COMMENT.sub('', path.read_text(encoding='utf-8'))
        for name in ON_METHOD.findall(code):
            found.append(f'{relative}: {name} is a method: a call made on its own is a property, var {name}:Null<...->Void>')
        if CLEAR_METHOD.search(code):
            found.append(f'{relative}: a method is named clear: name what it empties, clearX()')
        if HAS_METHOD.search(code):
            found.append(f'{relative}: a method is named has: name what it looks for, hasX()')
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
