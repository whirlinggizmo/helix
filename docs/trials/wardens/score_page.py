#!/usr/bin/env python3
"""Scores whether a helix-raylib entrant's program works in a page unchanged (../README.md, "Scoring").

    python3 score_page.py <entrant directory>... --helix <checkout> [--query QUERY]...

Each entrant is copied to <entrant>.page (without native/, the entrant's own directory left as it was), built for JS from its own
build.hxml, less its -cpp line and its helix-raylib-native-root define, against --helix's haxelib, and served whole beside an index.html
holding the canvas. It is run in headless Chromium on the GPU (this repository's tools/page_check.cjs and Playwright) once with no query
(the title) and once with each --query (by default ?enemies=200&seed=1), each writing page-<n>.png in the copy and printing the page's
errors. A build that fails prints the compiler's messages."""
import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PAGE = ('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;height:100%;background:#000}canvas{display:block;width:100%;'
        'height:100%}</style><canvas id="canvas"></canvas><script src="app.js"></script>\n')

def build(entrant, helix, defines=(), suffix='.page'):
    """Builds an entrant's program for the page in a copy of its directory (<entrant><suffix>), its build.hxml's lines with defines
    added; the copy, or None when the build fails (its messages printed)."""
    page = entrant.parent / (entrant.name + suffix)
    if page.exists():
        shutil.rmtree(page)
    shutil.copytree(entrant, page, ignore=shutil.ignore_patterns('native'))
    lines = [line for line in (entrant / 'build.hxml').read_text(encoding='utf-8').splitlines()
             if not line.startswith('-cpp') and 'helix-raylib-native-root' not in line]
    (page / 'page.hxml').write_text('\n'.join(lines + list(defines) + ['-js app.js', '-D js-es=6']) + '\n', encoding='utf-8')
    (page / 'index.html').write_text(PAGE, encoding='utf-8')
    built = subprocess.run(['haxe', 'page.hxml'], cwd=page, env=dict(os.environ, HAXELIB_PATH=str(helix / 'build/haxelib')),
                           capture_output=True, text=True)
    print(f'{entrant.name}: page build {"failed" if built.returncode else "ok"}', flush=True)
    if built.returncode:
        print((built.stdout + built.stderr)[-3000:])
        return None
    return page


def run(page, query, shot, headed=False):
    """Runs a built page with a query, saving its screenshot, in headless Chromium or with headed in its window on the display; what
    page_check printed ({errors, result}), or None when the run failed (its output printed)."""
    env = {k: v for k, v in os.environ.items() if k not in ('VK_DRIVER_FILES', 'VK_ICD_FILENAMES', 'DBUS_SESSION_BUS_ADDRESS')}
    env['HELIX_PLAYWRIGHT'] = str(ROOT / 'build/tools/node_modules/playwright')
    ran = subprocess.run(['node', str(ROOT / 'tools/page_check.cjs'), '--headed' if headed else '--headless', '', str(page), query, str(shot)], cwd=ROOT, env=env,
                         capture_output=True, text=True, timeout=300)
    try:
        return json.loads(ran.stdout)
    except ValueError:
        print(f'  {query or "(no query)"}: the run failed ({ran.returncode})\n{ran.stdout[-1500:]}{ran.stderr[-1500:]}')
        return None


def score(entrant, helix, queries):
    """Builds and runs one entrant's page; prints what it found."""
    page = build(entrant, helix)
    if page is None:
        return
    for n, query in enumerate([''] + queries):
        shot = page / f'page-{n}.png'
        printed = run(page, query, shot)
        if printed is not None:
            print(f'  {query or "(no query)"}: errors {printed["errors"]}, {shot}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('entrants', type=Path, nargs='+')
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--query', action='append')
    args = parser.parse_args()
    for entrant in args.entrants:
        score(entrant.resolve(), args.helix.resolve(), args.query or ['?enemies=200&seed=1'])

if __name__ == '__main__':
    main()
