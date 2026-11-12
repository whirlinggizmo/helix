#!/usr/bin/env python3
"""Checks helix-raylib against raylib's own C (engines/raylib/parity/README.md): each suite in engines/raylib/parity/<suite> runs a C reference built against the
raylib release its manifest names, its oracle (docs/DECISIONS.md 24: 6.2 where helix-raylib took a 6.2 fix, 5.5 elsewhere), and helix-raylib
doing the same.

    python3 tools/raylib_parity.py [--list] [SUITE ...]

For each suite (all by default, or the names given): raylib's release tarball for its oracle is fetched from GitHub, checked against its
sha256 here (RELEASES), and built once (make PLATFORM=PLATFORM_DESKTOP) into build/raylib/<version>/. The suite's sources are written
into build/raylib-parity/<suite>/ (a generated suite's two sides from its one list of cases, by engines/raylib/parity/shared/gen.py) with its assets,
and its C reference is built and run on a private display (tools/private_display.py), with SDL's dummy audio and no session bus.

A value suite's Haxe harness is then built for Node (js) and hxcpp (cpp), or the ones its manifest's targets name (page: the harness
in a headless Chromium, Playwright's own, muted, through tools/page_check.cjs, for what only a browser has), and run, each
printing what the reference prints, a line at a time. Each section's lines (by their first word, or as the manifest's sections say) are compared word by word: words and integers
exactly, other numbers relative to max(1, |either|, the line's scale), within the section's bar (the manifest's bars, a target's own where it names one, else its
tolerance). A pixel suite's helix-raylib program is built natively for each backend it names (gl, sdl_gpu), its shaders (the manifest's
shaders) compiled ahead of time by the same build, and run on the private display,
and its frame compared with raylib's: how many pixels differ at all, against the backend's allowance. Each section's or backend's
worst is printed beside its bar. Exits 1 on any failure.

Linux only: the C references and native programs need a private display (Xvfb, Openbox), and raylib's desktop build X11, GL and a C
compiler (cc). --list prints the suites, their oracles and what each covers, and builds nothing."""
import hashlib
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import cli  # noqa: E402

PARITY = ROOT / 'engines/raylib/parity'
OUT = ROOT / 'build/raylib-parity'
RAYLIB = ROOT / 'build/raylib'
# The releases the suites may name as their oracle, each pinned by its tarball's sha256.
RELEASES = {
    '5.5': 'aea98ecf5bc5c5e0b789a76de0083a21a70457050ea4cc2aec7566935f5e258e',
    '6.2': 'df7a13129b1bec9e73a6962efff170beba310ee6eab8f94cd000b7316b4db5ee',
}
URL = 'https://github.com/raysan5/raylib/archive/refs/tags/{}.tar.gz'
# What a C reference links besides libraylib.a: raylib's desktop build on Linux (GLFW over X11).
LINK = ['-lGL', '-lm', '-lpthread', '-ldl', '-lrt', '-lX11']
# The libraries a value harness builds with (helix-raylib itself from its source, without its program loop).
LIBRARIES = ['helix-log', 'helix-math', 'helix-geometry', 'helix-formats', 'helix-platform', 'helix-services']
TIMEOUT = 300
# The targets a value suite's harness runs on, unless its manifest names others (targets): a suite whose functions need what one target
# lacks (the native font rasterizer) runs on the other alone, and one needing a browser (Web Audio's decoder) names page, the harness
# built for the browser and run in a headless Chromium, its lines the page's result (window.helixResult).
TARGETS = ['js', 'cpp']
# The SDL3 a native build links (tools/sdl3.py), found once.
SDL3 = None


def suites():
    """Every suite's manifest, by name."""
    found = {}
    for path in sorted(PARITY.glob('*/manifest.json')):
        found[path.parent.name] = json.loads(path.read_text(encoding='utf-8'))
    return found


