#!/usr/bin/env python3
"""Checks helix-services (or, with --library raylib, helix-raylib) on the platform's real adapters: its examples (libs/services/examples/<name>, or
engines/raylib/examples/<name>), each built from its own hxml files, run
natively on a private display (Linux, SDL3's dummy audio driver) and in a headless Chromium, as tools/platform_checks.py runs the
platform's. Each says in its check.json what its native run prints and what its page shows (points and the colors expected there, each
within a tolerance per channel), and, where it waits on time, how many frames a native run lasts (nativeFrames, 60 by default), as the
private display doesn't pace them: a frame there takes about a quarter of a millisecond. A native run's data and cache directories are
under build/results/<library>/<name>/, never the user's own (XDG_DATA_HOME and XDG_CACHE_HOME; APPDATA and LOCALAPPDATA on Windows).
Exits 1 on any failure.

    python3 tools/services_checks.py --browser BROWSER [--desktop] [--library services|raylib] [NAME ...]

BROWSER is a Chromium to run (Edge on Windows), or "" for Playwright's own. The names are examples'; they default to all of them.
--desktop runs the native programs on this machine's own desktop, as platform_checks' does."""
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
        ran_frames = min(frames, platform_checks.PACED_FRAMES) if platform_checks.DESKTOP else frames
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
    parser.add_argument('--desktop', action='store_true', help="run natively on this machine's own desktop, not a private display")
    parser.add_argument('--library', choices=['services', 'raylib'], default='services', help='whose examples: services (default) or raylib')
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    global LIBRARY, EXAMPLES
    LIBRARY = a.library
    EXAMPLES = pins.LIBRARIES['helix-' + a.library] / 'examples'
    platform_checks.DESKTOP = a.desktop
    names = a.names or sorted(p.parent.name for p in EXAMPLES.glob('*/Main.hx'))
    failed = False
    for name in names:
        for problem in example(name, a.browser):
            failed = True
            print(f'{name}: {problem}', flush=True)
    print(f'{LIBRARY} checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
