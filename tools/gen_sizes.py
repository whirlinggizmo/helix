#!/usr/bin/env python3
"""Web sizes, measured (GOALS.md, 1): each library's and engine's ladder of programs (libs/<library>/tests/sizes/, engines/<engine>/tests/sizes/), each rung adding one thing to the one
before and constructing only what it uses, so a rung's increment is what its feature costs; built for the browser as a release (-dce
full, the analyzer's optimizations; a haxelib path holding this checkout's libraries), in docs/benchmarks.md's web sizes; and a check
against the committed baseline, docs/sizes.json. A library adds its ladder to LADDERS as it moves.

    python3 tools/gen_sizes.py [--write] [--check]

For each rung: its JavaScript raw, gzip -9 and brotli -q 11 (when the brotli tool is there); what the rung adds over the one before; and
where its bytes come from, by package from the build's source map, with Haxe's own per-class metadata (class names, links, enum tables:
the lines the source map gives no source) counted apart. The JavaScript is as the build writes it, unminified: what a game ships with Haxe
alone (Terser, when a build runs it, takes some 15% of the gzipped size more).

  --write  write docs/sizes.json (the baseline: every number, and the Haxe and commit measured) and docs/benchmarks.md's web sizes (the
           tables, between its <!-- gen_sizes --> markers)
  --check  measure and compare with the baseline: a rung more than TOLERANCE larger (gzip) fails; one smaller says to --write a new
           baseline. And check what each rung links (links(), docs/CONVENTIONS.md "A program links only what it names"): a library
           class no rung up to it declares in its Main's @:adds, a declaration it doesn't link, run-time type inspection linked, or
           a library's @:keep fails. helix.py test runs it.

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
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
# Each library's ladder: its programs' directory and how a rung is built.
LADDERS = {
    'platform': (ROOT / 'libs/platform/tests/sizes', ['-lib', 'helix-platform']),
    'services': (ROOT / 'libs/services/tests/sizes', ['-lib', 'helix-services']),
    'render': (ROOT / 'libs/render/tests/sizes', ['-lib', 'helix-render']),
    'raylib': (ROOT / 'engines/raylib/tests/sizes', ['-lib', 'helix-raylib']),
}
sys.path.insert(0, str(ROOT / 'tools'))
from pins import LIBRARIES  # noqa: E402  the libraries' directories, by haxelib name
# The libraries' classes, by their full names' start.
LIBRARY_PREFIX = 'helix.'
# Packages a rung declares by their classes, never whole: a package would declare every class in it, so a class a later rung links
# without naming it would pass (helix-math's and helix-geometry's, which every library above reaches into, helix-render's, and
# helix-services' assets, whose sources and caches each program links only those of it constructs).
BY_CLASS = ('helix.math', 'helix.geometry', 'helix.render', 'helix.services.assets')
# Standard library classes a rung declares in @:adds as it does a library's, being large or slow enough that only what asks for them should
# link them: SHA-256, which a ManifestCache hashes with natively alone (a page uses the browser's digest), so no page links it.
WATCHED = ('haxe.crypto.Sha256',)
BASELINE = ROOT / 'docs/sizes.json'
PAGE = ROOT / 'docs/benchmarks.md'
MARKERS = ('<!-- gen_sizes -->', '<!-- /gen_sizes -->')
OUT = ROOT / 'build/sizes'
TOLERANCE = (0.01, 1024)  # a regression is more than 1%, and more than 1 KB, of gzip
B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'


def rungs(ladder):
    """A ladder's rungs, in order: <n>-<name>/ in its directory."""
    return sorted((p for p in LADDERS[ladder][0].iterdir() if (p / 'Main.hx').is_file()), key=lambda p: int(p.name.split('-')[0]))


