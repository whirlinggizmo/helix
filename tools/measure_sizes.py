#!/usr/bin/env python3
"""Web sizes, measured (GOALS.md, 1): each library's ladder of programs (<library>/tests/sizes/), each rung adding one thing to the one
before and constructing only what it uses, so a rung's increment is what its feature costs; built for the browser as a release (-dce
full, the analyzer's optimizations; a haxelib path holding this checkout's libraries), in docs/benchmarks.md; and a check against the
committed baseline, docs/benchmarks.json. A library adds its ladder to LADDERS as it moves.

    python3 tools/measure_sizes.py [--write] [--check]

For each rung: its JavaScript raw, gzip -9 and brotli -q 11 (when the brotli tool is there); what the rung adds over the one before; and
where its bytes come from, by package from the build's source map, with Haxe's own per-class metadata (class names, links, enum tables:
the lines the source map gives no source) counted apart. The JavaScript is as the build writes it, unminified: what a game ships with Haxe
alone (Terser, when a build runs it, takes some 15% of the gzipped size more).

  --write  write docs/benchmarks.json (the baseline: every number, and the Haxe and commit measured) and docs/benchmarks.md (the tables)
  --check  measure and compare with the baseline: a rung more than TOLERANCE larger (gzip) fails; one smaller says to --write a new
           baseline. helix.py test runs it.

Standard library only."""
import argparse
import collections
import gzip
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
# Each library's ladder: its programs' directory and how a rung is built.
LADDERS = {
    'platform': (ROOT / 'platform/tests/sizes', ['-lib', 'helix-platform']),
    'services': (ROOT / 'services/tests/sizes', ['-lib', 'helix-services']),
}
LIBRARIES = {'helix-platform': ROOT / 'platform', 'helix-log': ROOT / 'log', 'helix-math': ROOT / 'math', 'helix-geometry': ROOT / 'geometry', 'helix-formats': ROOT / 'formats', 'helix-services': ROOT / 'services'}
BASELINE = ROOT / 'docs/benchmarks.json'
TABLE = ROOT / 'docs/benchmarks.md'
OUT = ROOT / 'build/sizes'
TOLERANCE = (0.01, 1024)  # a regression is more than 1%, and more than 1 KB, of gzip
B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'


def rungs(ladder):
    """A ladder's rungs, in order: <n>-<name>/ in its directory."""
    return sorted((p for p in LADDERS[ladder][0].iterdir() if (p / 'Main.hx').is_file()), key=lambda p: int(p.name.split('-')[0]))


def build(ladder, rung, haxelib):
    """The rung built as a release for the browser; its JavaScript's path."""
    out = OUT / ladder / rung.name / 'app.js'
    out.parent.mkdir(parents=True, exist_ok=True)
    args = ['haxe'] + LADDERS[ladder][1] + ['-cp', str(rung), '-main', 'Main', '-dce', 'full', '-D', 'analyzer-optimize', '-D', 'source-map', '-js',
                                 str(out)]
    done = subprocess.run(args, cwd=rung, env=dict(os.environ, HAXELIB_PATH=str(haxelib)), capture_output=True, text=True,
                          encoding='utf-8')
    if done.returncode:
        sys.exit(f'measure_sizes: {ladder} {rung.name} failed to build:\n{done.stdout}{done.stderr}')
    return out


def brotli(data):
    """data's brotli -q 11 size, or None without the brotli tool."""
    tool = shutil.which('brotli')
    if not tool:
        return None
    return len(subprocess.run([tool, '-c', '-q', '11'], input=data, capture_output=True, check=True).stdout)


def vlq(text):
    """A source map segment's numbers."""
    out, value, shift = [], 0, 0
    for c in text:
        digit = B64.index(c)
        value += (digit & 31) << shift
        shift += 5
        if not digit & 32:
            out.append(-(value >> 1) if value & 1 else value >> 1)
            value, shift = 0, 0
    return out


