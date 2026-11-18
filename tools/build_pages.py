"""Build the repository's GitHub Pages site into build/site: the API reference from the doc comments (tools/gen_apidoc.py's HTML) at
api/, its tree and first page grouped into libraries and engines, with tools/site/explorer.js opening it to the page shown, and an index at the root that opens it. The pages workflow (.github/workflows/pages.yml) deploys build/site.

    python3 tools/build_pages.py

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


MODULES = 'helix.raylib.modules'


def module_pages(nav):
    """Raylib's module pages (gen_apidoc's helix.raylib.modules, a page of Raylib's functions for each of raylib's modules) as Raylib's
    own in the tree: after Raylib, in raylib's order, each named as gen_apidoc's module_label names it, and the modules folder gone."""
    import gen_apidoc
    import gen_raylib
    folder = re.search(r'<li class="expando ?"><a class="nav-header"[^>]*><i class="fa fa-folder"></i>modules</a><ul class="nav nav-list">', nav)
    whole = top_items(nav[folder.start():])[0]
    items = top_items(whole[folder.end() - folder.start():-len('</ul></li>')])
    by_name = {re.search(r'data_path="' + re.escape(MODULES) + r'\.(\w+)"', item).group(1): item for item in items}
    pages = []
    for name, _ in gen_raylib.TARGETS['Raylib.hx'][0]:
        label = gen_apidoc.module_label(name)
        item = by_name.pop(name)
        item = re.sub(r'data_path="[^"]*"', f'data_path="helix.raylib.Raylib.{label[len("Raylib: "):]}"', item, count=1)
        item = re.sub(r'title="[^"]*">\w+<span class="pack">&nbsp;-&nbsp;[\w.]+</span>', f'title="{label}">{label}', item, count=1)
        pages.append(item)
    if by_name:
        sys.exit('pages: module pages raylib has no module for: ' + ', '.join(sorted(by_name)))
    nav = nav.replace(whole, '', 1)
    raylib = re.search(r'<li data_path="helix\.raylib\.Raylib">.*?</li>', nav)
    return nav[:raylib.end()] + ''.join(pages) + nav[raylib.end():]


def module_page(page, name):
    """A raylib module page headed as Raylib's: its title and heading gen_apidoc's module_label, under the class Raylib, not a
    package."""
    import gen_apidoc
    label = gen_apidoc.module_label(name)
    page = page.replace(f'<title>{MODULES}.{name} - ', f'<title>{label} - ', 1)
    return re.sub(r'<h1><small>class</small> ' + name + r'</h1><h4><small>package <a href="([^"]*?)modules/index\.html">[\w.]+</a></small></h4>',
                  lambda m: f'<h1>{label}</h1><h4><small>functions of <a href="{m.group(1)}Raylib.html">helix.raylib.Raylib</a></small></h4>', page, count=1)


def members(api):
    """Every documented member of the reference's types, as items of the tree the search reads and the tree hides: each named as its
    type and itself (Raylib.ToggleFullscreen, Sphere.contains), linked to its entry. A raylib module page's members are Raylib's."""
    items = []
    for page in sorted(api.rglob('*.html')):
        relative = page.relative_to(api).as_posix()
        if page.name == 'index.html' or not relative.startswith('helix/'):
            continue
        path = relative[:-len('.html')].replace('/', '.')
        if path.startswith(MODULES + '.'):
            path = 'helix.raylib.Raylib'
        owner, package = path.rsplit('.', 1)[1], path.rsplit('.', 1)[0]
        seen = set()
        for name in re.findall(r'<div class="field[^"]*"><a name="(\w+)"></a>', page.read_text(encoding='utf-8')):
            if name in seen or name == 'new':
                continue
            seen.add(name)
            items.append(f'<li data_path="{path}.{name}"><a href="::rootPath::{relative}#{name}" title="{path}.{name}">{owner}.{name}'
                         f'<span class="pack">&nbsp;-&nbsp;{package}</span></a></li>')
    return '<li class="expando member-index"><ul class="nav nav-list">' + ''.join(items) + '</ul></li>'


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
    tree = module_pages(grouped(nav.read_text(encoding='utf-8')))
    content = re.search(r"var navContent='(.*)';", tree, re.S)
    nav.write_text(tree[:content.end(1) - len('</ul>')] + members(SITE / 'api') + tree[content.end(1) - len('</ul>'):], encoding='utf-8')
    for page in (SITE / 'api' / MODULES.replace('.', '/')).glob('*.html'):
        if page.name == 'index.html':
            page.unlink()
        else:
            page.write_text(module_page(page.read_text(encoding='utf-8'), page.stem), encoding='utf-8')
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