def build(ladder, rung, haxelib):
    """The rung built as a release for the browser; its JavaScript's path. Beside it, app.xml (the build's -xml: what dead-code
    elimination kept) and kept.json (what the libraries mark @:keep, tools/haxe/Kept.hx), for the links' check."""
    out = OUT / ladder / rung.name / 'app.js'
    out.parent.mkdir(parents=True, exist_ok=True)
    kept = (out.parent / 'kept.json').as_posix()
    args = ['haxe'] + LADDERS[ladder][1] + ['-cp', str(rung), '-main', 'Main', '-D', 'helix-company=helix', '-D', f'helix-product={ladder}-{rung.name}', '-dce', 'full', '-D', 'analyzer-optimize', '-D', 'source-map', '-js',
                                 str(out), '-xml', str(out.parent / 'app.xml'), '-cp', str(ROOT / 'tools/haxe'), '--macro',
                                 f'Kept.write("{kept}", ["{LIBRARY_PREFIX}"])']
    done = subprocess.run(args, cwd=rung, env=dict(os.environ, HAXELIB_PATH=str(haxelib)), capture_output=True, text=True,
                          encoding='utf-8')
    if done.returncode:
        sys.exit(f'gen_sizes: {ladder} {rung.name} failed to build:\n{done.stdout}{done.stderr}')
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
    """The package a source file's bytes are counted under: the platform's by interface (its adapters under their interface), the services'
    by service, helix-render's by source file (its effects by package), helix-raylib's by source file (raylib's modules, R*, and its
    internals; its facade and structs as raylib), another library's by
    its name, Haxe's standard library, the program's."""
    path = source.replace('\\', '/')
    if '/src/helix/raylib/' in path:
        parts = path.split('/src/helix/raylib/', 1)[1].split('/')
        return 'raylib/' + parts[-1].removesuffix('.hx') if parts[0] in ('modules', 'internal') else 'raylib'
    if '/src/helix/render/' in path:
        parts = path.split('/src/helix/render/', 1)[1].split('/')
        return 'render/' + (parts[0] if len(parts) > 1 else parts[0].removesuffix('.hx'))
    if '/src/helix/services/' in path:
        return 'services/' + path.split('/src/helix/services/', 1)[1].split('/')[0]
    if '/src/helix/platform/' in path:
        parts = path.split('/src/helix/platform/', 1)[1].split('/')
        return f'platform/{parts[1]}' if parts[0] == 'adapters' and len(parts) > 2 else 'platform'
    for library in LIBRARIES.values():
        if f'/{library.name}/src/helix/' in path:
            return library.name
    if '/std/' in path:
        parts = path.split('/std/', 1)[1].split('/')
        return 'std/' + (parts[0] if len(parts) > 1 and parts[0] not in ('js', '_std') else 'js' if parts[0] == 'js' else 'core')
    return 'program'


def breakdown(js, source_map):
    """Bytes by package, from the source map; what it gives no source (Haxe's class and enum metadata) as 'haxe metadata'. What leads a
    line before its first segment (indentation, `var`, a field's name) is counted with the first segment that has a source."""
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
            # What leads a line before its first segment (its indentation, `var`, a declaration's name) is the code's that follows.
            first = next((src for _, src in segments if src is not None), None)
            sizes[package(source_map['sources'][first]) if first is not None else 'haxe metadata'] += len(line[:segments[0][0]].encode())
        for i, (start, src) in enumerate(segments):
            end = segments[i + 1][0] if i + 1 < len(segments) else len(line)
            name = package(source_map['sources'][src]) if src is not None else 'haxe metadata'
            sizes[name] += len(line[start:end].encode()) + (1 if i + 1 == len(segments) else 0)
    return dict(sizes.most_common())


def unit(path, module):
    """What a declaration names a library class by: its package (the names before its first capitalized one), its module or itself."""
    names = path.split('.')
    package = '.'.join(n for n in names[:next((i for i, n in enumerate(names) if n[:1].isupper() or n[:1] == '_'), len(names))])
    return {package, module, path}


