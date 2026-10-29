#!/usr/bin/env python3
"""Checks the adapter rule (docs/ARCHITECTURE.md) where it can be checked mechanically:

  1. An adapter (platform/src/helix/platform/adapters/) names nothing above the platform: no helix package but helix.platform. It
     implements a platform contract and nothing else.
  2. The platform's own code (platform/src/helix/platform/ outside adapters/, macros/ and tools/) uses no platform API (js.html,
     js.Browser, js.Syntax, js.lib, sys., cpp.) and no target conditional (#if js, cpp, sys, hl). The macros (macros/) run in the
     compiler, not on a target, and the tools (tools/: the shader compiler) in the compiler or Haxe's interpreter, never in a program.
  3. An adapter's C includes no generated shader header: programs reach adapters as data.
  4. Adapters of the same contract don't copy code: no run of DUPLICATE_LINES or more identical (normalized) lines in two adapters of
     one area. A call into an adapter's own extern bridge (its internal/*Bridge) is its own, as it reaches that adapter's C: two thin
     adapters over shared code in adapters/shared/ (the native hosts over NativeHost) differ in what they call. The same logic written
     differently isn't caught here; review is for that.
  5. Each adapter directory (adapters/<contract>/) is named for its contract: some class in it implements I<Contract>, the directory's
     name being the interface's without the I, lowercased.
  6. Each API directory (adapters/<contract>/<api>/) holds the adapter <Api><Contract>Adapter implementing I<Contract>, words the API's
     name ends with and the contract's starts with written once (webaudio + Audio is WebAudioAdapter, haxehttp + Http HaxeHttpAdapter).
  7. What an adopter of the platform writes against is visible: the adapter classes and what sits beside them in their API directory (an
     options class, an enum it takes) are not @:noCompletion, so the language server offers them. What no caller names is hidden: every type in an adapter's internal/ and in adapters/shared/ is @:noCompletion, so the
     language server doesn't offer it and the API reference leaves it out (dox and tools/gen_apidoc.py skip what's marked).
  8. An adapter class makes public only its constructor and the members of the contract it implements: anything else a caller needs
     belongs in the contract. Extern bridges (internal/) are the C's and exempt, as is an override, which the base class it extends made
     public.
  9. An adapter's constructor takes nothing, or one <Adapter>Options: a @:structInit class in its own file beside the adapter
     (docs/CONVENTIONS.md), so every value is named at the call.

Known violations, each with what removes it, would be listed in KNOWN; one that has gone must be taken off, so the list only shrinks.
Exits 1 on any other violation.

    python3 tools/check_adapters.py"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'platform/src/helix/platform'
SOURCES = [SRC]
ADAPTER_ROOTS = [root / 'adapters' for root in SOURCES]
DUPLICATE_LINES = 6

# What an adapter must not name: any helix package above the platform.
ENGINE = re.compile(r'\bhelix\.(?!platform\b)\w+')
PLATFORM = re.compile(r'\bjs\.(html|Browser|Syntax|lib)\b|\bsys\.[a-z]|\bcpp\.[A-Za-z]|#if\s+!?(js|cpp|sys|hl)\b')
# A type's declaration at a line's start (a module's private types begin with private, and are hidden already).
DECLARATION = re.compile(r'^(?:(?:extern|final|abstract|enum)\s+)*(?:class|interface|enum|typedef|abstract)\s+(\w+)')
GENERATED_HEADER = re.compile(r'#include\s+"([^"]*\.glsl\.h|shaders\.h)"')

# Known violations: (rule, file relative to platform/src/helix/platform, the step that removes it).
KNOWN = []


def code_lines(path):
    """The file's lines with comments and string contents blanked, as (number, text)."""
    text = path.read_text(encoding='utf-8')
    text = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), text, flags=re.S)
    out = []
    for number, line in enumerate(text.split('\n'), 1):
        line = re.sub(r'//.*', '', line)
        out.append((number, line))
    return out


def normalized(line):
    """A line as the duplicate check compares it: whitespace collapsed, empty and brace-only lines dropped."""
    s = ' '.join(line.split())
    return '' if s in ('', '{', '}', '};', '});', ')') or s.startswith(('import ', 'package ', '#include ')) else s


