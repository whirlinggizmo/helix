"""Generate the libraries' API reference from their doc comments: as HTML with dox (pinned in dependencies.json) into build/api, and as
Markdown in each library's api/ directory, committed, so the repository carries a readable reference: api/README.md holds the
library's own package and lists the rest, a file each with its types' public members (helix.services.audio in libs/services/api/audio.md),
and the platform's adapters together in libs/platform/api/adapters.md.

The reference is what a program writes against: a type or member marked @:noCompletion is a library's own (an adapter's internals,
checked by tools/check_adapters.py), hidden from the language server and left out here as dox leaves it out. Haxe describes the code
once per target (XML), js and cpp; a library's code has no target conditional, so both must describe the same types with the same
public members, and the tool fails when they differ. The adapters are each one target's: each description holds its own target's (the
compiler says which, by the target each package types for), and the reference shows both, each marked with its target. The HTML is made from one description,
js's with cpp's adapters added, so dox has nothing to mark as one target's. Of the tools (helix.platform.tools), which run in the compiler,
it shows ShaderCompiler, whose compile a program calls: a macro, its signature from the compiler's macro context (tools/haxe/Fields.hx), as
Haxe's description types a macro's arguments as Dynamic. helix-raylib's facades (Raylib, Raymath, Rlgl and the extras modules) are laid out as tools/gen_raylib.py
says: their members under headings, and what refuses to compile listed apart. Raylib, Raymath, Rlgl and Raygui each have pages of their
own in engines/raylib/api/, Raylib's one for each of raylib's modules (core.md, shapes.md and the rest) and one for its constants. Code is read through the compiler, never as text
(docs/CONVENTIONS.md, Tools). A @:structInit class is shown as the object a program writes, each field with its default. --check regenerates the Markdown in memory and fails when a library's api/ differs, so a change to a doc comment is committed with
its reference (helix.py test runs it)."""
import json
import re
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import pins  # noqa: E402
pins.use_haxelib()
OUT=ROOT/'build/api'
# The adapters: each compiles on its own target alone, so each target's description holds its own, and the reference shows both.
ADAPTERS='helix.platform.adapters'
# What the reference says of its targets, once.

def types_for(package,target):
    """Whether a package types for a target, as the compiler says."""
    out=['-js',str(OUT/'probe.js')] if target=='js' else ['-cpp',str(OUT/'probe-cpp')]
    ran=subprocess.run(['haxe',*sum((['-lib',name] for name in pins.LIBRARIES),[]),'--macro',f"include('{package}')",'--no-output',*out],cwd=ROOT,capture_output=True,text=True)
    return ran.returncode==0

ADAPTER_TARGETS={}
# Every macro function's signature, and helix-raylib's facades' layout (tools/gen_raylib.py), read as the reference is made.
MACROS={}
LAYOUT={}

def adapter_packages(target):
    """The adapters' packages for one target: those the compiler types for it. Each types for one target alone, the browser's (js) or
    native (cpp); one that types for both or neither stops the reference."""
    if not ADAPTER_TARGETS:
        packages=[f'{ADAPTERS}.{d.parent.name}.{d.name}' for d in sorted((ROOT/'libs/platform/src/helix/platform/adapters').glob('*/*/')) if d.parent.name!='shared']
        OUT.mkdir(parents=True,exist_ok=True)
        with ThreadPoolExecutor(8) as pool:
            found=list(pool.map(lambda p:(p,types_for(p,'js'),types_for(p,'cpp')),packages))
        for package,js,cpp in found:
            if js==cpp:sys.exit(f'gen_apidoc: {package} types for {"both targets" if js else "neither target"}; an adapter is for one')
            ADAPTER_TARGETS[package]='js' if js else 'cpp'
    return [p for p,t in ADAPTER_TARGETS.items() if t==target]

def describe(target):
    """Haxe's XML description of package helix for one target, with that target's adapters."""
    output=OUT/'xml'/f'{target}.xml';output.parent.mkdir(parents=True,exist_ok=True)
    # The tools run in the compiler or Haxe's interpreter, not on a target; a program meets ShaderCompiler alone, its compile a macro.
    ignore=[ADAPTERS+'*','helix.platform.tools']
    macro="include('helix',true,["+",".join(f"'{p}'" for p in ignore)+"])"
    args=['haxe',*sum((['-lib',name] for name in pins.LIBRARIES),[]),'--macro',macro,'-xml',str(output),'-D','doc-gen','--no-output']
    args+=['helix.platform.tools.ShaderCompiler']
    for package in adapter_packages(target):args+=['--macro',f"include('{package}')"]
    args+=['-js',str(OUT/'unused.js')] if target=='js' else ['-cpp',str(OUT/'unused-cpp')]
    subprocess.run(args,cwd=ROOT,check=True)

