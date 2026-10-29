#!/usr/bin/env python3
"""Checks helix-platform on the GPU with the library alone: its examples (platform/examples/<name>) and its graphics tests
(platform/tests/graphics). Each is built from its own hxml files, as a reader builds it, and run natively on a private display (Linux),
each native build it has (GL, and SDL_GPU where it has build-native-gpu.hxml), and in a headless Chromium. An example runs 60 frames and
the page's screenshot is checked against what it says it draws (its check.json: points and the colors expected there, each within a
tolerance per channel); the graphics tests check their own pixels, read back on each backend, and say how it went. Exits 1 on any
failure.

    python3 tools/platform_checks.py --browser BROWSER [NAME ...]

BROWSER is a Chromium to run, or "" for Playwright's own. The names are examples' and "graphics"; they default to all of them."""
import json
import os
import struct
import subprocess
import sys
import zlib
from contextlib import nullcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / 'platform/examples'
GRAPHICS = ROOT / 'platform/tests/graphics'
FRAMES = 60
sys.path.insert(0, str(ROOT / 'tools'))


def png_pixels(path):
    """(width, height, pixel) for an 8-bit RGB or RGBA non-interlaced PNG: pixel(x, y) is (r, g, b)."""
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', f'{path} is not a PNG'
    at, idat, header = 8, b'', None
    while at < len(data):
        length, kind = struct.unpack('>I4s', data[at:at + 8])
        body = data[at + 8:at + 8 + length]
        if kind == b'IHDR':
            header = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
        at += 12 + length
    width, height, depth, color, _, _, interlace = header
    assert depth == 8 and color in (2, 6) and interlace == 0, f'{path}: only 8-bit RGB/RGBA non-interlaced PNGs are read'
    channels = 3 if color == 2 else 4
    stride = width * channels
    raw = zlib.decompress(idat)
    rows, previous = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        kind, line = raw[start], bytearray(raw[start + 1:start + 1 + stride])
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = previous[i]
            c = previous[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + a) & 255
            elif kind == 2:
                line[i] = (line[i] + b) & 255
            elif kind == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        previous = line
    return width, height, lambda x, y: tuple(rows[y][x * channels:x * channels + 3])


def check_pixels(screenshot, expectations):
    """The problems with screenshot (a PNG) against expectations ({points: [{x, y, color: [r, g, b], tolerance}]})."""
    _, _, pixel = png_pixels(screenshot)
    problems = []
    for point in expectations['points']:
        found = pixel(point['x'], point['y'])
        tolerance = point.get('tolerance', 3)
        if any(abs(f - e) > tolerance for f, e in zip(found, point['color'])):
            problems.append(f'at {point["x"]},{point["y"]}: {list(found)}, expected {point["color"]} within {tolerance}')
    return problems


def build(directory, hxml, env):
    subprocess.run(['haxe', hxml], cwd=directory, env=env, check=True)


def run(name, directory, main, browser, native_run, page_run, native_frames=FRAMES):
    """Builds and runs one program both ways, in directory with its main class main, the page in browser: native_run(label, completed) and
    page_run(printed, screenshot) say what's wrong with each run, as a list of problems. native_frames is how many frames a native run
    lasts, which a private display doesn't pace. The problems found."""
    import pins
    from native_build import env as native_env
    env = pins.use_haxelib()
    build(directory, 'build-web.hxml', env)
    problems = []
    if sys.platform.startswith('linux'):
        import sdl3 as finder
        from private_display import private_display
        native = native_env(finder.find())
        env.update({k: native[k] for k in ('HELIX_PLATFORM', 'HXCPP_CONFIG', 'HELIX_SDL3_LIBRARY')})
        for hxml, output, label in (('build-native.hxml', 'native', 'GL'), ('build-native-gpu.hxml', 'native-gpu', 'SDL_GPU')):
            if not (directory / hxml).is_file():
                continue
            build(directory, hxml, env)
            with private_display() as display:
                ran = subprocess.run([str(directory / output / main)], cwd=directory, env=dict(display, HELIX_FRAMES=str(native_frames), SDL_AUDIO_DRIVER='dummy'), capture_output=True, text=True, encoding='utf-8', timeout=120)
            problems += [f'native {label}: {p}' for p in native_run(label, ran)]
    else:
        print(f'{name}: native runs skipped here (a private display needs Linux)', flush=True)
    out = ROOT / 'build/results/platform' / name
    out.mkdir(parents=True, exist_ok=True)
    screenshot = out / 'web.png'
    browser_env = {k: v for k, v in os.environ.items() if k not in ('VK_DRIVER_FILES', 'VK_ICD_FILENAMES')}
    ran = subprocess.run(['node', ROOT / 'tools/page_check.cjs', browser, str(directory / 'web'), f'?frames={FRAMES}', str(screenshot)], cwd=ROOT, env=browser_env, capture_output=True, text=True, encoding='utf-8')
    if ran.returncode:
        problems.append(f'browser run failed\n{ran.stdout}{ran.stderr}')
    else:
        printed = json.loads(ran.stdout)
        if printed['errors']:
            problems.append(f'page errors: {printed["errors"]}')
        else:
            problems += [f'page: {p}' for p in page_run(printed, screenshot)]
    return problems


def example(name, browser):
    """Builds and runs one example both ways; the problems found."""
    directory = EXAMPLES / name
    expected = json.loads((directory / 'check.json').read_text(encoding='utf-8'))

    def native_run(label, ran):
        if ran.returncode:
            return [f'exited {ran.returncode}\n{ran.stdout}{ran.stderr}']
        print(f'{name}: native {label} ran {FRAMES} frames', flush=True)
        return []

    def page_run(printed, screenshot):
        found = check_pixels(screenshot, expected)
        if not found:
            print(f'{name}: the page ran {FRAMES} frames, {len(expected["points"])} points checked', flush=True)
        return found

    return run(name, directory, 'Main', browser, native_run, page_run)


def graphics(browser):
    """Builds and runs the graphics tests both ways; the problems found."""

    def outcome(where, result):
        if result is None:
            return ['no result']
        if not result['passed']:
            return result['failures']
        print(f'graphics: {result["checks"]} checks passed {where}', flush=True)
        return []

    def native_run(label, ran):
        lines = [l for l in ran.stdout.splitlines() if l.startswith('{')]
        if not lines:
            return [f'exited {ran.returncode} with no result\n{ran.stdout}{ran.stderr}']
        found = outcome(f'natively on {label}', json.loads(lines[-1]))
        return found or ([f'exited {ran.returncode}\n{ran.stderr}'] if ran.returncode else [])

    return run('graphics', GRAPHICS, 'GraphicsTests', browser, native_run, lambda printed, _: outcome('in the page (WebGL2)', printed['result']))


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', required=True)
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    names = a.names or sorted(p.parent.name for p in EXAMPLES.glob('*/Main.hx')) + ['graphics']
    failed = False
    for name in names:
        for problem in (graphics(a.browser) if name == 'graphics' else example(name, a.browser)):
            failed = True
            print(f'{name}: {problem}', flush=True)
    print(f'platform checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