def raylib(version):
    """raylib's source for a release, its libraylib.a built: fetched, checked and built the first time."""
    if version not in RELEASES:
        raise SystemExit(f'raylib_parity: raylib {version} has no pinned tarball (RELEASES)')
    home = RAYLIB / version
    source = home / f'raylib-{version}'
    library = source / 'src/libraylib.a'
    if library.is_file():
        return source
    home.mkdir(parents=True, exist_ok=True)
    tarball = home / f'raylib-{version}.tar.gz'
    if not tarball.is_file() or hashlib.sha256(tarball.read_bytes()).hexdigest() != RELEASES[version]:
        print(f'raylib {version}: fetching {URL.format(version)}', flush=True)
        with urllib.request.urlopen(URL.format(version), timeout=120) as response:
            data = response.read()
        found = hashlib.sha256(data).hexdigest()
        if found != RELEASES[version]:
            raise SystemExit(f'raylib_parity: raylib {version}\'s tarball has sha256 {found}, not the pinned {RELEASES[version]}')
        tarball.write_bytes(data)
    if source.exists():
        shutil.rmtree(source)
    with tarfile.open(tarball) as archive:
        archive.extractall(home, filter='data')
    print(f'raylib {version}: building libraylib.a', flush=True)
    made = subprocess.run(['make', '-C', str(source / 'src'), 'PLATFORM=PLATFORM_DESKTOP', f'-j{os.cpu_count() or 4}'], capture_output=True,
                          text=True)
    if made.returncode or not library.is_file():
        raise SystemExit(f'raylib_parity: raylib {version}\'s build failed\n{made.stdout[-3000:]}{made.stderr[-3000:]}')
    return source


def stage(name, manifest, source, out):
    """Writes a suite's sources into out/src and its assets into out; returns the C reference's and the Haxe main's paths."""
    import importlib.util
    sys.dont_write_bytecode = True  # the suites' modules are read where they are, leaving nothing beside them
    suite = PARITY / name
    src = out / 'src'
    if src.exists():
        shutil.rmtree(src)
    src.mkdir(parents=True)
    pixels = manifest['kind'] == 'pixels'
    main = manifest.get('main', 'Main')
    if manifest.get('generated'):
        spec = importlib.util.spec_from_file_location('parity_gen', PARITY / 'shared/gen.py')
        gen = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gen)
        reference, _ = gen.generate(suite, src, ('scene' if pixels else 'ref') + '.c.in', main + '.hx.in')
    else:
        reference = src / manifest['reference']
        for file in [manifest['reference']] + manifest.get('harness', []):
            shutil.copy2(suite / file, src / file)
    for target, origin in manifest.get('assets', {}).items():
        destination = out / target
        destination.parent.mkdir(parents=True, exist_ok=True)
        if origin.startswith('raylib:'):
            shutil.copy2(source / origin[len('raylib:'):], destination)
        elif origin.endswith('.py'):
            subprocess.run([sys.executable, str(suite / origin), str(destination)], check=True)
        else:
            shutil.copy2((suite / origin).resolve(), destination)
    return reference, main


def build_reference(manifest, reference, source, out):
    """Builds the C reference into out/ref, linked with raylib's library unless the manifest says it's built alone."""
    command = ['cc', str(reference), '-o', str(out / 'ref'), '-I', str(source / 'src'), '-I', str(PARITY / 'shared')]
    if manifest.get('link', True):
        command += [str(source / 'src/libraylib.a')] + LINK
    else:
        command += ['-lm']
    built = subprocess.run(command, capture_output=True, text=True)
    if built.returncode:
        raise Failure(f'the C reference didn\'t build\n{built.stderr[-3000:]}')


def compiled_shaders(manifest):
    """The build's lines compiling each of the manifest's shaders (its shaders: [vertex, fragment, compiled], each a path in the suite's
    output or null for raylib's default stage) into the file LoadCompiledShaderAsync loads, as a program's build does."""
    def quoted(path):return 'null' if path is None else json.dumps(path)
    return [a for vs, fs, out in manifest.get('shaders', [])
            for a in ('--macro', f'helix.raylib.Raylib.CompileShaderFile({quoted(vs)}, {quoted(fs)}, {quoted(out)})')]


class Failure(Exception):
    """A suite that couldn't be run to the end."""


def haxe(arguments, env, cwd=ROOT):
    built = subprocess.run(['haxe'] + arguments, cwd=cwd, env=env, capture_output=True, text=True)
    if built.returncode:
        raise Failure(f'haxe {" ".join(arguments[-4:])} failed\n{built.stdout[-3000:]}{built.stderr[-3000:]}')


def run(command, display, cwd, extra=None, what='a run'):
    env = dict(display, SDL_AUDIO_DRIVER='dummy', **(extra or {}))
    for key in ('DBUS_SESSION_BUS_ADDRESS', 'WAYLAND_DISPLAY', 'XDG_RUNTIME_DIR'):
        env.pop(key, None)
    try:
        ran = subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        raise Failure(f'{what} still running after {TIMEOUT} s')
    if ran.returncode:
        raise Failure(f'{what} exited {ran.returncode}\n{ran.stdout[-2000:]}{ran.stderr[-2000:]}')
    return ran


