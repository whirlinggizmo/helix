#!/usr/bin/env python3
"""Checks helix-services (or, with --library raylib, helix-raylib) on the platform's real adapters: its examples (libs/services/examples/<name>, or
engines/raylib/examples/<name>), each built from its own hxml files, run
natively on a private display (Linux, SDL3's dummy audio driver) and in headless Chromium by default, as tools/platform_checks.py runs the
platform's. Each says in its check.json what its native run prints and what its page shows (points and the colors expected there, each
within a tolerance per channel), and, where it waits on time, how many frames a native run lasts (nativeFrames, 60 by default), as the
private display doesn't pace them: a frame there takes about a quarter of a millisecond. A native run's data and cache directories are
under build/results/<library>/<name>/, never the user's own (XDG_DATA_HOME and XDG_CACHE_HOME; APPDATA and LOCALAPPDATA on Windows).
Exits 1 on any failure.

    python3 tools/services_checks.py --browser BROWSER [--native | --page] [--headless | --headed] [--library services|raylib] [NAME ...]

BROWSER is a Chromium to run (Edge on Windows), or "" for Playwright's own. The names are examples'; they default to all of them.
--native, --page, --headless and --headed are platform_checks': the kinds run, and the display they run on."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import pins
import platform_checks
from platform_checks import FRAMES, check_pixels, run

LIBRARY = 'services'
EXAMPLES = ROOT / 'libs/services/examples'


def example(name, browser):
    """Builds and runs one example both ways; the problems found."""
    directory = EXAMPLES / name
    expected = json.loads((directory / 'check.json').read_text(encoding='utf-8'))
    frames = expected.get('nativeFrames', FRAMES)

    def native_run(label, ran):
        if ran.returncode:
            return [f'exited {ran.returncode}\n{ran.stdout}{ran.stderr}']
        missing = [line for line in expected.get('printed', []) if line not in ran.stdout]
        if missing:
            return [f'never printed {missing}\n{ran.stdout}{ran.stderr}']
        ran_frames = min(frames, platform_checks.PACED_FRAMES) if platform_checks.HEADED else frames
        print(f'{name}: native {label} ran {ran_frames} frames and printed what it should', flush=True)
        return []

    def page_run(printed, screenshot):
        found = check_pixels(screenshot, expected)
        if not found:
            ran = 'a second' if LIBRARY == 'raylib' else f'{FRAMES} frames'
            print(f'{name}: the page ran {ran}, {len(expected["points"])} points checked', flush=True)
        return found

    home = ROOT / 'build/results' / LIBRARY / name
    home.mkdir(parents=True, exist_ok=True)
    dirs = {'XDG_DATA_HOME': str(home / 'data'), 'XDG_CACHE_HOME': str(home / 'cache'), 'APPDATA': str(home / 'data'),
            'LOCALAPPDATA': str(home / 'cache')}
    # helix-raylib's CloseWindow clears a page's canvas, so its pages run on until the screenshot.
    return run(name, directory, 'Main', browser, native_run, page_run, frames, dirs, page_quits=LIBRARY != 'raylib')


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', required=True)
    cli.runs(parser)
    parser.add_argument('--library', choices=['services', 'raylib'], default='services', help='whose examples: services (default) or raylib')
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    global LIBRARY, EXAMPLES
    LIBRARY = a.library
    EXAMPLES = pins.LIBRARIES['helix-' + a.library] / 'examples'
    platform_checks.HEADED = a.headed
    platform_checks.NATIVE, platform_checks.PAGE = cli.targets(a)
    names = a.names or sorted(p.parent.name for p in EXAMPLES.glob('*/Main.hx'))
    failed = False
    import screen_power
    with screen_power.kept_on(a.headed):
        for name in names:
            for problem in example(name, a.browser):
                failed = True
                print(f'{name}: {problem}', flush=True)
    print(f'{LIBRARY} checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