def hidden(node):
    """Whether a type or member is marked @:noCompletion, the engine's own."""
    meta=node.find('meta')
    return meta is not None and any(m.get('n')==':noCompletion' for m in meta)

def public_types(file):
    """A target's XML description's documented types: helix's public ones not hidden, {path: node} (a module's private types have a
    path through the module, helix.asset._AssetService.Attempt)."""
    return {n.get('path'):n for n in ET.parse(file).getroot()
        if (n.get('path') or '').startswith('helix.') and '._' not in n.get('path') and n.get('private')!='1' and not hidden(n)}

def hidden_paths(file):
    """The paths of a description's hidden types: helix's marked @:noCompletion."""
    return {n.get('path') for n in ET.parse(file).getroot() if (n.get('path') or '').startswith('helix.') and hidden(n)}

def leaks(file):
    """Each shown member whose signature names a hidden type, 'Type.member: Hidden', so the reference never points at what it leaves
    out: such a member is the engine's too (hide it, or make it private), or the type isn't. An optional argument may: a game leaves it out."""
    secret=hidden_paths(file);found=[]
    def named(node):
        for e in node.iter():
            if e.get('path') in secret:yield e.get('path')
    def signature(member):
        """What a game meets of a member: its type, but for a method's optional arguments (left out, as a GPU or backend for tests)."""
        kids=[c for c in member if c.tag not in ('haxe_doc','meta')]
        if not kids:return []
        t=kids[0]
        if member.get('set')!='method' or t.tag!='f':return [t]
        names=t.get('a','').split(':') if t.get('a') else [];parts=list(t)
        return [k for n,k in zip(names,parts[:-1]) if not n.startswith('?')]+parts[-1:]
    for path,node in sorted(public_types(file).items()):
        for member in node:
            if member.tag in ('haxe_doc','meta') or member.get('public')!='1' or hidden(member):continue
            for name in sorted({n for part in signature(member) for n in named(part)}):found.append(f'{path}.{member.tag}: {name}')
    return found

def adapter(path):
    """Whether a type is an adapter's, described on its own target alone."""
    return path.startswith(ADAPTERS+'.')

def same_on_both(js,cpp):
    """Fails unless both targets describe the same documented types, each with the same public members as written; the adapters aside."""
    a={p:n for p,n in public_types(js).items() if not adapter(p)};b={p:n for p,n in public_types(cpp).items() if not adapter(p)}
    differ=[f'{p}: only on {"js" if p in a else "cpp"}' for p in sorted(set(a)^set(b))]
    for path in sorted(set(a)&set(b)):
        known=set(a)
        ma={m[:2] for m in (member_lines(c,known) for c in a[path]) if m};mb={m[:2] for m in (member_lines(c,known) for c in b[path]) if m}
        differ+=[f'{path}: {sig} only on {"js" if (sig,d) in ma else "cpp"}' for sig,d in sorted(ma^mb)]
    if differ:
        sys.exit('gen_apidoc: js and cpp describe the API differently (engine code has no target conditional):\n  '+'\n  '.join(differ))

def short(path):
    """A type's name without its package."""
    return path.rsplit('.',1)[-1]

def page_package(path):
    """The package whose page a type is on: its own, the adapters' all on one."""
    return ADAPTERS if adapter(path) else path.rsplit('.',1)[0]

def package_file(package):
    """The Markdown file a package's page is, from the checkout's root: in its library's api/ directory, README.md for the library's own
    package and the rest by their names below it (helix.services.audio is libs/services/api/audio.md)."""
    parts=package.split('.')
    return (pins.LIBRARIES['helix-'+parts[1]].relative_to(ROOT)/'api'/('README.md' if len(parts)==2 else '-'.join(parts[2:])+'.md')).as_posix()

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

TAG=re.compile(r'^\s*@(param|return|returns|throws|exception|see|since|deprecated)\s+(.*)$')

def doc_parts(node):
    """A doc comment as (summary, remarks, tags): the first paragraph, the paragraphs after it (fenced code kept as written, prose
    joined), and the Javadoc-style tags at the end, each (name, value, text); value is the parameter's name for param and throws."""
    d=node.find('haxe_doc')
    if d is None or not (d.text or '').strip():return '','',[]
    lines=[l.strip() for l in d.text.strip().split('\n')]
    tags=[];body=[]
    for line in lines:
        m=TAG.match(line)
        if m:
            name,text=m.groups();value=None
            if name in ('param','throws','exception'):
                value,_,text=text.partition(' ');text=text.strip()
            tags.append((name,value,text))
        elif tags and line:tags[-1]=(tags[-1][0],tags[-1][1],tags[-1][2]+' '+line)
        else:body.append(line)
    # Paragraphs: blank lines apart; a fenced block is one paragraph, its lines kept.
    paragraphs=[];fence=False
    for line in body:
        if line.startswith('```'):
            fence=not fence
            if fence:paragraphs.append([line])
            else:paragraphs[-1].append(line)
        elif fence:paragraphs[-1].append(line)
        elif not line:
            if paragraphs and paragraphs[-1]:paragraphs.append([])
        else:
            if not paragraphs:paragraphs.append([])
            paragraphs[-1].append(line)
    paragraphs=['\n'.join(p) if p and p[0].startswith('```') else ' '.join(p) for p in paragraphs if p]
    return (paragraphs[0] if paragraphs else ''),'\n\n'.join(paragraphs[1:]),tags

