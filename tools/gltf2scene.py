"""A Blender glTF export as a .scene3d file (helix.scene.SceneFile3D): one Model node named after the export, its file pointing at the glb,
and the export's custom properties as overrides by node path. Blender exports each object's custom properties as its node's extras when
"Custom Properties" is on; the path to a node is the names down the glTF's tree from the scene's roots joined by "/", so a name used twice
among siblings is an error. Nothing of the model's geometry, transforms, lights, cameras or materials is written: the file is the model's,
and the glTF reader instantiates all of it.

The custom properties the tool reads (any other extra is ignored):
  helix_enabled, helix_visible, helix_pickable   the override's flags, always (a behavior's prop of one of those names is set by hand)
  helix_behavior = "Checkpoint"   a behavior of that kind attached to the node; every other helix_<prop> is then that behavior's prop:
                                  a number, a bool, a string, "@name" a reference, "#rrggbb" a color, a list of numbers a Numbers
  helix_<name>                    without helix_behavior, the kind's property <name>, written as given (the loader checks it)
  helix_props_<name>              the node's props map, the game's own values

Written canonically, as SceneFile3D.write would, so parse then write gives the same bytes and a hand edit stays where it was made.

  python3 tools/gltf2scene.py <export.glb or .gltf> <out.scene3d> [--file models/<export>.glb] [--name <root node name>] [--check]"""
import argparse
import json
import math
from pathlib import Path
import re
import struct
import sys

PREFIX='helix_'
FLAGS=('enabled','visible','pickable')
# An override's properties in the order SceneFile3D writes them: SceneSchema.kinds, each kind's table, a name once where it first appears.
# The test checks the names against SceneSchema.hx and the order through the interpreter.
PROPERTIES=['tint','shadowCasting','shadowReceiving','color','intensity','shadowDistance','shadowMapSize','shadowStrength','shadowColor',
    'range','innerCone','outerCone','projection','fovY','near','far','orthographicHeight','minAspect','texture','regionX','regionY',
    'regionWidth','regionHeight','spriteWidth','spriteHeight','pivotX','pivotY','facing','alphaMode','alphaCutoff','text','textSize','font']
COLOR=re.compile(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})')

def read(path):
    """The glTF's JSON object from a .glb (its JSON chunk) or a .gltf."""
    data=Path(path).read_bytes()
    if data[:4]!=b'glTF':
        try:return json.loads(data.decode('utf-8'))
        except (UnicodeDecodeError,ValueError) as e:sys.exit(f'{path}: neither a GLB nor JSON ({e})')
    if len(data)<20:sys.exit(f'{path}: a GLB header, nothing after it')
    version,length=struct.unpack_from('<II',data,4)
    if version!=2:sys.exit(f'{path}: GLB version {version}, only 2 is read')
    chunk_length,chunk_type=struct.unpack_from('<II',data,12)
    if chunk_type!=0x4e4f534a or 20+chunk_length>len(data):sys.exit(f'{path}: the first GLB chunk is not JSON')
    try:return json.loads(data[20:20+chunk_length].decode('utf-8'))
    except (UnicodeDecodeError,ValueError) as e:sys.exit(f'{path}: the GLB JSON chunk does not parse ({e})')

def properties(gltf,path):
    """The helix_ extras of every node that has one, by the node's path: {path: {name: value}}, walking the default scene's roots (or,
    with no scenes, every parentless node). Exits naming a name two siblings share, a node on a path that has no name or one with "/" in it."""
    nodes=gltf.get('nodes',[])
    scenes=gltf.get('scenes')
    if scenes:roots=scenes[gltf.get('scene',0)].get('nodes',[])
    else:
        children={c for n in nodes for c in n.get('children',[])}
        roots=[i for i in range(len(nodes)) if i not in children]
    found={}
    def walk(indices,parent):
        """Whether a node under indices has helix_ extras, each found one's recorded by its path."""
        names=set();any_found=False
        for i in indices:
            node=nodes[i];name=node.get('name')
            extras={k[len(PREFIX):]:v for k,v in node.get('extras',{}).items() if k.startswith(PREFIX)} if isinstance(node.get('extras'),dict) else {}
            if name:
                if name in names:sys.exit(f'{path}: the name {name!r} is used twice among the children of {parent or "the roots"}')
                names.add(name)
            here=f'{parent}/{name}' if parent else name or ''
            if extras:found[here]=extras
            below=walk(node.get('children',[]),here)
            if (extras or below) and (not name or '/' in name):
                sys.exit(f'{path}: node {i} under {parent or "the roots"} needs a name without "/" to be on a path ({name!r})')
            any_found=any_found or bool(extras) or below
        return any_found
    walk(roots,'')
    return found

