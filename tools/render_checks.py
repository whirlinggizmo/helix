#!/usr/bin/env python3
"""Checks helix-render on the platform's real adapters: its examples (libs/render/examples/<name>) and its pixel tests (libs/render/tests/pixels),
each built from its own hxml files, run natively on a private display (Linux) on each native build it has (GL, and SDL_GPU from
build-native-gpu.hxml) and in Chromium (WebGL2), headless by default, as tools/platform_checks.py runs the platform's. An example's page is checked
against its check.json (points and the colors expected there, each within a tolerance per channel), and so is each native run's last
frame, which the example saves (`--screenshot`, libs/render/examples/Screenshot.hx);
the pixel tests draw each stage-1 area through the renderer, read their pixels back and check them themselves, on each backend. Exits 1
on any failure.

    python3 tools/render_checks.py --browser BROWSER [--native | --page] [--headless | --headed] [NAME ...]

BROWSER is a Chromium to run (Edge on Windows), or "" for Playwright's own. The names are examples' and "pixels"; they default to all of
them. --native, --page, --headless and --headed are platform_checks': the kinds run, and the display they run on."""
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

    out = ROOT / 'build/results/render' / name
    out.mkdir(parents=True, exist_ok=True)

    def screenshot(label):
        return out / f'native-{label}.png'

    def native_run(label, ran):
        if ran.returncode:
            return [f'exited {ran.returncode}\n{ran.stdout}{ran.stderr}']
        if not screenshot(label).is_file():
            return ['saved no screenshot']
        found = check_pixels(screenshot(label), expected)
        if not found:
            print(f'{name}: native {label} ran {FRAMES} frames, {len(expected["points"])} points checked', flush=True)
        return found

    def page_run(printed, screenshot):
        found = check_pixels(screenshot, expected)
        if not found:
            print(f'{name}: the page ran {FRAMES} frames, {len(expected["points"])} points checked', flush=True)
        return found

    def native_args(label):
        screenshot(label).unlink(missing_ok=True)
        return [f'--screenshot={screenshot(label)}']

    return run(name, directory, 'Main', browser, native_run, page_run, native_args=native_args)


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', required=True)
    cli.runs(parser)
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    platform_checks.HEADED = a.headed
    platform_checks.NATIVE, platform_checks.PAGE = cli.targets(a)
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