# Comparing a value suite's outputs.

INTEGER = re.compile(r'^-?\d+$')
HEX = re.compile(r'^[0-9A-Fa-f]{16}$')


def number(token, hex_bits):
    """token as a float, or None for a word. NaN and infinities in C's spelling and Haxe's both read."""
    if hex_bits and HEX.match(token):
        return struct.unpack('>d', bytes.fromhex(token))[0]
    try:
        return float(token)
    except ValueError:
        return None


def sections(path, manifest):
    """A value output's lines by section, in order: a line's first word, or the manifest's pattern's group of it, after the last header
    line (a first word in its headers) where it names some. A scale line (NAME scale SCALE CLASS) sets what the lines after it are
    measured against, and puts CLASS after their section's name; scale lines are a section of their own. Each line comes with its scale."""
    spec = manifest.get('sections', {})
    pattern = re.compile(spec['pattern']) if 'pattern' in spec else None
    headers = set(spec.get('headers', []))
    found, header, scale, kind = {}, '', 1.0, ''
    for line in path.read_text(encoding='utf-8').splitlines():
        tokens = line.split()
        if not tokens:
            continue
        if len(tokens) == 4 and tokens[1] == 'scale':
            scale, kind = float(tokens[2]), ' ' + tokens[3]
            found.setdefault('scale', []).append((tokens, 1.0))
            continue
        if tokens[0] in headers:
            header = ' '.join(tokens[:2]) + ' '
        key = tokens[0]
        if pattern:
            matched = pattern.match(key)
            key = matched.group(1) if matched else key
        found.setdefault(header + key + kind, []).append((tokens, scale))
    return found


def compare(reference, other, manifest):
    """{section: (worst difference, numbers non-finite against another, problem or None)} of other's output against reference's. A
    difference is relative to max(1, |either|, the line's scale)."""
    hex_bits = manifest.get('hex', False)
    a, b = sections(reference, manifest), sections(other, manifest)
    result = {}
    for key in list(a) + [k for k in b if k not in a]:
        if key not in a or key not in b:
            result[key] = (math.inf, 0, 'only in ' + ('helix-raylib\'s' if key not in a else 'raylib\'s'))
            continue
        x, y = a[key], b[key]
        if len(x) != len(y):
            result[key] = (math.inf, 0, f'{len(x)} lines against {len(y)}')
            continue
        worst, nonfinite, problem = 0.0, 0, None
        for i, ((p, scale), (q, _)) in enumerate(zip(x, y)):
            if len(p) != len(q):
                problem = problem or f'line {i + 1}: {len(p)} words against {len(q)}: {" ".join(p)[:120]} | {" ".join(q)[:120]}'
                continue
            for s, t in zip(p, q):
                u, v = number(s, hex_bits), number(t, hex_bits)
                if u is None or v is None:
                    if s != t:
                        problem = problem or f'line {i + 1}: {s} against {t}'
                    continue
                if math.isnan(u) or math.isnan(v) or math.isinf(u) or math.isinf(v):
                    if not (u == v or (math.isnan(u) and math.isnan(v))):
                        nonfinite += 1
                    continue
                if not hex_bits and INTEGER.match(s) and INTEGER.match(t):
                    if u != v:
                        problem = problem or f'line {i + 1}: {s} against {t}: {" ".join(p)[:120]}'
                    continue
                worst = max(worst, abs(u - v) / max(1.0, abs(u), abs(v), scale))
        result[key] = (worst, nonfinite, problem)
    return result


def bar(manifest, key, target):
    """(the worst difference allowed, the non-finite numbers allowed) in a section on a target: its own bar in the manifest's bars (the
    target's, where the bar names one: {"worst": 0, "page": 1e-4}), else its tolerance (the target's, where tolerance names each) and
    none."""
    tolerance = manifest['tolerance']
    if isinstance(tolerance, dict):
        tolerance = tolerance[target]
    own = manifest.get('bars', {}).get(key)
    if own is None:
        return tolerance, 0
    if isinstance(own, dict):
        return own.get(target, own.get('worst', tolerance)), own.get('nonfinite', 0)
    return own, 0

