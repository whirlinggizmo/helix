"""Build the repository's GitHub Pages site into build/site: the API reference from the doc comments (tools/gen_apidoc.py's HTML) at
api/, its tree and first page grouped into libraries and engines, with tools/site/explorer.js opening it to the page shown and filtering it by library, and an index at the root that opens it. The pages workflow (.github/workflows/pages.yml) deploys build/site.

    python3 tools/build_pages.py

Open build/site/index.html to see the site as it's served. Standard library only, beside gen_apidoc's dox."""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'build/site'
# The reference's address, as the README links its pages.
API = 'https://whirlinggizmo.github.io/helix/api/'
INDEX = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>HeliX</title>
<meta http-equiv="refresh" content="0; url=api/index.html">
</head>
<body><a href="api/index.html">HeliX API</a></body>
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


def raylib_folder(nav):
    """Raylib's place in the tree: an item that opens Raylib's page and holds its sections, its constants and each of raylib's modules
    (gen_apidoc's RAYLIB_SECTIONS), each linked to its place on the page."""
    import gen_apidoc
    raylib = re.search(r'<li data_path="helix\.raylib\.Raylib">.*?</li>', nav)
    href = '::rootPath::helix/raylib/Raylib.html'
    # nav.js holds the tree in a string quoted with ', so the titles have none.
    sections = [('constants', 'Raylib: constants and colors')] + [(module, f'Raylib: {module} functions') for module, _ in gen_apidoc.RAYLIB_SECTIONS]
    items = ''.join(f'<li data_path="helix.raylib.Raylib.{name}"><a class="treeLink" href="{href}#{name}" title="{title}">{name}</a></li>'
                    for name, title in sections)
    folder = (f'<li class="expando raylib-sections" data-page="helix/raylib/Raylib.html"><a class="nav-header" href="#" onclick="return toggleCollapsed(this)">'
              f'<i class="fa fa-folder"></i>Raylib</a><ul class="nav nav-list">{items}</ul></li>')
    return nav[:raylib.start()] + folder + nav[raylib.end():], raylib.group(0)


def raylib_sections(page):
    """Raylib's page with its sections: a contents list after its description, its constants with their groups' headings, and each of
    raylib's modules headed before its first function, with raylib.h's group headings before the first function under each. Each
    section links back to the contents."""
    import gen_apidoc
    top = '<a class="raylib-top" href="#contents">↑ Contents</a>'
    contents = ['<div class="raylib-contents"><a name="contents"></a>']
    for name, heading in gen_apidoc.RAYLIB_CONSTANTS:
        page = heading_before(page, name, f'<h4 class="raylib-group">{heading}</h4>')
    sections = [('constants and colors', 'constants', gen_apidoc.RAYLIB_CONSTANTS)]
    sections += [(module, module, headings) for module, headings in gen_apidoc.RAYLIB_SECTIONS]
    for title, anchor, headings in sections:
        groups = ''.join(f'<li><a href="#{name}">{heading}</a></li>' for name, heading in headings)
        contents.append(f'<p><a href="#{anchor}"><b>{title}</b></a></p><ul>{groups}</ul>')
    for module, headings in gen_apidoc.RAYLIB_SECTIONS:
        page = heading_before(page, headings[0][0], f'<h2 class="raylib-module"><a name="{module}"></a>{module}{top}</h2>')
        for name, heading in headings:
            page = heading_before(page, name, f'<h4 class="raylib-group">{heading}</h4>')
    contents.append('</div>')
    variables = '<h3 class="section">Static variables</h3>'
    if variables not in page:
        sys.exit('pages: Raylib\'s page has no constants')
    return page.replace(variables, ''.join(contents) + '<a name="constants"></a>' + top + variables, 1)


def heading_before(page, name, heading):
    """page with heading before the entry name."""
    anchor = f'<div class="field "><a name="{name}"></a>'
    if anchor not in page:
        sys.exit(f'pages: no entry {name} for the heading {heading}')
    return page.replace(anchor, heading + anchor, 1)


def members(api, items):
    """Every documented member of the reference's types, as items of the tree the search reads and the tree hides: each named as its
    type and itself (Raylib.ToggleFullscreen, Sphere.contains), linked to its entry, after the items given."""
    for page in sorted(api.rglob('*.html')):
        relative = page.relative_to(api).as_posix()
        if page.name == 'index.html' or not relative.startswith('helix/'):
            continue
        path = relative[:-len('.html')].replace('/', '.')
        owner, package = path.rsplit('.', 1)[1], path.rsplit('.', 1)[0]
        seen = set()
        for name in re.findall(r'<div class="field[^"]*"><a name="(\w+)"></a>', page.read_text(encoding='utf-8')):
            if name in seen or name == 'new':
                continue
            seen.add(name)
            items.append(f'<li data_path="{path}.{name}"><a class="treeLink" href="::rootPath::{relative}#{name}" title="{path}.{name}">{owner}.{name}'
                         f'<span class="pack">&nbsp;-&nbsp;{package}</span></a></li>')
    return '<li class="expando member-index"><ul class="nav nav-list">' + ''.join(items) + '</ul></li>'


