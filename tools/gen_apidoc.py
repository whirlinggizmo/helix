"""Generate HeliX's API reference from its doc comments: as HTML with dox (pinned in dependencies.json) into build/api,
published on the examples' site at /api/; and as Markdown in docs/api, committed, so the repository carries a readable
reference without the site (README.md, the index of packages, then a file a package with each type's public members).

Haxe describes the types once per target (XML), since each target has its own adapters: the browser's (DOM, WebGL2,
Web Audio, fetch, IndexedDB) and the native ones (Sokol, SDL3, libsndfile, evdev, the filesystem). dox merges the two and
marks what only one target has; the Markdown lists the adapters in one file, by name, as platform code nobody writes a
game against. --check regenerates the Markdown in memory and fails when docs/api differs, so a change to a doc comment is
committed with its reference (helix.py test runs it)."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/api'
DOCS=ROOT/'docs/api'
# The browser's adapters, by their API's name (the folder under each contract), and its profile; every other adapter and profile is native.
BROWSER_APIS={'dom','webgl2','webaudio','fetchapi','indexeddb','canvas','download'}

def targets():
    """The packages each target's description leaves out: (the browser's, the native ones), read from the adapters' folders so a new adapter is placed by its API's name."""
    browser=[];native=[]
    for contract in sorted((ROOT/'src/helix/adapters').iterdir()):
        if not contract.is_dir():continue
        if contract.name=='shared':native.append('helix.adapters.shared');continue
        for api in sorted(contract.iterdir()):
            if api.is_dir():(browser if api.name in BROWSER_APIS else native).append(f'helix.adapters.{contract.name}.{api.name}')
    for profile in sorted((ROOT/'src/helix/profiles').glob('*.hx')):
        (browser if profile.stem.startswith('Browser') else native).append(f'helix.profiles.{profile.stem}')
    return browser,native

def describe(target,ignore):
    """Haxe's XML description of package helix for one target, leaving out the other target's adapters."""
    output=OUT/'xml'/f'{target}.xml';output.parent.mkdir(parents=True,exist_ok=True)
    macro="include('helix',true,["+",".join(f"'{p}'" for p in ignore)+"])"
    args=['haxe','-cp','src','-cp','build/generated/shaders','-cp','build/generated/fonts','--macro',macro,'-xml',str(output),'-D','doc-gen','--no-output']
    args+=['-js',str(OUT/'unused.js')] if target=='js' else ['-cpp',str(OUT/'unused-cpp')]
    subprocess.run(args,cwd=ROOT,check=True)

def short(path):
    """A type's name without its package."""
    return path.rsplit('.',1)[-1]

def package_file(path):
    """The Markdown file a package's types go in: adapters and profiles together, else the package's name after helix."""
    package=path.rsplit('.',1)[0]
    if package.startswith('helix.adapters') or package=='helix.profiles':return 'adapters.md'
    return package[len('helix.'):].replace('.','-')+'.md' if package!='helix' else 'helix.md'

def type_text(node,known):
    """A type as Haxe writes it, from the XML's type element, helix's own types by their short names (the index finds them)."""
    tag=node.tag
    if tag in ('c','x','t','e'):
        path=node.get('path');params=[type_text(c,known) for c in node]
        # A method's type parameter comes as '<method>.T': written as Haxe writes it, T.
        head,_,last=path.rpartition('.')
        method=head and '.' not in head and head[:1].islower() and head not in ('haxe','sys','js','cpp','eval','hl','helix')
        name=last if method else short(path) if path.startswith('helix.') else path
        return name+(f'<{", ".join(params)}>' if params else '')
    if tag=='d':return 'Dynamic'
    if tag=='f':
        names=node.get('a','').split(':') if node.get('a') else []
        kids=list(node);ret=type_text(kids[-1],known) if kids else 'Void'
        args=[(f'{n}:' if n else '')+type_text(k,known) for n,k in zip(names,kids[:-1])] if names and names!=[''] else [type_text(k,known) for k in kids[:-1]]
        return '('+', '.join(args)+') -> '+ret if len(args)!=1 or ':' in (args[0] if args else '') else f'{args[0]} -> {ret}'
    if tag=='a':
        return '{'+', '.join(f'{c.tag}:{type_text(list(c)[0],known)}' for c in node if len(c))+'}'
    return node.tag