def doc_text(node):
    """A doc comment's summary, one paragraph."""
    return doc_parts(node)[0]

def tag_lines(tags):
    """The tags as Markdown list items: a parameter by name, the return as 'returns', an exception as 'throws' and its type."""
    return [f'- `{v}`: {t}' if n=='param' else f'- throws `{v}`: {t}' if n in ('throws','exception') else f'- {"returns" if n in ("return","returns") else n}: {t}' for n,v,t in tags]

def doc_lines(node,indent=''):
    """A doc comment as Markdown lines after its summary: the tags as a list, then the remarks, each line indented."""
    _,remarks,tags=doc_parts(node)
    lines=tag_lines(tags)
    if remarks:lines+=(['']+remarks.split('\n') if lines else remarks.split('\n'))
    return [indent+l if l else '' for l in lines]

def macro_signatures():
    """Every macro function's signature, {(class, name): signature}, as declared: the description gives a macro function no line and types
    its arguments as Dynamic, so the classes with a static of no line are compiled once more with tools/haxe/Fields.hx's build macro,
    which reads their fields as the compiler parsed them. Its ExprOf<T> arguments are shown as the T the program passes and its result
    as the T the program gets, a bare Expr, which gives the program nothing, as Void."""
    root=ET.parse(OUT/'xml/js.xml').getroot()
    classes=sorted(c.get('path') for c in root if c.tag=='class' and c.get('interface')!='1' and (c.get('path') or '').startswith('helix.')
                   and any(f.get('static')=='1' and f.get('set')=='method' and f.get('line') is None for f in c))
    if not classes:return {}
    fields=OUT/'xml/macro-fields.json'
    subprocess.run(['haxe',*sum((['-lib',name] for name in pins.LIBRARIES),[]),*classes,'-cp',str(ROOT/'tools/haxe'),
                    '--macro',f'Fields.write("{fields.as_posix()}", {json.dumps(classes)})','-D','doc-gen','--no-output','-js',str(OUT/'unused.js')],cwd=ROOT,check=True)
    shown=lambda t:short_types(re.sub(r'^ExprOf<(.*)>$',r'\1',t or 'Dynamic'))
    out={}
    for f in json.loads(fields.read_text(encoding='utf-8')):
        if not f['isMacro']:continue
        args=', '.join(('?' if a['optional'] and not a['value'] else '')+a['name']+':'+shown(a['type'])+(f' = {a["value"]}' if a['value'] else '') for a in f['args'])
        result='Void' if f['result'] in ('Expr','haxe.macro.Expr',None) else shown(f['result'])
        out[(f['owner'],f['name'])]=f'{"static " if f["isStatic"] else ""}macro function {f["name"]}({args}):{result}'
    return out

def short_types(text):
    """A type's text with helix's types by their short names, as the reference writes them."""
    return re.sub(r'\bhelix(?:\.\w+)*\.([A-Z]\w*)',r'\1',text)

def member_lines(member,known,instance=()):
    """A public member as a Haxe signature and its doc, or None for a private one or the meta; instance names an abstract's properties,
    statics of its implementation whose accessors take the value."""
    # An abstract's constructor, its implementation's _new, which the compiler hides itself: shown as the new a program calls.
    constructor=member.tag=='_new' and bool(instance)
    if member.tag in ('haxe_doc','meta') or member.get('public')!='1' or hidden(member) and not constructor:return None
    name='new' if constructor else member.tag;static='' if constructor else 'static ' if member.get('static')=='1' else ''
    kids=[c for c in member if c.tag not in ('haxe_doc','meta')]
    if not kids:return None
    t=kids[0]
    if name in instance:static=''
    # An inline method is a variable of a function type: written as the method it is.
    if (member.get('set')=='method' or member.get('get')=='inline') and t.tag=='f':
        names=t.get('a','').split(':') if t.get('a') else [];values=(t.get('v') or '').split(':') if t.get('v') else []
        parts=list(t);ret=type_text(parts[-1],known) if parts else 'Void'
        # An abstract's method is a static of its implementation taking the value first, as this: written as the game calls it.
        if names[:1]==['this']:names,parts,values,static=names[1:],parts[1:],values[1:],''
        args=[]
        for i,(n,k) in enumerate(zip(names,parts[:-1])):
            v=values[i] if i<len(values) else ''
            ty=type_text(k,known)
            # An optional argument is nullable as written; the compiler's XML wraps a typedef's in Null<> on Windows and not elsewhere.
            if n.startswith('?') and ty.startswith('Null<') and ty.endswith('>'):ty=ty[5:-1]
            # A rest argument as the program writes it, not the Rest<T> it compiles to.
            if ty.startswith('haxe.Rest<') and ty.endswith('>'):n,ty='...'+n,ty[10:-1]
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
        # A constant: inline, read-only.
        if (get,setter)==('inline','null'):final_,access='inline var ',''
        sig=f'{static}{final_}{name}{access}:{type_text(t,known)}'
    return sig,doc_text(member),member

