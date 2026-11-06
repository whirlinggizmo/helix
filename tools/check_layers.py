#!/usr/bin/env python3
"""Checks the layers: each library names only itself and the libraries it's built on, and owns its package roots alone; no library
reaches an engine.

  1. A Haxe file in a library refers to no package of a library it isn't built on (its USES), by import or by a qualified name in its code
     (comments and strings aside): not one above it, nor one beside it (math and log know nothing of each other, nor log and platform, nor formats and log).
  2. A library's files declare only packages under the roots it owns; no other library declares a package under them.
  A library's tests and examples (TESTS) are held to rule 1 too, as they build with that library alone.
  3. In helix-platform, contracts don't know each other (docs/PLATFORM.md): a contract's files are its interface, the types in
     helix.platform it reaches, and its adapters (adapters/<contract>/); none names another contract's. Anything else (adapters/shared/, a
     type no contract reaches) is common, and may name at most one contract, whose it then is. A shared interface (SHARED) passes
     between contracts, extended (IPollable) or given by one and taken by another (IDecodedImage): no contract's, and naming no other
     type in helix.platform. A device (DEVICES) is built over another contract,
     the events: it and its adapters may name that contract's types and adapters too, and nothing else of another's.
  4. A library (libs/<name>) knows no consumer: nothing in it reaches an engine (engines/<name>), which may own the loop and keep
     statics. Beyond rule 1's packages, its build files and code (comments aside) name no engine's haxelib and no path into engines/.
     Every haxelib.json under libs/ and engines/ is a layer here, named as LAYERS names it and depending only on what it's built on.

LAYERS lists the libraries, then the engines, bottom to top, each with its directory, the package roots it owns and the libraries it's
built on; a helix package no library owns is a violation wherever it's named. Exits 1 on any violation. Standard library only.

    python3 tools/check_layers.py"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Bottom to top, libraries (libs/) then engines (engines/): (its haxelib, its source directory, the package roots it owns, the libraries
# below it that it's built on).
LAYERS = [
    ('helix-math', 'libs/math/src', ['helix.math'], []),
    ('helix-geometry', 'libs/geometry/src', ['helix.geometry'], ['helix-math']),
    ('helix-log', 'libs/log/src', ['helix.log'], []),
    ('helix-formats', 'libs/formats/src', ['helix.formats'], ['helix-math']),
    ('helix-platform', 'libs/platform/src', ['helix.platform'], ['helix-formats', 'helix-geometry', 'helix-math']),
    ('helix-services', 'libs/services/src', ['helix.services'], ['helix-platform', 'helix-formats', 'helix-geometry', 'helix-math', 'helix-log']),
    ('helix-render', 'libs/render/src', ['helix.render'], ['helix-services', 'helix-platform', 'helix-formats', 'helix-geometry', 'helix-math', 'helix-log']),
    ('helix-raylib', 'engines/raylib/src', ['helix.raylib'], ['helix-render', 'helix-services', 'helix-platform', 'helix-formats', 'helix-geometry', 'helix-math', 'helix-log']),
]
# Each library's tests and examples, held to its layer too: they build with that library alone.
TESTS = {'helix-math': ['libs/math/tests'], 'helix-geometry': ['libs/geometry/tests'], 'helix-log': ['libs/log/tests'], 'helix-formats': ['libs/formats/tests'], 'helix-platform': ['libs/platform/tests', 'libs/platform/examples'],
         'helix-services': ['libs/services/tests'], 'helix-render': ['libs/render/tests', 'libs/render/examples'], 'helix-raylib': ['engines/raylib/examples']}
# The interfaces in helix.platform shared between contracts (rule 3): IPollable, the poll a program calls each frame, and IDecodedImage,
# an image the decoder gives for the graphics to upload.
SHARED = {'IPollable', 'IDecodedImage'}
# The contracts built over another (rule 3): each device's adapters add their events to the events adapter of their API.
DEVICES = {'keyboard': 'events', 'mouse': 'events', 'touch': 'events', 'gamepads': 'events', 'tilt': 'events'}

PACKAGE = re.compile(r'^package\s+([\w.]+)\s*;', re.M)
REFERENCE = re.compile(r'\bhelix(?:\.[a-z_]\w*)+')


def code(text):
    """text with comments and string contents blanked."""
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.S)
    text = re.sub(r'//[^\n]*', '', text)
    return re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '""', text)


def owner(name):
    """The index in LAYERS of the library owning package or type path name: None for no helix package, -1 for a helix package no
    library owns."""
    if name != 'helix' and not name.startswith('helix.'):
        return None
    for index, (_, _, roots, _) in enumerate(LAYERS):
        if any(name == r or name.startswith(r + '.') for r in roots):
            return index
    return -1


def contracts():
    """Violations of rule 3 in libs/platform/src/helix/platform."""
    base = ROOT / 'libs/platform/src/helix/platform'
    top = {p.stem: p for p in base.glob('*.hx')}
    texts = {p: code(p.read_text(encoding='utf-8')) for p in base.rglob('*.hx')}

    def named(path):
        """The files in helix.platform that path names: types, adapter directories (as a contract's name) and shared files."""
        text = texts[path]
        found = {top[n] for n in re.findall(r'\bhelix\.platform\.([A-Z]\w*)', text) if n in top}
        if path.parent == base:
            found |= {top[n] for n in top if re.search(r'\b' + n + r'\b', text)}
        found |= {c for c in re.findall(r'\bhelix\.platform\.adapters\.(\w+)\.', text) if c != 'shared'}
        for sub, name in re.findall(r'\bhelix\.platform\.adapters\.shared\.((?:[a-z]\w*\.)*)([A-Z]\w*)', text):
            shared = base / 'adapters/shared' / sub.replace('.', '/') / (name + '.hx')
            if shared.exists():
                found.add(shared)
        return found - {path}

    owner = {}
    for name, path in top.items():
        if re.fullmatch(r'I[A-Z]\w*', name) and name not in SHARED:
            contract, todo = name[1:].lower(), [path]
            while todo:
                for t in named(todo.pop()):
                    if isinstance(t, Path) and t.parent == base and t not in owner and t.stem not in SHARED:
                        owner[t] = contract
                        todo.append(t)
            owner[path] = contract
    for path in texts:
        parts = path.relative_to(base).parts
        if parts[0] == 'adapters' and parts[1] != 'shared':
            owner[path] = parts[1]

    known = {}

    def knows(item):
        """The contracts item belongs to or, if common, names."""
        if isinstance(item, str):
            return {item}
        if item in owner:
            return {owner[item]}
        if item not in known:
            known[item] = set()
            known[item] = set().union(*(knows(t) for t in named(item)))
        return known[item]

    violations = []
    for path in sorted(texts):
        where = path.relative_to(ROOT)
        if path.parent == base and path.stem in SHARED:
            if named(path):
                violations.append(f'{where}: shared, but names {", ".join(sorted(t if isinstance(t, str) else t.stem for t in named(path)))}')
        elif path in owner:
            for t in sorted(named(path), key=str):
                others = knows(t) - {owner[path], DEVICES.get(owner[path])}
                if others:
                    violations.append(f'{where}: {owner[path]} names {'adapters/' + t if isinstance(t, str) else t.stem}, {", ".join(sorted(others))}\'s')
        elif len(knows(path)) > 1:
            violations.append(f'{where}: common to contracts, but names {", ".join(sorted(knows(path)))}')
    return violations


def engine(index):
    """Whether LAYERS[index] is an engine (engines/), not a library (libs/)."""
    return LAYERS[index][1].startswith('engines/')


# A library's files that a build reads (rule 4), and the comments in each kind, left out.
BUILD_FILES = {'.hx': r'/\*.*?\*/|//[^\n]*', '.hxml': r'#[^\n]*', '.json': None, '.xml': r'<!--.*?-->', '.txt': r'#[^\n]*',
               '.c': r'/\*.*?\*/|//[^\n]*', '.h': r'/\*.*?\*/|//[^\n]*', '.html': r'<!--.*?-->'}


def reaches():
    """Violations of rule 4: a library that reaches an engine, and a haxelib.json that isn't the layer LAYERS says."""
    violations = []
    engines = [name for i, (name, _, _, _) in enumerate(LAYERS) if engine(i)]
    homes = {Path(directory).parent: (name, uses) for name, directory, _, uses in LAYERS}
    for found in sorted(ROOT.glob('libs/*/haxelib.json')) + sorted(ROOT.glob('engines/*/haxelib.json')):
        home = found.parent.relative_to(ROOT)
        if home not in homes:
            violations.append(f'{home.as_posix()}: a library or engine LAYERS doesn\'t list')
            continue
        name, uses = homes[home]
        described = json.loads(found.read_text(encoding='utf-8'))
        if described.get('name') != name:
            violations.append(f'{home.as_posix()}/haxelib.json: named {described.get("name")}, not {name}')
        for dependency in described.get('dependencies', {}):
            if dependency not in uses:
                violations.append(f'{home.as_posix()}/haxelib.json: {name} depends on {dependency}, which it isn\'t built on')
    if not engines:
        return violations
    named = re.compile(r'\bengines/|(?<![\w-])(?:' + '|'.join(map(re.escape, engines)) + r')(?![\w-])')
    # The files under libs/ a build could read: tracked, or new and not ignored (build output is ignored). A copy that isn't a checkout
    # (remote_windows' holds just those files) is read whole.
    if (ROOT / '.git').exists():
        listed = subprocess.run(['git', 'ls-files', '-co', '--exclude-standard', '-z', 'libs'], cwd=ROOT, capture_output=True, check=True)
        relatives = [n for n in listed.stdout.decode().split('\0') if n]
    else:
        relatives = [p.relative_to(ROOT).as_posix() for p in (ROOT / 'libs').rglob('*')]
    for relative in sorted(relatives):
        path = ROOT / relative
        if path.suffix not in BUILD_FILES or '/vendor/' in relative or not path.is_file():
            continue
        text = path.read_text(encoding='utf-8', errors='replace')
        if BUILD_FILES[path.suffix]:
            text = re.sub(BUILD_FILES[path.suffix], lambda m: '\n' * m.group(0).count('\n'), text, flags=re.S)
        for number, line in enumerate(text.split('\n'), 1):
            for match in named.finditer(line):
                violations.append(f'{relative}:{number}: names {match.group(0)}, ' + ('a path into the engines' if match.group(0) == 'engines/' else 'an engine\'s haxelib') + ': a library reaches no engine')
    return violations


def main():
    import cli
    cli.parser(__doc__).parse_args()
    violations = []
    for index, (library, directory, _, uses) in enumerate(LAYERS):
        allowed = {index} | {i for i, layer in enumerate(LAYERS) if layer[0] in uses}
        tests = sorted(p for d in TESTS.get(library, []) for p in (ROOT / d).rglob('*.hx'))
        for path in sorted((ROOT / directory).rglob('*.hx')) + tests:
            text = path.read_text(encoding='utf-8')
            declared = PACKAGE.search(text)
            if declared and path not in tests and owner(declared.group(1)) != index:
                whose = LAYERS[owner(declared.group(1))][0] + '\'s' if owner(declared.group(1)) != -1 else 'no library\'s'
                violations.append(f'{path.relative_to(ROOT)}: package {declared.group(1)} is {whose}, not {library}\'s')
            for number, line in enumerate(code(text).split('\n'), 1):
                for name in REFERENCE.findall(line):
                    other = owner(name)
                    if other == -1:
                        violations.append(f'{path.relative_to(ROOT)}:{number}: {library} names {name}, which no library owns')
                    elif other is not None and other not in allowed and engine(other) and not engine(index):
                        violations.append(f'{path.relative_to(ROOT)}:{number}: {library} names {name}, in the engine {LAYERS[other][0]}: a library reaches no engine')
                    elif other is not None and other not in allowed:
                        where = 'above it' if other > index else 'which it isn\'t built on'
                        violations.append(f'{path.relative_to(ROOT)}:{number}: {library} names {name}, in {LAYERS[other][0]}, {where}')
    violations += contracts()
    violations += reaches()
    for v in violations:
        print(v)
    print(f'check_layers: {"FAILED" if violations else "ok"} ({", ".join(l for l, _, _, _ in LAYERS)}, bottom to top; no library reaching an engine)')
    return 1 if violations else 0


if __name__ == '__main__':
    sys.exit(main())