def descriptions():
    """Each library's description, as the README's table gives it, by the library's name (helix-raylib)."""
    return dict(re.findall(r'^\| \[(helix-[\w-]+)\]\([^)]*\) \| ([^|]*?) \|', (ROOT / 'README.md').read_text(encoding='utf-8'), re.M))


def library_page(page, name, package):
    """A library's package page headed with the library's name, its package and its description, as the README's table gives it."""
    import html
    heading = f'<h1>{package} </h1>'
    if heading not in page:
        sys.exit(f'pages: {package}\'s page has no heading')
    return page.replace(heading, f'<h1>{name}</h1><h4><small>package {package}</small></h4><p>{html.escape(descriptions().get(name, "").rstrip("."))}.</p>', 1)


def package_page(page, package, description):
    """A package's page headed with its last name, its package and its description, as its library's README describes it."""
    import html
    heading = f'<h1>{package} </h1>'
    if heading not in page:
        sys.exit(f'pages: {package}\'s page has no heading')
    # A sentence's first letter capitalized, but a library's name (helix-tweens), and code in backticks as code.
    about = description.rstrip('.') if description.startswith('helix') else description[0].upper() + description[1:].rstrip('.')
    about = re.sub(r'`([^`]*)`', r'<code>\1</code>', html.escape(about))
    return page.replace(heading, f'<h1>{package.rsplit(".", 1)[1]}</h1><h4><small>package {package}</small></h4><p>{about}.</p>', 1)


def introduction():
    """The README's paragraphs before its first section, as HTML: links (the API's own relative to the reference), bold, code and
    quotes."""
    import html
    text = re.search(r'^# helix\n(.*?)^## ', (ROOT / 'README.md').read_text(encoding='utf-8'), re.M | re.S).group(1)
    out = []
    for paragraph in (p.strip() for p in text.split('\n\n') if p.strip()):
        quoted = paragraph.startswith('> ')
        line = html.escape(' '.join(l.removeprefix('> ').strip() for l in paragraph.split('\n')), quote=False)
        line = re.sub(r'\[([^]]*)\]\(([^)]*)\)', lambda m: f'<a href="{m.group(2).removeprefix(API)}">{m.group(1)}</a>', line)
        line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', line)
        line = re.sub(r'`([^`]*)`', r'<code>\1</code>', line)
        out.append(f'<blockquote><p>{line}</p></blockquote>' if quoted else f'<p>{line}</p>')
    return out


def overview(page):
    """The reference's first page as the README lays the libraries out: Libraries, then Engines, each library bottom to top
    (tools/check_layers.py), named, linked to its package's page and described as the README's table describes it."""
    import check_layers
    import html
    described = descriptions()
    body = ['<h1>HeliX</h1>'] + introduction()
    for title, directory in (('Libraries', 'libs/'), ('Engines', 'engines/')):
        body += [f'<h2>{title}</h2>', '<table class="table table-condensed"><tbody>']
        for name, source, roots, _ in check_layers.LAYERS:
            if source.startswith(directory):
                href = roots[0].replace('.', '/') + '/index.html'
                body.append(f'<tr class="package"><td style="width:200px;"><i class="fa fa-folder-o"></i><a href="{href}">{name}</a></td>'
                            f'<td>{html.escape(described.get(name, ""))}</td></tr>')
        body.append('</tbody></table>')
    content = re.search(r'<h1>helix </h1>.*?</table>', page, re.S)
    page = page[:content.start()] + ''.join(body) + page[content.end():]
    return page.replace('<title>helix - HeliX API</title>', '<title>HeliX API</title>', 1)


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
    import check_layers
    for name, _, roots, _ in check_layers.LAYERS:
        page = SITE / 'api' / roots[0].replace('.', '/') / 'index.html'
        page.write_text(library_page(page.read_text(encoding='utf-8'), name, roots[0]), encoding='utf-8')
    # A library's other packages, as its README's table of them describes each (helix.raylib.extras).
    for _, source, roots, _ in check_layers.LAYERS:
        readme = (ROOT / source).parent / 'README.md'
        for package, description in re.findall(r'^\| `(helix(?:\.\w+)+)` \| ([^|]*?) \|$', readme.read_text(encoding='utf-8'), re.M):
            page = SITE / 'api' / package.replace('.', '/') / 'index.html'
            if package not in roots and page.exists():
                page.write_text(package_page(page.read_text(encoding='utf-8'), package, description), encoding='utf-8')
    nav = SITE / 'api/nav.js'
    # Raylib's own item is the search's, as its place in the tree is its sections.
    tree, raylib = raylib_folder(grouped(nav.read_text(encoding='utf-8')))
    content = re.search(r"var navContent='(.*)';", tree, re.S)
    nav.write_text(tree[:content.end(1) - len('</ul>')] + members(SITE / 'api', [raylib]) + tree[content.end(1) - len('</ul>'):], encoding='utf-8')
    page = SITE / 'api/helix/raylib/Raylib.html'
    page.write_text(raylib_sections(page.read_text(encoding='utf-8')), encoding='utf-8')
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