def member_block(members):
    """Members as one block of signatures, then each one's doc."""
    lines=['```haxe']+[sig for sig,_,_ in members]+['```','']
    for sig,d,node_ in members:
        if d:
            lines.append(f'- `{sig.split("(")[0].split(":")[0].split()[-1]}`: {d}')
            lines+=doc_lines(node_,'  ')
    return lines+['']

def sectioned(members,layout=None):
    """A class's members: in one block, or, when helix-raylib's generator lays the class out (tools/gen_raylib.py, a facade), a block under
    each heading, and the members that refuse to compile as lists of names, those helix-raylib won't have apart from those it hasn't yet."""
    if not layout:return member_block(members)
    named,refused=layout
    skipped={n for kind in refused.values() for n in kind}
    groups={};order=[]
    for sig,d,n in members:
        if n.tag in skipped:continue
        key=named.get(n.tag,'')
        if key not in groups:groups[key]=[];order.append(key)
        groups[key].append((sig,d,n))
    lines=[]
    for key in order:lines+=([f'### {key}',''] if key else [])+member_block(groups[key])
    if refused['unsupported']:
        lines+=['### Not supported in helix-raylib','','Each of these is raylib\'s name (or emscripten\'s, which raylib\'s web programs call), and a call to it doesn\'t compile, saying why and what to use instead.','',
                ', '.join(f'`{n}`' for n in refused['unsupported'])+'.','']
    if refused['unimplemented']:
        lines+=['### Not in helix-raylib yet','','Each of these is raylib\'s name, and a call to it doesn\'t compile, saying so.','',
                ', '.join(f'`{n}`' for n in refused['unimplemented'])+'.','']
    return lines

# helix-raylib's facades at its package's top (Raylib, Raymath, Rlgl, Raygui) are long, so each is a page of its own beside the library's
# README.md, which keeps its description and links it; Raylib's is a page for each of raylib's modules (rcore's is core.md) and one for its
# constants. By page, from the checkout's root.
PAGES={}

def paged(path,members):
    """A facade's members on pages of their own (PAGES); returns what its library's README.md shows of them: the pages, and what refuses
    to compile."""
    named,refused=LAYOUT[path]
    folder=Path(package_file(path.rsplit('.',1)[0])).parent
    groups=[['',[]]]
    for line in sectioned(members,(named,{'unsupported':[],'unimplemented':[]})):
        if line.startswith('### '):groups.append([line[4:],[]])
        else:groups[-1][1].append(line)
    pages={}
    for title,lines in groups:
        if not lines:continue
        module=re.match(r'r(\w+): ',title) if short(path)=='Raylib' else None
        name=module.group(1) if module else 'constants' if short(path)=='Raylib' else short(path).lower()
        page=pages.setdefault(name,{'titles':[],'lines':[]})
        page['titles'].append(title)
        page['lines']+=lines if module or short(path)!='Raylib' and len(groups)<=2 else ([f'## {title}',''] if title else [])+lines
    links=[]
    for name,page in pages.items():
        heading=short(path) if short(path)!='Raylib' else page['titles'][0] if name!='constants' else 'Raylib\'s constants'
        PAGES[(folder/f'{name}.md').as_posix()]='\n'.join([f'# {heading}','','[Back to the library](README.md)','']+page['lines']).rstrip('\n')+'\n'
        links.append(f'- [{name}.md]({name}.md): {heading}')
    out=['Its members are on their own pages:','']+links if len(links)>1 else [f'Its members are on their own page: [{name}.md]({name}.md).']
    return out+['']+sectioned([],(named,refused))