def links(ladder):
    """The links' check on a ladder's rungs as built (docs/CONVENTIONS.md, "A program links only what it names"): each rung's Main
    declares, in @:adds, the library packages, modules or classes it adds to the rungs before, and the WATCHED standard library classes
    (read from its build's -xml, as the compiler has the metadata); a rung linking a library or WATCHED class that no declaration up to
    it names, a declaration naming nothing the
    rung links, a declaration naming a package of BY_CLASS whole, the standard library's run-time type inspection (Type, ValueType, haxe.rtti, js.Boot.getClass) linked, or a library's
    @:keep (tools/haxe/Kept.hx) is a problem. Interfaces, externs and abstracts' implementations aren't counted: the compiler keeps
    those of its own. Returns the problems."""
    problems, declared, reported = [], set(), set()
    for rung in rungs(ladder):
        name = f'{ladder} {rung.name}'
        root = ElementTree.parse(OUT / ladder / rung.name / 'app.xml').getroot()
        kept, adds = {}, []
        for e in root:
            path = e.get('path')
            if e.tag not in ('class', 'enum') or e.get('extern'):
                continue
            if path == 'Main':
                adds = [json.loads(v.text) for m in e.iter('m') if m.get('n') == ':adds' for v in m.findall('e')]
            elif (path.startswith(LIBRARY_PREFIX) or path in WATCHED) and not e.get('interface') and '_Impl_' not in path:
                kept[path] = unit(path, e.get('module'))
            fields = {f.tag for f in e if f.tag not in ('meta', 'haxe_doc', 'implements', 'extends')}
            if path in ('Type', 'ValueType') or path.startswith('haxe.rtti.') or path == 'js.Boot' and 'getClass' in fields:
                problems.append(f'{name} links {path}{" (" + ", ".join(sorted(fields)) + ")" if fields else ""}: run-time type inspection')
        for declaration in adds:
            package = not any(n[:1].isupper() for n in declaration.split('.'))
            if package and any(declaration == p or declaration.startswith(p + '.') for p in BY_CLASS):
                problems.append(f'{name} declares the package {declaration} in @:adds: declare its classes')
            if not any(declaration in units for units in kept.values()):
                problems.append(f'{name} declares {declaration} in @:adds, which it doesn\'t link')
        declared |= set(adds)
        for path, units in sorted(kept.items()):
            if not units & declared and path not in reported:
                problems.append(f'{name} links {path}, which no rung up to it declares in @:adds')
                reported.add(path)
        for marked in json.loads((OUT / ladder / rung.name / 'kept.json').read_text(encoding='utf-8')):
            problems.append(f'{marked} is marked @:keep, so every program typing it links it')
    return list(dict.fromkeys(problems))


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
                 'Programs on helix-platform alone (`libs/platform/tests/sizes/`), each constructing only the adapters it uses and adding one to '
                 'the one before: what a feature costs is its row\'s increment, gzip; brotli in brackets. The adapters\' bytes are counted '
                 'under their interface.'),
    'services': ('helix-services',
                 'Programs on helix-services and what it sits on (`libs/services/tests/sizes/`), each adding one service, with the platform\'s '
                 'adapters it needs, to the one before, from a window cleared each frame: what a service costs is its row\'s increment, gzip; '
                 'brotli in brackets. Each service\'s bytes are counted under its package; the adapters\' under their interface.'),
    'render': ('helix-render',
               'Programs on helix-render and what it sits on (`libs/render/tests/sizes/`), each adding one feature to the one before, from the '
               'renderer\'s frame clearing the screen: what a feature costs is its row\'s increment, gzip; brotli in brackets. Its first '
               'draw brings the batches\' shader (GLSL ES carried in the program) and helix-services\' shaders; its text the assets, the '
               'images and the fonts it loads a TrueType font through; its 3D the 3D batch, a mesh and an unlit material; its light the '
               'lights and the lit materials\' one shader, every shading, counted under `BatchLighting`, which compiles it. helix-render\'s '
               'bytes are counted by source file, or by package for `effects`.'),
    'raylib': ('helix-raylib',
            'Programs written in raylib on helix-raylib (`engines/raylib/tests/sizes/`), each adding one feature to the one before, from a window '
            'cleared each frame: what a feature costs through raylib\'s API is its row\'s increment, gzip; brotli in brackets. Against '
            'the services\' ladder this is what the familiar API costs (DECISIONS 15): helix-raylib\'s window brings its time, the screen '
            '(with the saves it keeps its state in) and the keyboard, so its first rung holds them; the rest (the assets its files load '
            'through, the image decoder, the dropped files) comes with the functions that need it (DECISIONS 30). Each rung\'s `@:adds` '
            'names what it adds. Its 3D starts with a cube made in memory (GenMeshCube, '
            'LoadModelFromMesh), drawn unlit with a camera: the 3D drawing alone, so the glTF rung after it is the reader\'s own cost. '
            'helix-raylib\'s bytes are counted by source file: raylib\'s modules (R*) and its internals, its facade and structs as raylib. '
            'The last two rungs are its high-water marks. The game is what a real game uses, one file format of each kind (a skinned, '
            'blended glTF model, PNG textures, a TTF font, WAV sounds and Ogg music, every input, a save, a shader and a render '
            'texture). The kitchen sink calls every function of `Raylib`, `Raymath`, `Rlgl`, `Raygui`, `Raylib6`, `Rlights` and `helix.raylib.extras` that compiles, written as the program '
            'builds (its `Everything.hx`), and every reader by a constant name of each extension, so nothing of helix-raylib is left out: '
            'it is the comparison point for whole-library sizes, such as an Emscripten build of raylib exporting everything.'),
}