def duplicates(files):
    """Runs of DUPLICATE_LINES or more identical normalized lines in two different files: (file a, line a, file b, line b, length)."""
    seqs = {}
    for f in files:
        # A call into the adapter's own bridge (one in its API directory's internal/) is qualified by that adapter, so calls into different
        # C differ; a shared bridge's calls stay as they are.
        root = next(r for r in ADAPTER_ROOTS if f.is_relative_to(r))
        api = root / f.relative_to(root).parts[0] / f.relative_to(root).parts[1]
        own = {b.stem for b in (api / 'internal').glob('*Bridge.hx')}
        def qualify(line):
            return re.sub(r'\b(\w+Bridge)\b', lambda m: api.name + '.' + m.group(1) if m.group(1) in own else m.group(1), line)
        seqs[f] = [(n, qualify(normalized(l))) for n, l in code_lines(f) if normalized(l)]
    found = []
    names = sorted(seqs)
    for i, a in enumerate(names):
        index = {}
        for k in range(len(seqs[a]) - DUPLICATE_LINES + 1):
            index.setdefault(tuple(t for _, t in seqs[a][k:k + DUPLICATE_LINES]), k)
        for b in names[i + 1:]:
            k = 0
            while k <= len(seqs[b]) - DUPLICATE_LINES:
                key = tuple(t for _, t in seqs[b][k:k + DUPLICATE_LINES])
                if key in index:
                    found.append((a, seqs[a][index[key]][0], b, seqs[b][k][0]))
                    k += DUPLICATE_LINES
                else:
                    k += 1
    return found


def adapter_name(api, contract):
    """The lowercased class name an adapter for contract (I<Contract>, given without the I) in api/ must have: api, the contract without
    the words api already ends with, then 'adapter'."""
    words = [w.lower() for w in re.findall(r'[A-Z][a-z0-9]*', contract)]
    for k in range(len(words), 0, -1):
        if api.endswith(''.join(words[:k])):
            return api + ''.join(words[k:]) + 'adapter'
    return api + ''.join(words) + 'adapter'