def for_dox(source,output):
    """The description dox reads: source's, with Raylib's functions moved to a class for each of raylib's modules (the module classes of
    helix.raylib.modules, each with the functions it writes), so the HTML has a page for each, as the Markdown does. Raylib keeps its
    constants and links the modules. As text, as merged() is."""
    import gen_raylib
    text=source.read_text(encoding='utf-8')
    named,refused=LAYOUT['helix.raylib.Raylib']
    skipped={n for kind in refused.values() for n in kind}
    raylib=re.search(r'^\t<class path="helix\.raylib\.Raylib" [^>]*file="([^"]*)">\n(.*?)^\t</class>\n',text,re.M|re.S)
    folder=Path(raylib.group(1)).parent/'modules'
    sections=gen_raylib.TARGETS['Raylib.hx'][0]
    moved={title:[] for _,title in sections}
    kept=raylib.group(2)
    for member in re.finditer(r'^\t\t<(\w+)\b(?:[^>]*?/>|[^>]*>.*?</\1>)\n',raylib.group(2),re.M|re.S):
        title=named.get(member.group(1))
        if title in moved and member.group(1) not in skipped:
            moved[title].append(member.group(0));kept=kept.replace(member.group(0),'',1)
    links=', '.join(f'[{name}](modules/{name}.html)' for name,_ in sections)
    kept=re.sub(r'</haxe_doc>(\n\t\t<meta>(?:(?!</haxe_doc>).)*)?$',lambda m:f"\n\nIts functions are on a page for each of raylib's modules: {links}.</haxe_doc>"+(m.group(1) or ''),kept,count=1,flags=re.S)
    blocks=[]
    for name,title in sections:
        # The module class's own description gives way to the functions it writes, as Raylib's.
        text=re.sub(r'^\t<class path="helix\.raylib\.modules\.'+name+r'" .*?^\t</class>\n','',text,count=1,flags=re.M|re.S)
        blocks.append(f'\t<class path="helix.raylib.modules.{name}" params="" file="{folder/(name+".hx")}">\n'+''.join(moved[title])
                      +f"\t\t<haxe_doc>raylib's {title}. They are `Raylib`'s functions, called with `import helix.raylib.Raylib.*;`.</haxe_doc>\n\t</class>\n")
    text=text.replace(raylib.group(0),raylib.group(0).replace(raylib.group(2),kept),1)
    output.write_text(text[:text.rindex('</haxe>')]+''.join(blocks)+'</haxe>\n',encoding='utf-8')

def merged(js,cpp,output):
    """One description from both targets': js's, and cpp's adapters; writes it to output, the description the reference is made from.
    Merged as Haxe wrote them, as text: ElementTree would rewrite what dox reads (an empty haxe_doc, CDATA)."""
    blocks=[m.group(0) for m in re.finditer(r'^\t<(class|enum|typedef|abstract) path="'+re.escape(ADAPTERS)+r'\..*?^\t</\1>\n',cpp.read_text(encoding='utf-8'),re.M|re.S)]
    expected=sum(1 for n in ET.parse(cpp).getroot() if adapter(n.get('path') or ''))
    if len(blocks)!=expected:sys.exit(f'gen_apidoc: found {len(blocks)} of the {expected} native adapter types in {cpp.name}')
    text=js.read_text(encoding='utf-8')
    output.write_text(text[:text.rindex('</haxe>')]+''.join(blocks)+'</haxe>\n',encoding='utf-8')