def doc_text(node):
    """A doc comment's text as one paragraph."""
    d=node.find('haxe_doc')
    return ' '.join((d.text or '').split()) if d is not None else ''

def member_lines(member,known):
    """A public member as a Haxe signature and its doc, or None for a private one or the meta."""
    if member.tag in ('haxe_doc','meta') or member.get('public')!='1':return None
    name=member.tag;static='static ' if member.get('static')=='1' else ''
    kids=[c for c in member if c.tag not in ('haxe_doc','meta')]
    if not kids:return None
    t=kids[0]
    if member.get('set')=='method' and t.tag=='f':
        names=t.get('a','').split(':') if t.get('a') else [];values=(t.get('v') or '').split(':') if t.get('v') else []
        parts=list(t);ret=type_text(parts[-1],known) if parts else 'Void'
        args=[]
        for i,(n,k) in enumerate(zip(names,parts[:-1])):
            v=values[i] if i<len(values) else ''
            ty=type_text(k,known)
            # An optional argument is nullable as written; the compiler's XML wraps a typedef's in Null<> on Windows and not elsewhere.
            if n.startswith('?') and ty.startswith('Null<') and ty.endswith('>'):ty=ty[5:-1]
            args.append(f'{n}:{ty}'+(f' = {v}' if v else ''))
        sig=f'{static}function {name}({", ".join(args)})'+('' if name=='new' else f':{ret}')
    else:
        # A property's access as its source declares it: accessor is get or set, and a read-only one with a getter (null or never alike
        # from outside) reads (get, never).
        get=member.get('get','default');setter=member.get('set','default')
        get={'accessor':'get'}.get(get,get);setter={'accessor':'set'}.get(setter,setter)
        if get=='get' and setter=='null':setter='never'
        access='' if (get,setter)==('default','default') else f'({get}, {setter})'
        final_='final ' if member.get('final')=='1' else 'var '
        sig=f'{static}{final_}{name}{access}:{type_text(t,known)}'
    return sig,doc_text(member)

def markdown(xmls):
    """The Markdown files from the targets' XML descriptions merged: {relative path: text}."""
    types={}
    for file in xmls:
        for node in ET.parse(file).getroot():
            path=node.get('path')
            # Public types alone: a module's private ones have a path through the module (helix.assets._AssetService.Attempt).
            if path and path.startswith('helix.') and '._' not in path and node.get('private')!='1' and path not in types:types[path]=node
    known=set(types)
    files={};index={}
    for path in sorted(types):
        node=types[path];name=short(path);params=node.get('params','')
        header=name+(f'<{params.replace(":",", ")}>' if params else '')
        kind={'class':'class','enum':'enum','typedef':'typedef','abstract':'abstract'}[node.tag]
        lines=[f'## {header}','',f'*{kind}* in `{node.get("file","")}`','']
        doc=doc_text(node)
        if doc:lines+=[doc,'']
        file=package_file(path)
        if file=='adapters.md':
            index.setdefault(file,[]).append((path,doc));files.setdefault(file,[]).append(f'- **{header}** (`{node.get("file","")}`): {doc}' if doc else f'- **{header}** (`{node.get("file","")}`)')
            continue
        if node.tag=='class':
            # A property's accessors (get_x, set_x; an interface's are public) are the property, listed once.
            properties={c.tag for c in node if c.get('set')!='method' and c.get('get') is not None}
            members=[m for m in (member_lines(c,known) for c in node if not (c.tag[:4] in ('get_','set_') and c.tag[4:] in properties)) if m]
            members.sort(key=lambda m:0 if m[0].split('(')[0].endswith(' new') else 1)
            if members:
                lines.append('```haxe')
                for sig,_ in members:lines.append(sig)
                lines.append('```');lines.append('')
                for sig,d in members:
                    if d:lines.append(f'- `{sig.split("(")[0].split(":")[0].split()[-1]}`: {d}')
                lines.append('')
        elif node.tag=='enum':
            for c in node:
                if c.tag in ('haxe_doc','meta'):continue
                args=c.get('a','');lines.append(f'- `{c.tag}'+(f'({", ".join(a+":"+type_text(k,known) for a,k in zip(args.split(":"),c))})' if args else '')+'`'+(f': {doc_text(c)}' if doc_text(c) else ''))
            lines.append('')
        elif node.tag=='typedef':
            inner=[c for c in node if c.tag not in ('haxe_doc','meta')]
            if inner:
                if inner[0].tag=='a':
                    for f in inner[0]:
                        if len(f):lines.append(f'- `{f.tag}:{type_text(list(f)[0],known)}`'+(f': {doc_text(f)}' if doc_text(f) else ''))
                else:lines.append(f'An alias of `{type_text(inner[0],known)}`.')
                lines.append('')
        index.setdefault(file,[]).append((path,doc));files.setdefault(file,[]).append('\n'.join(lines))
    out={}
    readme=['# HeliX API reference','','Generated from the code\'s doc comments by `tools/gen_apidoc.py` (the same source as the HTML at https://whirlinggizmo.github.io/helix/api/); `python3 tools/gen_apidoc.py --check` fails when it\'s stale. A file a package, each type with its public members.','']
    for file in sorted(files):
        package='helix.adapters and helix.profiles' if file=='adapters.md' else 'helix'+('' if file=='helix.md' else '.'+file[:-3].replace('-','.'))
        names=', '.join(short(p) for p,_ in index[file]) if file!='adapters.md' else f'{len(index[file])} adapters and profiles, the platform code'
        readme.append(f'- [`{package}`]({file}): {names}')
        title=f'# {package}' if file!='adapters.md' else '# helix.adapters and helix.profiles'
        lead='' if file!='adapters.md' else '\nThe platform code: one adapter an API behind each contract, and the profiles that choose them (ARCHITECTURE.md). A game writes against the contracts, never these.\n'
        out[file]='\n'.join([title,lead]+(['[Back to the index](README.md)','']) + files[file]).rstrip('\n')+'\n'
    out['README.md']='\n'.join(readme)+'\n'
    return out