def check_values(name, manifest, main, out, display, env):
    """Builds and runs a value suite's harness for each of its targets (js and cpp, unless its manifest's targets say fewer) and compares
    each with ref.txt; returns the problems."""
    targets = manifest.get('targets', TARGETS)
    ran = run([str(out / 'ref')], display, out, what='the C reference')
    (out / 'ref.txt').write_text(ran.stdout, encoding='utf-8')
    base = sum((['-lib', lib] for lib in LIBRARIES), []) + ['-cp', 'engines/raylib/src', '--macro', 'helix.raylib.internal.Metadata.register()', '-cp',
                                                            str(PARITY / 'shared'), '-cp', str(out / 'src'), '-main', main,
                                                            '-D', 'helix-company=helix', '-D', f'helix-product=parity-{name}']
    for resource, file in manifest.get('resources', {}).items():
        base += ['-resource', f'{PARITY / name / file}@{resource}']
    if 'js' in targets:
        haxe(base + ['-js', str(out / 'js/harness.js'), '-D', 'js-es=6'], env)
        run(['node', str(out / 'js/harness.js'), str(out / 'js.txt')], display, out, what='the js harness')
    if 'page' in targets:
        page = out / 'page'
        haxe(base + ['-js', str(page / 'harness.js'), '-D', 'js-es=6'], env)
        (page / 'index.html').write_text('<!doctype html><meta charset="utf-8"><script src="harness.js"></script>\n', encoding='utf-8')
        ran = run(['node', str(ROOT / 'tools/page_check.cjs'), '', str(page), '', str(page / 'page.png')], {**os.environ, **display}, ROOT,
                  what='the page harness')
        printed = json.loads(ran.stdout)
        if printed['errors'] or not isinstance(printed['result'], str):
            raise Failure(f'the page harness: {printed["errors"] or "no result"}')
        (out / 'page.txt').write_text(printed['result'], encoding='utf-8')
    if 'cpp' in targets:
        import native_build
        haxe(base + ['-cpp', str(out / 'cpp'), '-D', 'analyzer-optimize', '-D', native_build.ARCH, '-D', f'HXCPP_COMPILE_THREADS={os.cpu_count() or 4}'], env)
        run([str(out / 'cpp' / main), str(out / 'cpp.txt')], display, out, what='the cpp harness')
    results = {target: compare(out / 'ref.txt', out / f'{target}.txt', manifest) for target in targets}
    keys = []
    for target in targets:
        keys += [k for k in results[target] if k not in keys]
    width = max(len(k) for k in keys) if keys else 8
    print(f'  {"section":{width}}  ' + '  '.join(f'{target:>15}' for target in targets) + '  bar')
    problems = []
    for key in keys:
        cells, allowed = [], []
        for target in targets:
            worst_bar, nonfinite_bar = bar(manifest, key, target)
            worst, nonfinite, problem = results[target].get(key, (math.inf, 0, 'missing'))
            cells.append('differs' if problem else (f'{worst:.2e}' if worst else '0') + (f' +{nonfinite}' if nonfinite else ''))
            if problem:
                problems.append(f'{target} {key}: {problem}')
            elif worst > worst_bar:
                problems.append(f'{target} {key}: {worst:.3g} over its bar, {worst_bar:g}')
            elif nonfinite > nonfinite_bar:
                problems.append(f'{target} {key}: {nonfinite} numbers non-finite against another, over the {nonfinite_bar} allowed')
            text = f'{worst_bar:g}' + (f' +{nonfinite_bar}' if nonfinite_bar else '')
            if text not in allowed:
                allowed.append(text)
        allowed = ' / '.join(allowed)
        print(f'  {key:{width}}  ' + '  '.join(f'{cell:>15}' for cell in cells) + f'  {allowed}')
    for target in targets:
        finite = [(w, k) for k, (w, _, p) in results[target].items() if not p]
        w, k = max(finite) if finite else (0, '-')
        print(f'  worst {target}: {w:.3g} ({k})')
    return problems

def png_pixels(path):
    from platform_checks import png_pixels as read
    return read(path)


def differing(a, b):
    """(pixels that differ at all, of how many, the largest channel difference) between two PNGs of one size; None if their sizes differ."""
    wa, ha, pa = png_pixels(a)
    wb, hb, pb = png_pixels(b)
    if (wa, ha) != (wb, hb):
        return None
    count, most = 0, 0
    for y in range(ha):
        for x in range(wa):
            p, q = pa(x, y), pb(x, y)
            if p != q:
                count += 1
                most = max(most, max(abs(i - j) for i, j in zip(p, q)))
    return count, wa * ha, most