def markdown(xml,native=frozenset()):
    """The Markdown files from an XML description: {relative path: text}. native holds the native adapters' paths, the rest the browser's."""
    types=public_types(xml)
    known=set(types)
    files={};index={}
    for path in sorted(types):
        node=types[path];name=short(path);params=node.get('params','')
        header=name+(f'<{params.replace(":",", ")}>' if params else '')
        kind='interface' if node.get('interface')=='1' else {'class':'class','enum':'enum','typedef':'typedef','abstract':'abstract'}[node.tag]
        # What it extends and implements, by name: an interface's base, an adapter's interface.
        parents=''.join(f', {word} '+', '.join(f'`{short(e.get("path"))}`' for e in node.findall(word))
                        for word in ('extends','implements') if node.findall(word))
        # Its source, relative to its page: a link on GitHub and in a checkout alike.
        source=node.get('file','')
        # A library reached through a haxelib dev link is reported by its absolute path: made relative to the checkout.
        if Path(source).is_absolute() and Path(source).resolve().is_relative_to(ROOT.resolve()):source=Path(source).resolve().relative_to(ROOT.resolve()).as_posix()
        # The import that names it: its own path, as each shown type is its own file (checked above).
        target=(', native (cpp)' if path in native else ', for the browser (js)') if adapter(path) else ''
        lines=[f'## {header}','',f'*{kind}*{target} in [`{source}`]({os.path.relpath(ROOT/source,ROOT/Path(package_file(page_package(path))).parent).replace(os.sep,"/")})'+f', `import {path};`'+parents,'']
        doc=doc_text(node)
        if doc:
            lines+=[doc,'']
            more=doc_lines(node)
            if more:lines+=more+['']
        file=page_package(path)
        # An abstract's values and members are its implementation class's statics: an enum abstract's values (:enum) listed by name, the
        # rest as a class's members.
        impl=node.find('impl') if node.tag=='abstract' else None
        body=impl[0] if impl is not None and len(impl) else node
        if node.tag=='abstract':
            values=[c for c in body if c.find('meta') is not None and any(m.get('n')==':enum' for m in c.find('meta'))]
            if values:
                documented=[c for c in values if doc_text(c)]
                if documented:
                    for c in values:lines.append(f'- `{name}.{c.tag}`'+(f': {doc_text(c)}' if doc_text(c) else ''))
                else:lines.append('Values: '+', '.join(f'`{c.tag}`' for c in values)+'.')
                lines.append('')
        if node.tag=='class' or node.tag=='abstract' and body is not node:
            # A property's accessors (get_x, set_x; an interface's are public) are the property, listed once.
            properties={c.tag for c in body if c.get('set')!='method' and c.get('get') is not None}
            enum={c.tag for c in body if c.find('meta') is not None and any(m.get('n')==':enum' for m in c.find('meta'))} if node.tag=='abstract' else set()
            # An abstract's property is the value's when its accessor takes the value (this).
            instance={c.tag for c in body if c.tag in properties and any((a.tag==f'get_{c.tag}' or a.tag==f'set_{c.tag}') and len(a) and (a[0].get('a') or '').split(':')[0]=='this' for a in body)} if node.tag=='abstract' else set()
            members=[m for m in (member_lines(c,known,instance) for c in body if c.tag not in enum and not (c.tag[:4] in ('get_','set_') and c.tag[4:] in properties)) if m]
            members=[(MACROS.get((path,n.tag),sig),d,n) for sig,d,n in members]
            members.sort(key=lambda m:0 if m[0].split('(')[0].endswith(' new') else 1)
            # A @:structInit class is written as an object where one is expected, not constructed: shown as that object, each field with
            # its default.
            if node.find('meta') is not None and any(m.get('n')==':structInit' for m in node.find('meta')) and node.find('new') is not None:
                f=node.find('new').find('f');names=f.get('a','').split(':') if f.get('a') else []
                fields=[n+':'+type_text(k[0] if n.startswith('?') and k.get('path')=='Null' and len(k) else k,known) for n,k in zip(names,list(f)[:-1])]
                lines+=['Written as an object where one is expected; a field marked `?` may be left out, for its default:','','```haxe','{'+', '.join(fields)+'}','```','']
                members=[(sig+''.join(f' = {v[0].text}' for meta in n.findall('meta') for v in meta if v.get('n')==':value' and len(v)),d,n) for sig,d,n in members if not sig.split('(')[0].endswith(' new')]
            if members:lines+=paged(path,members) if path in LAYOUT and path.count('.')==2 and path.startswith('helix.raylib.') else sectioned(members,LAYOUT.get(path))
        elif node.tag=='enum':
            for c in node:
                if c.tag in ('haxe_doc','meta'):continue
                args=c.get('a','');lines.append(f'- `{c.tag}'+(f'({", ".join(a+":"+type_text(k,known) for a,k in zip(args.split(":"),c))})' if args else '')+'`'+(f': {doc_text(c)}' if doc_text(c) else ''))
                # Its remarks and tags too: a value's default or its limits are often in them.
                lines+=doc_lines(c,'  ')
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
    # A page a package, and a library's README.md its own package's (or none, when it has no types of its own) with the rest listed.
    out={}
    libraries={}
    for package in files:libraries.setdefault('.'.join(package.split('.')[:2]),[]).append(package)
    for library,packages in sorted(libraries.items()):
        others=[p for p in sorted(packages) if p!=library]
        for package in others:
            out[package_file(package)]='\n'.join([f'# {package}','','[Back to the library](README.md)','']+files[package]).rstrip('\n')+'\n'
        lines=[f'# {library}','','Generated from the doc comments by `tools/gen_apidoc.py`.','']
        if others:lines+=['## Packages','']+[f'- [`{p}`]({Path(package_file(p)).name}): '+', '.join(short(t) for t,_ in index[p]) for p in others]+['']
        if library=='helix.raylib':lines+=['## Shader includes','','[shaders.md](shaders.md): '+', '.join(f'`<helix/raylib/shaders/{n}>`' for n in INCLUDES),'']
        out[package_file(library)]='\n'.join(lines+files.get(library,[])).rstrip('\n')+'\n'
    out.update(PAGES)
    out['engines/raylib/api/shaders.md']=includes_page()
    return out