def package(source):
    """The package a source file's bytes are counted under: the platform's by contract (its adapters under their contract), the services'
    by service, another library's by its name, Haxe's standard library, the program's."""
    path = source.replace('\\', '/')
    if '/services/src/helix/services/' in path:
        return 'services/' + path.split('/services/src/helix/services/', 1)[1].split('/')[0]
    if '/platform/src/helix/platform/' in path:
        parts = path.split('/platform/src/helix/platform/', 1)[1].split('/')
        return f'platform/{parts[1]}' if parts[0] == 'adapters' and len(parts) > 2 else 'platform'
    for library in LIBRARIES.values():
        if f'/{library.name}/src/helix/' in path:
            return library.name
    if '/std/' in path:
        parts = path.split('/std/', 1)[1].split('/')
        return 'std/' + (parts[0] if len(parts) > 1 and parts[0] not in ('js', '_std') else 'js' if parts[0] == 'js' else 'core')
    return 'program'


def breakdown(js, source_map):
    """Bytes by package, from the source map; what it gives no source (Haxe's class and enum metadata) as 'haxe metadata'."""
    text = js.decode('utf-8')
    lines = text.split('\n')
    sizes = collections.Counter()
    source = 0
    for index, mappings in enumerate(source_map['mappings'].split(';')):
        if index >= len(lines):
            break
        line = lines[index]
        segments, column = [], 0
        for segment in mappings.split(','):
            if not segment:
                continue
            numbers = vlq(segment)
            column += numbers[0]
            if len(numbers) > 1:
                source += numbers[1]
                segments.append((column, source))
            else:
                segments.append((column, None))
        if not segments:
            sizes['haxe metadata'] += len(line.encode()) + 1
            continue
        if segments[0][0] > 0:
            sizes['haxe metadata'] += len(line[:segments[0][0]].encode())
        for i, (start, src) in enumerate(segments):
            end = segments[i + 1][0] if i + 1 < len(segments) else len(line)
            name = package(source_map['sources'][src]) if src is not None else 'haxe metadata'
            sizes[name] += len(line[start:end].encode()) + (1 if i + 1 == len(segments) else 0)
    return dict(sizes.most_common())


def measure():
    """Every rung of every ladder measured: {ladder: {name: {adds, raw, gzip, brotli, packages}}}."""
    haxelib = Path(tempfile.mkdtemp(prefix='helix-sizes-'))
    try:
        for name, path in LIBRARIES.items():
            (haxelib / name).mkdir()
            (haxelib / name / '.dev').write_text(str(path), encoding='utf-8')
        results = {}
        for ladder in LADDERS:
            results[ladder] = {}
            for rung in rungs(ladder):
                out = build(ladder, rung, haxelib)
                js = out.read_bytes()
                source_map = json.loads(Path(str(out) + '.map').read_text(encoding='utf-8'))
                results[ladder][rung.name] = {
                    'adds': adds(rung),
                    'raw': len(js),
                    'gzip': len(gzip.compress(js, 9, mtime=0)),
                    'brotli': brotli(js),
                    'packages': breakdown(js, source_map),
                }
        return results
    finally:
        shutil.rmtree(haxelib, ignore_errors=True)


def adds(rung):
    """What the rung adds, from its first line."""
    first = (rung / 'Main.hx').read_text(encoding='utf-8').split('\n', 1)[0]
    return first.split('this one ', 1)[1].rstrip('.') if 'this one ' in first else ''


def kb(n):
    return '-' if n is None else f'{n / 1024:.1f}'


INTRODUCTIONS = {
    'platform': ('helix-platform',
                 'Programs on helix-platform alone (`platform/tests/sizes/`), each constructing only the adapters it uses and adding one to '
                 'the one before: what a feature costs is its row\'s increment, gzip; brotli in brackets. The adapters\' bytes are counted '
                 'under their contract.'),
    'services': ('helix-services',
                 'Programs on helix-services and what it sits on (`services/tests/sizes/`), each adding one service, with the platform\'s '
                 'adapters it needs, to the one before, from a window cleared each frame: what a service costs is its row\'s increment, gzip; '
                 'brotli in brackets. Each service\'s bytes are counted under its package; the adapters\' under their contract.'),
}