def check_pixels(name, manifest, main, out, display, env):
    """Builds and runs a pixel suite's program natively for each backend and compares its frame with raylib's; returns the problems."""
    import native_build
    if (out / 'ref.png').exists():
        (out / 'ref.png').unlink()
    run([str(out / 'ref')], display, out, what='the C reference')
    if not (out / 'ref.png').is_file():
        raise Failure('the C reference saved no ref.png')
    shutil.copy2(out / 'ref.png', out / 'raylib.png')
    problems = []
    for backend, allowance in manifest['backends'].items():
        directory = out / ('native' if backend == 'gl' else 'native-gpu')
        defines = ['-D', 'sdl_gpu'] if backend == 'sdl_gpu' else []
        haxe(['-lib', 'helix-raylib', '-cp', str(out / 'src'), '-main', main, '-D', 'helix-company=helix', '-D', f'helix-product=parity-{name}', '-dce', 'full', '-D', f'HXCPP_COMPILE_THREADS={os.cpu_count() or 4}']
             + defines + compiled_shaders(manifest) + ['-cpp', str(directory)], env, cwd=out)
        native_build.place_runtimes(directory, SDL3)
        shot = directory / 'helix.png'
        if shot.exists():
            shot.unlink()
        run([str(directory / main)], display, directory, {'HELIX_QUIT_AFTER_FRAME': str(manifest.get('frames', 5))}, what=f'the {backend} program')
        if not shot.is_file():
            problems.append(f'{backend}: saved no helix.png')
            continue
        shutil.copy2(shot, out / f'{backend}.png')
        found = differing(out / 'raylib.png', out / f'{backend}.png')
        if found is None:
            problems.append(f'{backend}: its frame is not the size of raylib\'s')
            continue
        count, total, most = found
        print(f'  {backend}: {count} of {total} pixels differ ({100 * count / total:.2f}%), by at most {most}; allowed {allowance}')
        if count > allowance:
            problems.append(f'{backend}: {count} pixels differ, over the {allowance} allowed')
    return problems


def main():
    parser = cli.parser(__doc__)
    parser.add_argument('--list', action='store_true', help='print the suites, their oracles and what each covers')
    parser.add_argument('names', nargs='*', metavar='SUITE')
    a = parser.parse_args()
    every = suites()
    unknown = [n for n in a.names if n not in every]
    if unknown:
        parser.error(f'no such suite: {", ".join(unknown)} (there are {", ".join(every)})')
    names = a.names or list(every)
    if a.list:
        for name in names:
            m = every[name]
            print(f'{name} (raylib {m["oracle"]}, {m["kind"]}): {m["covers"]}')
        return 0
    if not sys.platform.startswith('linux'):
        print('raylib_parity: Linux only (a private display runs the C references and native programs)')
        return 1
    import pins
    import native_build
    import sdl3
    from private_display import private_display
    global SDL3
    pins.use_haxelib()
    pins.check_hxcpp()
    SDL3 = sdl3.find()
    env = native_build.env(SDL3)
    sources = {v: raylib(v) for v in sorted({every[n]['oracle'] for n in names})}
    started = time.monotonic()
    failed, results = [], []
    with private_display() as display:
        for name in names:
            manifest = every[name]
            began = time.monotonic()
            print(f'{name} (raylib {manifest["oracle"]}): {manifest["covers"]}', flush=True)
            source = sources[manifest['oracle']]
            out = OUT / name
            out.mkdir(parents=True, exist_ok=True)
            try:
                reference, main_class = stage(name, manifest, source, out)
                build_reference(manifest, reference, source, out)
                check = check_pixels if manifest['kind'] == 'pixels' else check_values
                problems = check(name, manifest, main_class, out, display, env)
            except Failure as e:
                problems = [str(e)]
            for problem in problems:
                print(f'  FAILED {problem}', flush=True)
            seconds = time.monotonic() - began
            results.append((name, not problems, seconds))
            print(f'{name}: {"ok" if not problems else "FAILED"} ({seconds:.0f} s)', flush=True)
            if problems:
                failed.append(name)
    total = time.monotonic() - started
    print('raylib parity: ' + ', '.join(f'{n} {"ok" if ok else "FAILED"}' for n, ok, _ in results) + f' ({total:.0f} s)')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