def main():
    import cli
    cli.parser(__doc__).parse_args()
    violations = []
    adapters = lambda pattern: sorted(p for root in ADAPTER_ROOTS for p in root.rglob(pattern))
    areas = sorted((p for root in ADAPTER_ROOTS if root.is_dir() for p in root.iterdir() if p.is_dir() and p.name != 'shared'), key=lambda p: p.name)
    for path in adapters('*.hx'):
        for number, line in code_lines(path):
            if ENGINE.search(line):
                violations.append(('engine', path, number, line.strip()))
    for path in adapters('*.c') + adapters('*.h'):
        for number, line in enumerate(path.read_text(encoding='utf-8').split('\n'), 1):
            if GENERATED_HEADER.search(line):
                violations.append(('header', path, number, line.strip()))
    for path in sorted(p for source in SOURCES for p in source.rglob('*.hx')):
        if any(path.is_relative_to(source / d) for source in SOURCES for d in ('adapters', 'macros', 'tools')):
            continue
        for number, line in code_lines(path):
            if PLATFORM.search(line):
                violations.append(('platform', path, number, line.strip()))
    # Duplicates between adapters of one area (audio, host, ...), in Haxe and in C.
    for area in areas:
        for suffix in ('*.hx', '*.c'):
            files = sorted(area.rglob(suffix))
            for a, la, b, lb in duplicates(files):
                violations.append(('duplicate', area, la, f'{a.relative_to(ROOT)}:{la} repeats in {b.relative_to(ROOT)}:{lb}'))
    # Each area is named for a contract one of its classes implements.
    for area in areas:
        contracts = {m.lower() for f in area.rglob('*.hx') for m in re.findall(r'\bimplements\s+(?:[\w.]+\.)?I(\w+)', f.read_text(encoding='utf-8'))}
        if area.name not in contracts:
            violations.append(('name', area, 0, f'no adapter in {area.name}/ implements I<{area.name}> (it implements {sorted(contracts)})'))
    # Each API directory holds <Api><Contract>Adapter, its overlap written once.
    for area in areas:
        for api in sorted(p for p in area.iterdir() if p.is_dir() and p.name != 'internal'):
            found = []
            for f in api.glob('*.hx'):
                for name, contract in re.findall(r'\bclass\s+(\w+)[^{]*?\bimplements\s+(?:[\w.]+\.)?I(\w+)', f.read_text(encoding='utf-8')):
                    if contract.lower() == area.name:
                        found.append(name)
                        expected = adapter_name(api.name, contract)
                        if name.lower() != expected:
                            violations.append(('name', f, 0, f'{name} implements I{contract} in {area.name}/{api.name}/: expected {expected} (any case)'))
            if not found and any(api.glob('*.hx')):
                violations.append(('name', api, 0, f'no class in {area.name}/{api.name}/ implements I<{area.name}>'))
    # Rule 7: what no caller names is hidden (@:noCompletion among the metadata lines right above each type); the adapter classes are shown.
    for path in adapters('*.hx'):
        shown = 'internal' not in path.parts and 'shared' not in path.parts
        lines = path.read_text(encoding='utf-8').split('\n')
        for number, line in enumerate(lines, 1):
            found = DECLARATION.match(line)
            if not found:
                continue
            above = number - 2
            metas = []
            while above >= 0 and lines[above].startswith('@'):
                metas.append(lines[above])
                above -= 1
            hidden = any('@:noCompletion' in m for m in metas)
            if shown and hidden:
                violations.append(('hidden', path, number, f'{found.group(1)} is what an adopter constructs: take off its @:noCompletion'))
            elif not shown and not hidden:
                violations.append(('hidden', path, number, f'{found.group(1)} is platform code: mark it @:noCompletion on the line above'))
    # Rule 8: an adapter's public members are its contract's and its constructor.
    interfaces = {}
    for source in SOURCES:
        for f in source.rglob('I*.hx'):
            m = re.search(r'\binterface\s+(I\w+)[^{]*\{(.*)\n\}', f.read_text(encoding='utf-8'), re.S)
            if m:
                interfaces[m.group(1)] = set(re.findall(r'\b(?:function|var)\s+(\w+)', m.group(2)))
    for path in sorted((ROOT / 'platform/src/helix/platform/adapters').rglob('*.hx')):
        if 'internal' in path.parts:
            continue
        text = path.read_text(encoding='utf-8')
        contracts = re.findall(r'\bimplements\s+(?:[\w.]+\.)?(I\w+)', text)
        bases = re.findall(r'\bextends\s+(?:[\w.]+\.)?(\w+)', text)
        if not contracts and not bases:
            continue
        allowed = {'new'} | {name for c in contracts for name in interfaces.get(c, set())}
        for base in bases:
            for f in (ROOT / 'platform/src').rglob(base + '.hx'):
                allowed |= {name for c in re.findall(r'\bimplements\s+(?:[\w.]+\.)?(I\w+)', f.read_text(encoding='utf-8')) for name in interfaces.get(c, set())}
        for number, line in code_lines(path):
            m = re.match(r'\s*(?:@:[\w.]+(?:\([^)]*\))?\s*)*((?:override|inline|static|final)\s+)*public\s+(?:(?:override|inline|static|final)\s+)*(?:function|var|final)\s+(\w+)', line)
            if m and m.group(2) not in allowed and not re.search(r'\boverride\b', m.group(0)):
                violations.append(('public', path, number, f'{m.group(2)} is public but not in its contract: move it into the contract, or make it private'))
    # Rule 9: the constructor takes nothing, or one <Adapter>Options, a @:structInit class in its own file beside it.
    for area in areas:
        for api in sorted(p for p in area.iterdir() if p.is_dir() and p.name != 'internal'):
            for f in api.glob('*Adapter.hx'):
                name = f.stem
                body = re.search(r'^class\s+' + name + r'\b.*?(?=^(?:private\s+)?(?:class|enum|typedef|abstract)\b|\Z)', f.read_text(encoding='utf-8'), re.S | re.M)
                found = re.search(r'\bpublic\s+function\s+new\s*\(([^)]*)\)', body.group(0)) if body else None
                params = found.group(1).strip() if found else ''
                if params and not re.fullmatch(r'options\s*:\s*' + name + r'Options', params):
                    violations.append(('options', f, 0, f'{name}({params}): take nothing, or one options:{name}Options'))
                options = api / (name + 'Options.hx')
                if params and options.exists():
                    text = options.read_text(encoding='utf-8')
                    if not re.search(r'@:structInit\s*\n\s*class\s+' + name + r'Options\b', text):
                        violations.append(('options', options, 0, f'{name}Options must be a @:structInit class'))
                elif params:
                    violations.append(('options', f, 0, f'{name}Options belongs in its own file beside the adapter'))
                for other in api.glob('*Options.hx'):
                    if other.stem != name + 'Options':
                        violations.append(('options', other, 0, f'{other.stem} is beside {name}: name it {name}Options'))
    known = {(rule, SRC / file) for rule, file, _ in KNOWN}
    seen = set()
    failed = False
    for rule, path, number, text in violations:
        key = (rule, path)
        if key in known:
            seen.add(key)
            continue
        failed = True
        print(f'{path.relative_to(ROOT)}:{number}: {rule}: {text}')
    for rule, file, step in KNOWN:
        if (rule, SRC / file) not in seen:
            failed = True
            print(f'{file}: known {rule} violation is gone ({step}): take it off KNOWN in tools/check_adapters.py')
    pending = len(seen)
    print(f'check_adapters: {"FAILED" if failed else "ok"}; {pending} known violation(s) left')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