def main():
    if not (ROOT/'build/generated/shaders/shader-contract.json').is_file():sys.exit('Generate the shaders first: python3 tools/example.py app-hello build web')
    version=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['dox']
    check='--check' in sys.argv[1:]
    env=dict(os.environ,HAXELIB_PATH=str(ROOT/'build/haxelib'));(ROOT/'build/haxelib').mkdir(parents=True,exist_ok=True)
    # dox makes the HTML alone: a check (the Markdown, from Haxe's own description) needs no install.
    if not check and not (ROOT/'build/haxelib/dox'/version.replace('.',',')).is_dir():subprocess.run(['haxelib','--always','install','dox',version],env=env,check=True,stdout=subprocess.DEVNULL)
    import bake_fonts
    bake_fonts.generate()
    if OUT.exists() and not check:shutil.rmtree(OUT)
    browser,native=targets()
    describe('js',native);describe('cpp',browser)
    pages=markdown([OUT/'xml/js.xml',OUT/'xml/cpp.xml'])
    if check:
        stale=[name for name,text in pages.items() if not (DOCS/name).is_file() or (DOCS/name).read_text(encoding='utf-8')!=text]
        extra=[p.name for p in DOCS.glob('*.md') if p.name not in pages] if DOCS.is_dir() else []
        if stale or extra:
            # The first differing lines of each stale page, so a check failing on another system says what differs there.
            import difflib
            for name in stale:
                if (DOCS/name).is_file():
                    diff=list(difflib.unified_diff((DOCS/name).read_text(encoding='utf-8').splitlines(),pages[name].splitlines(),'committed '+name,'generated '+name,lineterm='',n=1))
                    print('\n'.join(diff[:40]),flush=True)
            sys.exit('gen_apidoc: docs/api is stale ('+', '.join(stale+extra)+'); run python3 tools/gen_apidoc.py and commit it')
        print('gen_apidoc: docs/api is current');return
    DOCS.mkdir(parents=True,exist_ok=True)
    for p in DOCS.glob('*.md'):
        if p.name not in pages:p.unlink()
    for name,text in pages.items():(DOCS/name).write_text(text,encoding='utf-8')
    # No source links yet: dox could link each type to its source on GitHub.
    subprocess.run(['haxelib','run','dox','-i',str(OUT/'xml'),'-o',str(OUT),'-in','^helix','--title','HeliX API',
        '-D','description','HeliX: a Haxe game framework over thin per-platform adapters.'],cwd=ROOT,env=env,check=True)
    print('API reference:',OUT/'index.html','and',DOCS)

if __name__=='__main__':main()
