"""Build the repository's GitHub Pages site into build/site: the API reference from the doc comments (tools/gen_apidoc.py's HTML) at
api/, its tree and first page grouped into libraries and engines, with tools/site/explorer.js opening it to the page shown, and an index at the root that opens it. The pages workflow (.github/workflows/pages.yml) deploys build/site.

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


def top_items(html):
    """The items of a nav list's own level, each <li> with what it holds."""
    items, depth, start = [], 0, 0
    for tag in re.finditer(r'<li\b|</li>', html):
        if tag.group(0) == '<li':
            if depth == 0:
                start = tag.start()
            depth += 1
        else:
            depth -= 1
            if depth == 0:
                items.append(html[start:tag.end()])
    return items


def grouped(nav):
    """dox's tree (nav.js) as the README lays the libraries out: Libraries, then Engines, each library bottom to top
    (tools/check_layers.py) and under its own name (helix-services), holding its packages."""
    import check_layers
    content = re.search(r"var navContent='(.*)';", nav, re.S)
    by_package = {}
    for item in top_items(content.group(1)[len('<ul class="nav nav-list">'):-len('</ul>')]):
        by_package[re.search(r'class="expando package-(\w+)"', item).group(1)] = item
    groups = []
    for title, directory in (('Libraries', 'libs/'), ('Engines', 'engines/')):
        items = []
        for name, source, roots, _ in check_layers.LAYERS:
            if source.startswith(directory):
                package = roots[0].split('.')[1]
                items.append(re.sub(r'(</i>)' + package + '(</a>)', r'\g<1>' + name + r'\g<2>', by_package.pop(package), count=1))
        groups.append(f'<li class="expando"><a class="nav-header" href="#" onclick="return toggleCollapsed(this)"><i class="fa fa-folder"></i>{title}</a>'
                      f'<ul class="nav nav-list">{"".join(items)}</ul></li>')
    if by_package:
        sys.exit('pages: packages no layer owns: ' + ', '.join(sorted(by_package)))
    return nav[:content.start(1)] + '<ul class="nav nav-list">' + ''.join(groups) + '</ul>' + nav[content.end(1):]


def overview(page):
    """The reference's first page as the README lays the libraries out: Libraries, then Engines, each library bottom to top
    (tools/check_layers.py), named, linked to its package's page and described as the README's table describes it."""
    import check_layers
    import html
    described = dict(re.findall(r'^\| \[(helix-[\w-]+)\]\([^)]*\) \| ([^|]*?) \|', (ROOT / 'README.md').read_text(encoding='utf-8'), re.M))
    body = ['<h1>helix</h1>']
    for title, directory in (('Libraries', 'libs/'), ('Engines', 'engines/')):
        body += [f'<h2>{title}</h2>', '<table class="table table-condensed"><tbody>']
        for name, source, roots, _ in check_layers.LAYERS:
            if source.startswith(directory):
                href = roots[0].replace('.', '/') + '/index.html'
                body.append(f'<tr class="package"><td style="width:200px;"><i class="fa fa-folder-o"></i><a href="{href}">{name}</a></td>'
                            f'<td>{html.escape(described.get(name, ""))}</td></tr>')
        body.append('</tbody></table>')
    content = re.search(r'<h1>helix </h1>.*?</table>', page, re.S)
    return page[:content.start()] + ''.join(body) + page[content.end():]


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
    first = SITE / 'api/index.html'
    first.write_text(overview(first.read_text(encoding='utf-8')), encoding='utf-8')
    nav = SITE / 'api/nav.js'
    nav.write_text(grouped(nav.read_text(encoding='utf-8')), encoding='utf-8')
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
