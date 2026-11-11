#!/usr/bin/env python3
"""Checks helix-raylib in a page, where only a browser answers: each page test in engines/raylib/tests/page (a main class of its own,
built with helix-raylib for the page beside an index.html holding the canvas) runs in Chromium (tools/page_check.cjs), headless or with
--headed in its window on this machine's display, and
leaves {passed, checks, failures} in window.helixResult. A test's check.json, when there is one, names points of the page's screenshot
and the colors expected there, each within a tolerance per channel, as tools/platform_checks.py checks an example's. Exits 1 on any
failure.

    python3 tools/raylib_page_checks.py [--browser BROWSER] [--headless | --headed] [TEST ...]

BROWSER is a Chromium to run, or "" (the default) for Playwright's own. The tests default to all of them."""
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / 'engines/raylib/tests/page'
OUT = ROOT / 'build/results/raylib-page'
# Whether the pages run in the browser's window on this machine's display (--headed), not headless.
HEADED = False
sys.path.insert(0, str(ROOT / 'tools'))
# The page each test runs in: its canvas, filling a white page, and the test's script.
PAGE = ('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;height:100%;background:#fff}canvas{display:block;width:100%;'
        'height:100%}</style><canvas id="canvas"></canvas><script src="app.js"></script>\n')


def run(name, browser):
    """Builds and runs one page test; the problems found."""
    import pins
    from platform_checks import check_pixels
    env = pins.use_haxelib()
    web = OUT / name
    web.mkdir(parents=True, exist_ok=True)
    (web / 'index.html').write_text(PAGE, encoding='utf-8')
    built = subprocess.run(['haxe', '-lib', 'helix-raylib', '-cp', str(TESTS), '-main', name, '-D', 'helix-company=helix', '-D', f'helix-product={name}', '-js', str(web / 'app.js'), '-D', 'js-es=6', '-D', 'helix-raylib-portable-sys'],
                           cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8')
    if built.returncode:
        return [f'build failed\n{built.stdout}{built.stderr}']
    browser_env = {k: v for k, v in os.environ.items() if k not in ('VK_DRIVER_FILES', 'VK_ICD_FILENAMES', 'DBUS_SESSION_BUS_ADDRESS')}
    screenshot = web / 'page.png'
    ran = subprocess.run(['node', str(ROOT / 'tools/page_check.cjs'), '--headed' if HEADED else '--headless', browser, str(web), '', str(screenshot)], cwd=ROOT, env=browser_env,
                         capture_output=True, text=True, encoding='utf-8')
    if ran.returncode:
        return [f'browser run failed\n{ran.stdout}{ran.stderr}']
    printed = json.loads(ran.stdout)
    if printed['errors']:
        return [f'page errors: {printed["errors"]}']
    result = printed['result']
    if result is None:
        return ['no result']
    problems = list(result['failures'])
    expected = TESTS / f'{name}.check.json'
    if expected.is_file():
        problems += check_pixels(screenshot, json.loads(expected.read_text(encoding='utf-8')))
    if not problems:
        print(f'{name}: {result["checks"]} checks passed in the page', flush=True)
    return problems


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', default='')
    cli.runs(parser, kinds=False)
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    global HEADED
    HEADED = a.headed
    names = a.names or sorted(p.stem for p in TESTS.glob('*.hx'))
    failed = False
    for name in names:
        for problem in run(name, a.browser):
            failed = True
            print(f'{name}: {problem}', flush=True)
    print(f'raylib page checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
