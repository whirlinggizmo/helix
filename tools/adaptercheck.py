#!/usr/bin/env python3
"""Checks the adapter rule (docs/ARCHITECTURE.md) where it can be checked mechanically:

  1. An adapter (src/helix/adapters/) names no engine code: no rendering, no engine service, no generated layout or framework program,
     no shared decoder or policy. It implements a platform contract and nothing else.
  2. Engine code (src/helix/ outside adapters/ and profiles/) uses no platform API (js.html, js.Browser, js.Syntax, js.lib, sys., cpp.)
     and no target conditional (#if js, cpp, sys, hl).
  3. An adapter's C includes no generated shader header: programs reach adapters as data.
  4. Adapters of the same contract don't copy code: no run of DUPLICATE_LINES or more identical (normalized) lines in two adapters of
     one area. The same logic written differently isn't caught here; review is for that.

Known violations, each with the audit step that removes it (docs/ADAPTER_AUDIT.md), are listed in KNOWN; a known violation that has gone
must be taken off the list, so the list only shrinks. Exits 1 on any other violation.

    python3 tools/adaptercheck.py"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'src/helix'
ADAPTERS = SRC / 'adapters'
DUPLICATE_LINES = 6

# Engine code an adapter must not name.
ENGINE = re.compile(r'\bhelix\.(render2d|render3d|particles|app\.(BaseApp|Ticker)|graphics\.(Pipelines|Shader\b|Shaders|ShaderParameters|ScreenEffect|'
                    r'PostProcess|Mipmaps)|audio\.(AudioResources|AudioPlayback|AudioClip|AudioStream|Wav\b|WavStream)|assets\.AssetService|'
                    r'host\.(HostCore|Runner))\b|\b[A-Z][A-Za-z0-9]*[0-9]DLayout\b|\bGeneratedShader\b')
PLATFORM = re.compile(r'\bjs\.(html|Browser|Syntax|lib)\b|\bsys\.[a-z]|\bcpp\.[A-Za-z]|#if\s+!?(js|cpp|sys|hl)\b')
GENERATED_HEADER = re.compile(r'#include\s+"([^"]*\.glsl\.h|shaders\.h)"')

# Known violations: (rule, file relative to src/helix, the step that removes it).
KNOWN = [
    ('engine', 'adapters/audio/webaudio/WebAudioAdapter.hx', 'audio (4): WAV dispatch moves to shared code'),
    ('engine', 'adapters/audio/sokol/SokolAudioAdapter.hx', 'audio (4): WAV dispatch and the stream pump move to shared code'),
    ('duplicate', 'adapters/audio', 'audio (4)'),
]


def code_lines(path):
    """The file's lines with comments and string contents blanked, as (number, text)."""
    text = path.read_text()
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
        seqs[f] = [(n, normalized(l)) for n, l in code_lines(f) if normalized(l)]
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


def main():
    violations = []
    for path in sorted(ADAPTERS.rglob('*.hx')):
        for number, line in code_lines(path):
            if ENGINE.search(line):
                violations.append(('engine', path, number, line.strip()))
    for path in sorted(ADAPTERS.rglob('*.c')) + sorted(ADAPTERS.rglob('*.h')):
        for number, line in enumerate(path.read_text().split('\n'), 1):
            if GENERATED_HEADER.search(line):
                violations.append(('header', path, number, line.strip()))
    for path in sorted(SRC.rglob('*.hx')):
        if path.is_relative_to(ADAPTERS) or path.is_relative_to(SRC / 'profiles'):
            continue
        for number, line in code_lines(path):
            if PLATFORM.search(line):
                violations.append(('platform', path, number, line.strip()))
    # Duplicates between adapters of one area (audio, host, ...), in Haxe and in C.
    for area in sorted(p for p in ADAPTERS.iterdir() if p.is_dir() and p.name != 'internal'):
        for suffix in ('*.hx', '*.c'):
            files = sorted(area.rglob(suffix))
            for a, la, b, lb in duplicates(files):
                violations.append(('duplicate', area, la, f'{a.relative_to(SRC)}:{la} repeats in {b.relative_to(SRC)}:{lb}'))
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
            print(f'{file}: known {rule} violation is gone ({step}): take it off KNOWN in tools/adaptercheck.py')
    pending = len(seen)
    print(f'adaptercheck: {"FAILED" if failed else "ok"}; {pending} known violation(s) left, each removed by an audit step')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