# helix-raylib's GLSL includes a program's own shader may use, each documented by the comment that opens it.
INCLUDES=['skinning.glsl']

def includes_page():
    """helix-raylib's shader includes, as their opening comments describe them: the prose as paragraphs, an indented example as GLSL,
    and the first paragraph without the include's own name before its colon."""
    lines=['# helix-raylib\'s shader includes','','[Back to the library](README.md)','',
           'A shader of the program\'s own is raylib\'s GLSL (`#version 330`, or `100` for the web), compiled ahead of time by '
           '`CompileShaderFile`. It may include these.','']
    for name in INCLUDES:
        text=(ROOT/'engines/raylib/src/helix/raylib/shaders'/name).read_text(encoding='utf-8')
        comment=[]
        for line in text.splitlines():
            if not line.startswith('//'):break
            comment.append(line[2:])
        blocks=[]  # (kind, lines): 'p' a paragraph, 'code' an example
        for line in comment:
            kind='code' if line.startswith('    ') else None if line.strip()=='' else 'p'
            if kind is None:
                blocks.append(None);continue
            text_=line[5:] if kind=='code' else line.strip()
            if blocks and blocks[-1] is not None and blocks[-1][0]==kind:blocks[-1][1].append(text_)
            else:blocks.append((kind,[text_]))
        blocks=[b for b in blocks if b is not None]
        first=' '.join(blocks[0][1]).split(':',1)[1].strip()
        lines+=[f'## `<helix/raylib/shaders/{name}>`','',first[:1].upper()+first[1:] if not first.startswith('raylib') else first,'']
        for kind,body in blocks[1:]:
            lines+=(['```glsl']+body+['```',''] if kind=='code' else [' '.join(body),''])
    return '\n'.join(lines).rstrip('\n')+'\n'

# Who a name belongs to when it isn't helix's: the doc writes it after its owner (raylib's `LoadOBJ`, MTL's `Kd`).
OWNERS=r"(?:raylib(?: [\d.]+)?|rlgl|raygui|raymath|rlights|MTL|glTF)'s? $"

def unknown_names(xml,pages):
    """The names helix-raylib's pages give in backticks that no library's reference shows: (page, name) pairs. A name is one a program
    would call or write, a type, function or constant, starting with a capital. One after its owner (OWNERS) is another's. One the shader
    includes declare is in shaders.md."""
    known=set()
    for node in public_types(xml).values():
        known.update((node.get('path'),node.get('path').split('.')[-1]))
        known.update(c.tag for c in node.iter())
    known.update(re.findall(r'\w+',pages['engines/raylib/api/shaders.md']))
    unknown=[]
    for name,text in sorted(pages.items()):
        if not name.startswith('engines/raylib/api/') or name.endswith('/shaders.md'):continue
        fenced=False
        for line in text.splitlines():
            if line.startswith('```'):fenced=not fenced
            if fenced or line.startswith('```'):continue
            for m in re.finditer(r'`([^`]+)`',line):
                n=m.group(1)
                if not re.fullmatch(r'[A-Z]\w*(\.\w+)*',n) or n.endswith('_') or re.search(OWNERS,line[:m.start()]):continue
                if n not in known and n.split('.')[-1] not in known:unknown.append((name,n))
    return sorted(set(unknown))

def main():
    import cli
    p=cli.parser(__doc__);p.add_argument('--check',action='store_true',help="write nothing; fail when a library's api/ isn't what the sources give")
    generate(check=p.parse_args().check)

def defines_section(env,library,macro,example):
    """A library's defines, as its init macro registers them for the compiler (its Defines.ALL), so the reference and
    haxe --help-user-defines can't differ."""
    done=subprocess.run(['haxe','-lib',library,'--macro',f'{macro}.describe()'],cwd=ROOT,
                        env=env,capture_output=True,text=True,encoding='utf-8',check=True)
    lines=['## Defines','',f'Set in a build\'s hxml, as `{example}`'+(' (quoted when the value has a space: `-D "helix-company=Whirling Gizmo"`)' if library=='helix-platform' else '')+'. '
           '`haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.','']
    for define in json.loads(done.stdout.strip().splitlines()[-1]):
        params=''.join(f'=<{p}>' for p in define.get('params',[]))
        lines.append(f'- `{define["define"]}{params}`: {define["doc"]}')
    return '\n'.join(lines)+'\n'

def written():
    """The API pages in the checkout, each library's api/*.md, from the checkout's root."""
    return [p.relative_to(ROOT).as_posix() for d in pins.LIBRARIES.values() for p in sorted((d/'api').glob('*.md'))]