def override(extras,where):
    """The override a node's helix_ extras make, as nested lists of (key, value) in the writer's order: the flags; then, with a behavior,
    its kind and the rest as its props, else the rest as the kind's properties; and the node's props from helix_props_<name>. Exits on a
    value no file holds."""
    props=[(k[len('props_'):],value(v,f'{where}: helix_{k}')) for k,v in extras.items() if k.startswith('props_')]
    rest={k:v for k,v in extras.items() if not k.startswith('props_')}
    entries=[]
    for flag in FLAGS:
        if flag in rest:
            v=rest.pop(flag)
            # Older Blender kept a bool custom property as an int.
            if v in (0,1) and not isinstance(v,float):v=bool(v)
            if not isinstance(v,bool):sys.exit(f'{where}: helix_{flag} is true or false ({v!r})')
            entries.append((flag,'true' if v else 'false'))
    if 'behavior' in rest:
        kind=rest.pop('behavior')
        if not isinstance(kind,str) or not kind:sys.exit(f'{where}: helix_behavior names a behavior, text that is not empty ({kind!r})')
        behavior=[('kind',string(kind))]
        if rest:behavior.append(('props',[(k,value(v,f'{where}: helix_{k}')) for k,v in sorted(rest.items())]))
        entries.append(('behaviors',[behavior]))
    else:
        known=[k for k in PROPERTIES if k in rest]
        for k in known+sorted(k for k in rest if k not in PROPERTIES):entries.append((k,value(rest[k],f'{where}: helix_{k}')))
    if props:entries.append(('props',sorted(props)))
    return entries

def value(v,where):
    """A custom property's value as the file's text: a number, a bool, text, a reference or a color (as the writer normalizes it), a list
    of numbers; exits on anything else (a nested group, a list holding other than numbers)."""
    if isinstance(v,bool):return 'true' if v else 'false'
    if isinstance(v,(int,float)):return number(v)
    if isinstance(v,str):
        if len(v)>1 and v[0]=='@':return string(v)
        if COLOR.fullmatch(v):
            text=v.lower()
            return string(text[:7] if len(text)==9 and text[7:]=='ff' else text)
        return string(v)
    if isinstance(v,list) and all(isinstance(x,(int,float)) and not isinstance(x,bool) for x in v):return '['+', '.join(number(x) for x in v)+']'
    sys.exit(f'{where}: expected a number, text, a bool, a list of numbers, a color or a reference ({v!r})')

def number(v):
    """A number as SceneFile3D writes one: an integer-valued one without a point, else with at most six decimals and no trailing zeros, by
    the same integer arithmetic on the rounded fraction; one that is not finite is 0."""
    if isinstance(v,int):return str(v)
    if not math.isfinite(v):return '0'
    negative=v<0;magnitude=-v if negative else v
    whole=math.floor(magnitude);fraction=math.floor((magnitude-whole)*1e6+0.5)
    if fraction>=1000000:whole+=1;fraction=0
    text=str(int(whole))
    if fraction>0:text+='.'+f'{fraction:06d}'.rstrip('0')
    return '-'+text if negative and text!='0' else text

def string(text):
    """text quoted as SceneFile3D writes it: JSON's escapes for the quote, the backslash and control characters, everything else as it is."""
    escapes={'"':'\\"','\\':'\\\\','\n':'\\n','\r':'\\r','\t':'\\t','\b':'\\b','\f':'\\f'}
    return '"'+''.join(escapes.get(c,c if ord(c)>=0x20 else f'\\u{ord(c):04x}') for c in text)+'"'

def lines(entries):
    """An object's lines from its (key, value) entries, a value being text (one line), a list of entries (an object) or a list of entry
    lists (a list of objects): two-space indentation, a comma after all but the last, as SceneFile3D lays them out."""
    if not entries:return ['{}']
    out=['{']
    for i,(key,v) in enumerate(entries):
        if isinstance(v,str):body=[v]
        elif v and isinstance(v[0],list):
            body=['[']
            for j,item in enumerate(v):
                item_lines=lines(item)
                if j<len(v)-1:item_lines[-1]+=','
                body+=['  '+l for l in item_lines]
            body.append(']')
        else:body=lines(v)
        body[0]=f'{string(key)}: {body[0]}'
        if i<len(entries)-1:body[-1]+=','
        out+=['  '+l for l in body]
    out.append('}')
    return out

def convert(gltf_path,file=None,name=None):
    """The .scene3d's bytes for the export at gltf_path: a Model node named name (the export's stem) with file (models/<export's name>) and
    its custom properties as overrides."""
    gltf_path=Path(gltf_path);gltf=read(gltf_path)
    root=[('kind',string('Model')),('name',string(name or gltf_path.stem)),('file',string(file or f'models/{gltf_path.name}'))]
    found=properties(gltf,str(gltf_path))
    if found:root.append(('overrides',[(path,override(extras,f'{gltf_path}: {path}')) for path,extras in sorted(found.items())]))
    return ('\n'.join(lines([('helix-scene3d','1'),('nodes',[root])]))+'\n').encode('utf-8')

def main():
    p=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('gltf',help='the export, a .glb or a .gltf');p.add_argument('out',help='the .scene3d to write')
    p.add_argument('--file',help="the model's path as the scene names it (default: models/<the export's name>)")
    p.add_argument('--name',help="the Model node's name (default: the export's stem)")
    p.add_argument('--check',action='store_true',help='write nothing; exit 1 when out differs from what would be written')
    a=p.parse_args()
    data=convert(a.gltf,a.file,a.name);out=Path(a.out)
    if a.check:
        if not out.is_file() or out.read_bytes()!=data:sys.exit(f'gltf2scene: {out} differs from {a.gltf}; run python3 tools/gltf2scene.py {a.gltf} {out}')
        print(f'gltf2scene: {out} is current');return
    out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
    print(f'gltf2scene: {out}')

if __name__=='__main__':main()