def render(baseline):
    """docs/benchmarks.md from the baseline."""
    out = ['# Benchmarks: web sizes', '',
           'Generated by `tools/measure_sizes.py --write` from `benchmarks.json`, the baseline CI holds to (`--check`, in `helix.py test`: a '
           'rung more than 1% and 1 KB larger, gzipped, fails). Each library has a ladder of programs on it and what it sits on, each '
           'constructing only what it uses. Every rung is a release browser build (`-dce full`, the analyzer), its JavaScript unminified, '
           'as Haxe alone writes it; sizes in KB.', '',
           f'Measured from {baseline["commit"]} with Haxe {baseline["haxe"]}.']
    for ladder, rows in baseline['ladders'].items():
        title, introduction = INTRODUCTIONS[ladder]
        out += ['', f'## {title}', '', introduction, '',
                '| rung | adds | raw | gzip (brotli) | increment |', '|---|---|---:|---:|---:|']
        before = None
        for name, row in rows.items():
            increment = '' if before is None else f'+{kb(row["gzip"] - before["gzip"])}'
            out.append(f'| {name} | {row["adds"]} | {kb(row["raw"])} | {kb(row["gzip"])} ({kb(row["brotli"])}) | {increment} |')
            before = row
        out += ['', 'Each rung\'s JavaScript by package, raw KB, from its source map; "haxe metadata" is what the map gives no source: Haxe\'s '
                'per-class and per-enum metadata (names, links, constructor tables), which grows with the classes a build links.', '']
        names = list(rows)
        packages = sorted({p for row in rows.values() for p in row['packages']},
                          key=lambda p: -max(row['packages'].get(p, 0) for row in rows.values()))
        out.append('| package | ' + ' | '.join(names) + ' |')
        out.append('|---|' + '---:|' * len(names))
        for p in packages:
            out.append(f'| {p} | ' + ' | '.join(kb(rows[n]['packages'].get(p, 0)) for n in names) + ' |')
    return '\n'.join(out) + '\n'


def haxe_version():
    return subprocess.run(['haxe', '--version'], capture_output=True, text=True).stdout.strip()


def commit():
    done = subprocess.run(['git', 'log', '-1', '--format=%h %cs'], cwd=ROOT, capture_output=True, text=True)
    return done.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--check', action='store_true')
    a = parser.parse_args()
    results = measure()
    for ladder, rows in results.items():
        for name, row in rows.items():
            print(f'{ladder:9} {name:13} raw {kb(row["raw"]):>7} KB  gzip {kb(row["gzip"]):>6} KB  brotli {kb(row["brotli"]):>6} KB')
    if a.write:
        baseline = {'commit': commit(), 'haxe': haxe_version(), 'ladders': results}
        BASELINE.write_text(json.dumps(baseline, indent=1) + '\n', encoding='utf-8')
        TABLE.write_text(render(baseline), encoding='utf-8')
        print(f'measure_sizes: wrote {BASELINE.relative_to(ROOT)} and {TABLE.relative_to(ROOT)}')
    if a.check:
        baseline = json.loads(BASELINE.read_text(encoding='utf-8'))['ladders']
        failed = False
        for ladder, name, row in ((ladder, name, row) for ladder, rows in results.items() for name, row in rows.items()):
            was = baseline.get(ladder, {}).get(name)
            name = f'{ladder} {name}'
            if was is None:
                print(f'measure_sizes: {name} has no baseline: --write one')
                failed = True
                continue
            growth = row['gzip'] - was['gzip']
            if growth > max(TOLERANCE[0] * was['gzip'], TOLERANCE[1]):
                print(f'measure_sizes: {name} grew {kb(growth)} KB gzipped ({kb(was["gzip"])} -> {kb(row["gzip"])}); '
                      'docs/benchmarks.md says where its bytes are')
                failed = True
            elif growth < -TOLERANCE[1]:
                print(f'measure_sizes: {name} shrank {kb(-growth)} KB gzipped: --write a new baseline')
        if failed:
            sys.exit(1)


if __name__ == '__main__':
    main()