def generate(check=False):
    """Each library's api/ and the HTML in build/api from the doc comments; with check, writes nothing and fails when an api/ isn't what they give.
    What another tool calls (tools/pages.py): main reads the command line, this doesn't."""
    version=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['dox']
    env=dict(os.environ,HAXELIB_PATH=str(ROOT/'build/haxelib'));(ROOT/'build/haxelib').mkdir(parents=True,exist_ok=True)
    # dox makes the HTML alone: a check (the Markdown, from Haxe's own description) needs no install.
    if not check and not (ROOT/'build/haxelib/dox'/version.replace('.',',')).is_dir():subprocess.run(['haxelib','--always','install','dox',version],env=env,check=True,stdout=subprocess.DEVNULL)
    if OUT.exists() and not check:shutil.rmtree(OUT)
    describe('js');describe('cpp')
    global MACROS,LAYOUT
    MACROS=macro_signatures()
    import gen_raylib
    LAYOUT=gen_raylib.layout()
    same_on_both(OUT/'xml/js.xml',OUT/'xml/cpp.xml')
    merged(OUT/'xml/js.xml',OUT/'xml/cpp.xml',OUT/'xml/api.xml')
    native={p for p in public_types(OUT/'xml/cpp.xml') if adapter(p)}
    # A shown type is its own file, so it's imported by its own path (import helix.scene.transitions.Fade): one in another type's module is
    # imported through that module's (helix.scene.Transition.Fade), which no one guesses.
    lodgers=sorted(f'{p} (in {n.get("file")})' for p,n in public_types(OUT/'xml/api.xml').items() if n.get('module') and n.get('module')!=p)
    if lodgers:sys.exit('gen_apidoc: shown types in another type\'s file; give each its own file, or hide it:\n  '+'\n  '.join(lodgers))
    leaked=leaks(OUT/'xml/api.xml')
    if leaked:sys.exit('gen_apidoc: shown members name hidden (@:noCompletion) types; hide or privatize the member, or show the type:\n  '+'\n  '.join(leaked))
    pages=markdown(OUT/'xml/api.xml',native)
    pages['libs/platform/api/README.md']=pages['libs/platform/api/README.md'].rstrip('\n')+'\n\n'+defines_section(env,'helix-platform','helix.platform.macros.Defines','-D helix-product=Asteroids')
    pages['engines/raylib/api/README.md']=pages['engines/raylib/api/README.md'].rstrip('\n')+'\n\n'+defines_section(env,'helix-raylib','helix.raylib.internal.Defines','-D helix-raylib-native-root=../assets')
    # A departure from raylib is answered where it's met: every name a doc or a refusal gives is one the program can look up.
    unknown=unknown_names(OUT/'xml/api.xml',pages)
    if unknown:sys.exit("gen_apidoc: helix-raylib's docs name what no reference shows; name what the program uses, or the name's owner "
                        "(raylib's `LoadOBJ`):\n  "+'\n  '.join(f'{n} in {p}' for p,n in unknown))
    if check:
        stale=[name for name,text in pages.items() if not (ROOT/name).is_file() or (ROOT/name).read_text(encoding='utf-8')!=text]
        extra=[name for name in written() if name not in pages]
        if stale or extra:
            # The first differing lines of each stale page, so a check failing on another system says what differs there.
            import difflib
            for name in stale:
                if (ROOT/name).is_file():
                    diff=list(difflib.unified_diff((ROOT/name).read_text(encoding='utf-8').splitlines(),pages[name].splitlines(),'committed '+name,'generated '+name,lineterm='',n=1))
                    print('\n'.join(diff[:40]),flush=True)
            sys.exit('gen_apidoc: the API pages are stale ('+', '.join(stale+extra)+'); run python3 tools/gen_apidoc.py and commit it')
        print('gen_apidoc: the API pages are current');return
    for name in written():
        if name not in pages:(ROOT/name).unlink()
    for name,text in pages.items():(ROOT/name).parent.mkdir(parents=True,exist_ok=True);(ROOT/name).write_text(text,encoding='utf-8')
    # One description, both targets' merged (the same but for the adapters): dox marks nothing as one target's and offers no filter by
    # one. It leaves out what's @:noCompletion itself.
    # Each type's View Source on GitHub, at the commit described, so the code linked is the code documented.
    described=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    commit=described.stdout.strip() if described.returncode==0 else 'main'
    for_dox(OUT/'xml/api.xml',OUT/'xml/dox.xml')
    subprocess.run(['haxelib','run','dox','-i',str(OUT/'xml/dox.xml'),'-o',str(OUT),'-in','^helix','-D','source-path',f'https://github.com/whirlinggizmo/helix/blob/{commit}/',
        '--title','helix API','--toplevel-package','helix','--keep-field-order','-D','website','https://github.com/whirlinggizmo/helix'],cwd=ROOT,env=env,check=True)
    print('API reference:',OUT/'index.html','and each library\'s api/')

if __name__=='__main__':main()
