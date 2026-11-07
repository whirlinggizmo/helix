"""Build the repository's GitHub Pages site into build/site: the API reference from the doc comments (tools/gen_apidoc.py's HTML) at
api/, with tools/site/explorer.js opening its tree to the page shown, and an index at the root that opens it. The pages workflow (.github/workflows/pages.yml) deploys build/site.

    python3 tools/pages.py

Open build/site/index.html to see the site as it's served. Standard library only, beside gen_apidoc's dox."""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'build/site'
INDEX = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>helix</title>
<meta http-equiv="refresh" content="0; url=api/index.html">
</head>
<body><a href="api/index.html">helix API</a></body>
</html>
'''


def main():
    import cli
    cli.parser(__doc__).parse_args()
    import pins
    pins.check_hxcpp()
    import gen_apidoc
    gen_apidoc.generate()
    if SITE.exists():
        shutil.rmtree(SITE)
    shutil.copytree(gen_apidoc.OUT, SITE / 'api', ignore=shutil.ignore_patterns('xml', 'unused*'))
    # Each page loads explorer.js after dox's index.js, from the same root.
    shutil.copy(ROOT / 'tools/site/explorer.js', SITE / 'api')
    for page in (SITE / 'api').rglob('*.html'):
        text = page.read_text(encoding='utf-8')
        script = re.search(r'<script src="([^"]*)index\.js"></script>', text)
        if script:
            page.write_text(text.replace(script.group(0), script.group(0) + f'<script src="{script.group(1)}explorer.js"></script>', 1), encoding='utf-8')
    (SITE / 'index.html').write_text(INDEX, encoding='utf-8')
    print('pages:', SITE / 'index.html')


if __name__ == '__main__':
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    main()
