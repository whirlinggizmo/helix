#!/usr/bin/env python3
"""Checks helix-render on the platform's real adapters: its examples (libs/render/examples/<name>) and its pixel tests (libs/render/tests/pixels),
each built from its own hxml files, run natively on a private display (Linux) on each native build it has (GL, and SDL_GPU from
build-native-gpu.hxml) and in a headless Chromium (WebGL2), as tools/platform_checks.py runs the platform's. An example's page is checked
against its check.json (points and the colors expected there, each within a tolerance per channel) and its native runs by their exit;
the pixel tests draw each stage-1 area through the renderer, read their pixels back and check them themselves, on each backend. Exits 1
on any failure.

    python3 tools/render_checks.py --browser BROWSER [--desktop] [NAME ...]

BROWSER is a Chromium to run (Edge on Windows), or "" for Playwright's own. The names are examples' and "pixels"; they default to all of
them. --desktop runs the native programs on this machine's own desktop, as platform_checks' does."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import platform_checks
from platform_checks import FRAMES, check_pixels, run, tests

EXAMPLES = ROOT / 'libs/render/examples'
PIXELS = ROOT / 'libs/render/tests/pixels'


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


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', required=True)
    parser.add_argument('--desktop', action='store_true', help="run natively on this machine's own desktop, not a private display")
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    platform_checks.DESKTOP = a.desktop
    names = a.names or sorted(p.parent.name for p in EXAMPLES.glob('*/Main.hx')) + ['pixels']
    failed = False
    for name in names:
        if name == 'pixels':
            found = tests('pixels', PIXELS, 'PixelTests', 'WebGL2', a.browser)
        else:
            found = example(name, a.browser)
        for problem in found:
            failed = True
            print(f'{name}: {problem}', flush=True)
    print(f'render checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