def render(baseline):
    """docs/benchmarks.md's web sizes from the baseline: what goes between its markers."""
    out = [f'Measured from {baseline["commit"]} with Haxe {baseline["haxe"]}.']
    for ladder, rows in baseline['ladders'].items():
        title, introduction = INTRODUCTIONS[ladder]
        out += ['', f'### {title}', '', introduction, '',
                '| rung | adds | raw | gzip (brotli) | increment |', '|---|---|---:|---:|---:|']
        before = None
        for name, row in rows.items():
            increment = '' if before is None else f'+{kb(row["gzip"] - before["gzip"])}'
            out.append(f'| {name} | {row["adds"]} | {kb(row["raw"])} | {kb(row["gzip"])} ({kb(row["brotli"])}) | {increment} |')
            before = row
        out += ['', 'Each rung\'s JavaScript by package, raw KB, from its source map, a line\'s start (its indentation, a declaration\'s '
                'name) counted with the code it leads; "haxe metadata" is what the map gives no source: Haxe\'s per-class and per-enum '
                'metadata (names, links, constructor tables), which grows with the classes a build links.', '']
        names = list(rows)
        packages = sorted({p for row in rows.values() for p in row['packages']},
                          key=lambda p: -max(row['packages'].get(p, 0) for row in rows.values()))
        out.append('| package | ' + ' | '.join(names) + ' |')
        out.append('|---|' + '---:|' * len(names))
        for p in packages:
            out.append(f'| {p} | ' + ' | '.join(kb(rows[n]['packages'].get(p, 0)) for n in names) + ' |')
    return '\n'.join(out)


def write_page(baseline):
    """docs/benchmarks.md with its web sizes remade from the baseline, the rest of it kept."""
    text = PAGE.read_text(encoding='utf-8')
    start, end = MARKERS
    if start not in text or end not in text:
        sys.exit(f'gen_sizes: {PAGE.relative_to(ROOT)} has no {start} ... {end} markers')
    head, rest = text.split(start, 1)
    PAGE.write_text(head + start + '\n' + render(baseline) + '\n' + end + rest.split(end, 1)[1], encoding='utf-8')


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
        write_page(baseline)
        print(f'gen_sizes: wrote {BASELINE.relative_to(ROOT)} and {PAGE.relative_to(ROOT)}')
    if a.check:
        baseline = json.loads(BASELINE.read_text(encoding='utf-8'))['ladders']
        failed = False
        for ladder, name, row in ((ladder, name, row) for ladder, rows in results.items() for name, row in rows.items()):
            was = baseline.get(ladder, {}).get(name)
            name = f'{ladder} {name}'
            if was is None:
                print(f'gen_sizes: {name} has no baseline: --write one')
                failed = True
                continue
            growth = row['gzip'] - was['gzip']
            if growth > max(TOLERANCE[0] * was['gzip'], TOLERANCE[1]):
                print(f'gen_sizes: {name} grew {kb(growth)} KB gzipped ({kb(was["gzip"])} -> {kb(row["gzip"])}); '
                      'docs/benchmarks.md says where its bytes are')
                failed = True
            elif growth < -TOLERANCE[1]:
                print(f'gen_sizes: {name} shrank {kb(-growth)} KB gzipped: --write a new baseline')
        for problem in dict.fromkeys(p for ladder in results for p in links(ladder)):
            print(f'gen_sizes: {problem}')
            failed = True
        if failed:
            sys.exit(1)


if __name__ == '__main__':
    main()
