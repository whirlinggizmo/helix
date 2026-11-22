"""helix-box2d's committed files made from Box2D: its vendored sources, hxcpp's list of them, the calls between Haxe and Box2D, and
the WebAssembly module a page loads.

- Sources: Box2D's C (its src/ and include/box2d/ directories, its api/box2d_api.json and its LICENSE) from the release archive
  dependencies.json pins (box2d), checked against its hash, into libs/box2d/vendor/box2d.
- hxcpp's list: libs/box2d/vendor/box2d/files.xml, the file group a native build compiles, with the flags that keep Box2D
  deterministic across targets.
- The calls: libs/box2d/src/helix/box2d/internal/hb.c and hb.h, a C function of numbers alone for each function of Box2D's that
  helix-box2d has, and Hb.hx, Calls.hx, Init.hx and Callbacks.hx, the Haxe that calls them, all made from api/box2d_api.json. A
  call's numbers, ids and vectors are its arguments, and its structs, arrays and strings cross as 32-bit words through hb_io.h's call
  buffer; a callback's cross through its callback buffer.
- The module: libs/box2d/wasm/box2d.wasm, Box2D and the calls built by Emscripten as a standalone module (no JavaScript of
  Emscripten's), single threaded, with the same flags. Emscripten is found at HELIX_EMSDK, EMSDK or ~/toolchains/emsdk. Objects are
  kept in build/box2d-wasm between builds.

    python3 tools/gen_box2d.py            # vendors the sources when they're missing, writes the calls and files.xml, builds box2d.wasm
    python3 tools/gen_box2d.py --vendor   # vendors the sources again, from the archive
    python3 tools/gen_box2d.py --check    # fails when a file here isn't what the pin and this tool make

Standard library only."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cli  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / 'libs' / 'box2d'
VENDOR = LIBRARY / 'vendor' / 'box2d'
INTERNAL = LIBRARY / 'src' / 'helix' / 'box2d' / 'internal'
WASM = LIBRARY / 'wasm' / 'box2d.wasm'
OBJECTS = ROOT / 'build' / 'box2d-wasm'
# The defines every translation unit shares, natively and in the module: NDEBUG leaves Box2D's asserts out, so invalid input is
# logged and refused, as a release build of Box2D does.
DEFINES = ['NDEBUG']

# What helix-box2d leaves out (DECISIONS 88): what Box2D 3.2 calls experimental, and the parts a program doesn't call.
EXCLUDED = re.compile(
    r'^b2(Replay|Recording|DynamicTree|MoverJoint|PogoJoint)_|^b2(CreateRecording|CreateRecordingFromFile|CreateReplay|DestroyRecording|'
    r'DestroyReplay|ValidateRecording|CreateDynamicTree|CreateTreeProxy|DestroyDynamicTree|DestroyTreeProxy|CreateMoverJoint|CreatePogoJoint|'
    r'DefaultMoverJointDef|DefaultPogoJointDef|SolvePlanes|ClipVector|SetAllocator|SetAssertCallback|Yield|World_CastMover|World_CollideMover|'
    r'World_StartRecording|World_StopRecording|World_DumpMemoryStats|Load\w+Id|Store\w+Id)$')
EXCLUDED_FIELDS = {'internalValue', 'enqueueTask', 'finishTask', 'userTaskContext'}
EXCLUDED_CALLBACKS = {'b2AllocCallbackFcn', 'b2AssertCallbackFcn', 'b2EnqueueTaskCallbackFcn', 'b2FinishTaskCallbackFcn', 'b2FreeCallbackFcn',
                      'b2TaskCallbackFcn', 'b2TreeBoxCastCallbackFcn', 'b2TreeQueryCallbackFcn', 'b2TreeRayCastCallbackFcn',
                      'b2PlaneResultCallbackFcn'}
ALIASES = {'b2Pos': 'b2Vec2', 'b2WorldTransform': 'b2Transform', 'b2WorldCastOutput': 'b2CastOutput'}
INTS = {'int', 'int32_t', 'uint32_t', 'uint16_t', 'int16_t', 'uint8_t', 'size_t'}
# User data is kept on the Haxe side, by id (Data.hx): Box2D's own pointer is never set.
USER_DATA = re.compile(r'^b2(World|Body|Shape|Joint)_(Set|Get)UserData$')
IDS = {'b2WorldId': 'world', 'b2BodyId': 'body', 'b2ShapeId': 'shape', 'b2JointId': 'joint', 'b2ChainId': 'chain', 'b2ContactId': 'contact'}
# Queries whose callback runs only during the call.
QUERIES = {'b2World_CastRay', 'b2World_CastShape', 'b2World_OverlapAABB', 'b2World_OverlapShape'}


def pin():
    """dependencies.json's box2d entry."""
    return json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['box2d']


def vendor():
    """Downloads the pinned release, checks its hash, and copies Box2D's sources, headers, API description and license."""
    box2d = pin()
    with tempfile.TemporaryDirectory() as scratch:
        archive = Path(scratch) / 'box2d.tar.gz'
        print(f'gen_box2d: downloading {box2d["url"]}')
        with urllib.request.urlopen(box2d['url']) as response:
            archive.write_bytes(response.read())
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != box2d['sha256']:
            sys.exit(f'gen_box2d: {box2d["url"]} has sha256 {digest}, not the pinned {box2d["sha256"]}')
        with tarfile.open(archive) as tar:
            tar.extractall(scratch, filter='data')
        top = next(p for p in Path(scratch).iterdir() if p.is_dir())
        if VENDOR.exists():
            shutil.rmtree(VENDOR)
        for directory in ('src', 'include/box2d'):
            for source in sorted((top / directory).iterdir()):
                if source.is_file() and source.suffix in ('.c', '.h', '.inl'):
                    target = VENDOR / directory / source.name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, target)
        (VENDOR / 'api').mkdir(parents=True)
        shutil.copyfile(top / 'api' / 'box2d_api.json', VENDOR / 'api' / 'box2d_api.json')
        shutil.copyfile(top / 'LICENSE', VENDOR / 'LICENSE')
    print(f'gen_box2d: vendored Box2D {box2d["version"]} into {VENDOR.relative_to(ROOT)}')


def tree_hash():
    """A hash of the vendored tree: each file's path and bytes, in the paths' text order."""
    digest = hashlib.sha256()
    files = [p for d in ('src', 'include', 'api') for p in (VENDOR / d).rglob('*') if p.is_file()] + [VENDOR / 'LICENSE']
    for path in sorted(files, key=lambda p: p.relative_to(VENDOR).as_posix()):
        digest.update(path.relative_to(VENDOR).as_posix().encode() + b'\0' + path.read_bytes())
    return digest.hexdigest()


def sources():
    """Box2D's C files, relative to the vendored src directory."""
    return sorted(p.name for p in (VENDOR / 'src').glob('*.c'))


def files_xml():
    """hxcpp's file group for Box2D and helix-box2d's C, with the flags that keep floating point the same on every target."""
    lines = ['<xml>', '<!-- Written by tools/gen_box2d.py. -->', "<files id='helix-box2d' dir='${HELIX_BOX2D}/vendor/box2d/src'>",
             "  <compilerflag value='-I${HELIX_BOX2D}/vendor/box2d/include'/>", "  <compilerflag value='-I${HELIX_BOX2D}/src/helix/box2d/internal'/>",
             *[f"  <compilerflag value='-D{d}'/>" for d in DEFINES],
             "  <compilerflag value='-std=gnu17' unless='windows'/>", "  <compilerflag value='/std:c17' if='windows'/>",
             "  <compilerflag value='/experimental:c11atomics' if='windows'/>",
             "  <compilerflag value='-ffp-contract=off' unless='windows'/>", "  <compilerflag value='/fp:precise' if='windows'/>",
             "  <compilerflag value='-O2' unless='debug'/>",
             # hxcpp rebuilds a file when its source is newer, never for a header it includes: a new release's base.h (its version)
             # is newer than every object, so each is rebuilt rather than linked from the release before.
             "  <depend name='${HELIX_BOX2D}/vendor/box2d/include/box2d/base.h'/>"]
    lines += [f"  <file name='{s}'/>" for s in sources()]
    lines += [f"  <file name='../../../src/helix/box2d/internal/{name}'/>" for name in ('hb.c', 'hb_io.c')]
    lines += ['</files>', '</xml>', '']
    return '\n'.join(lines)


# The model: Box2D's API as helix-box2d has it.


class Model:
    def __init__(self):
        api = json.loads((VENDOR / 'api' / 'box2d_api.json').read_text(encoding='utf-8'))
        self.structs = {s['name']: s for s in api['structs']}
        self.enums = {e['name'] for e in api['enums']}
        self.callbacks = {t['name']: t['function'] for t in api['typedefs'] if t.get('function') and t['name'] not in EXCLUDED_CALLBACKS}
        self.functions = [f for f in api['functions'] if not EXCLUDED.match(f['name'])]
        self.defaults = {f['name'][len('b2Default'):] for f in self.functions if f['name'].startswith('b2Default')}
        headers = ['base.h', 'id.h', 'math_functions.h', 'collision.h', 'types.h', 'box2d.h']
        texts = {h: (VENDOR / 'include' / 'box2d' / h).read_text(encoding='utf-8') for h in headers}
        self.functions.sort(key=lambda f: (headers.index(f['header']), re.search(r'\b' + f['name'] + r'\s*\(', texts[f['header']]).start()))

    def fields(self, struct):
        return [f for f in self.structs[struct]['fields'] if f['name'] not in EXCLUDED_FIELDS]


M = None


def norm(t):
    """A C type without const, its spacing made one, its single precision alias resolved: 'const b2Pos *' is 'b2Vec2 *'."""
    t = re.sub(r'\bconst\b', '', t)
    t = re.sub(r'\s+', ' ', t).strip().replace(' *', ' *')
    if t.endswith('*') and not t.endswith(' *'):
        t = t[:-1].strip() + ' *'
    base = t[:-2] if t.endswith(' *') else t
    base = ALIASES.get(base, base)
    return base + (' *' if t.endswith(' *') else '')


def hx_type(c):
    """The Haxe type of a C value type."""
    return 'B2' + c[2:] if c.startswith('b2') else c


def kind(c):
    """f, i, b or l for a scalar; v for b2Vec2; s for another struct."""
    if c in ('float', 'double'):
        return 'f'
    if c == 'bool':
        return 'b'
    if c == 'uint64_t':
        return 'l'
    if c in INTS or c in M.enums:
        return 'i'
    if c == 'b2Vec2':
        return 'v'
    if c in M.structs:
        return 's'
    raise ValueError(c)


def flat(c, path=''):
    """A small struct's scalar fields as (path, kind), or None when it holds anything else: passed as arguments when four or fewer."""
    k = kind(c)
    if k in 'fib':
        return [(path, k)]
    if k == 'l':
        return None
    if k == 'v':
        return [(path + '.x', 'f'), (path + '.y', 'f')]
    out = []
    for f in M.fields(c):
        if f['args'] or '*' in f['type'] or 'Fcn' in f['type'] or f['type'] == 'void(*)':
            return None
        sub = flat(norm(f['type']), path + '.' + f['name'])
        if sub is None:
            return None
        out += sub
    return out


def direct(c):
    f = flat(c)
    return f is not None and len(f) <= 4


def count_param(params, i):
    """Whether the parameter after i is the count or capacity of the array at i."""
    return i + 1 < len(params) and norm(params[i + 1]['type']) == 'int' and re.search(r'count|capacity|size', params[i + 1]['name'], re.I)


def param_kind(params, i):
    c = norm(params[i]['type'])
    if c == 'void *':
        return 'context'
    if c == 'char *':
        return 'string'
    if c == 'uint8_t *':
        return 'bytesin' if 'const' in params[i]['type'] else 'bytesout'
    if c == 'float *':
        return 'fout'
    if c == 'uint64_t *':
        return 'lout'
    if c.endswith('Fcn *'):
        return 'fcn'
    if c == 'b2DebugDraw *':
        return 'draw'
    if c.endswith(' *'):
        if count_param(params, i):
            return 'inarray' if 'const' in params[i]['type'] else 'outarray'
        return 'in' if 'const' in params[i]['type'] else 'inout'
    k = kind(c)
    if k in 'fib':
        return 'scalar'
    if k == 'l':
        return 'u64'
    return 'direct' if direct(c) else 'in'


def element(c):
    return c[:-2] if c.endswith(' *') else c


def hx_param_type(params, i):
    c = norm(params[i]['type'])
    k = param_kind(params, i)
    if k == 'context':
        return 'Dynamic'
    if k == 'string':
        return 'String'
    if k in ('bytesin', 'bytesout'):
        return 'haxe.io.Bytes'
    if k == 'fout':
        return 'Array<Float>'
    if k == 'lout':
        return 'Array<haxe.Int64>'
    if k == 'fcn':
        return hx_type(element(c))
    if k in ('inarray', 'outarray'):
        return f'Array<{hx_type(element(c))}>'
    if k in ('in', 'inout', 'draw'):
        return hx_type(element(c))
    if k == 'u64':
        return 'haxe.Int64'
    if k == 'scalar':
        return {'f': 'Float', 'i': 'Int', 'b': 'Bool'}[kind(c)] if c not in M.enums else hx_type(c)
    return hx_type(c)


def hx_scalar(c):
    if c in M.enums:
        return hx_type(c)
    return {'f': 'Float', 'i': 'Int', 'b': 'Bool', 'l': 'haxe.Int64'}[kind(c)]


def returns_struct(f):
    r = norm(f['return_type'])
    return r != 'void' and r not in ('void *', 'char *') and kind(r) in 'vs'


def hx_return(f):
    r = norm(f['return_type'])
    if r == 'void':
        return 'Void'
    if r == 'void *':
        return 'Dynamic'
    if r == 'char *':
        return 'String'
    if kind(r) in 'vs':
        return hx_type(r)
    return hx_scalar(r)


# The words of a struct, in C and in Haxe.


def pointer_count(struct, name, fields):
    """The count field of a struct's pointer field."""
    names = [f['name'] for f in fields]
    for candidate in (name.replace('Events', 'Count'), name[:-1] + 'Count', 'count'):
        if candidate != name and candidate in names:
            return candidate
    raise ValueError(f'{struct}.{name}')


def array_length(args):
    n = args.strip('[]')
    return '8' if n == 'B2_MAX_POLYGON_VERTICES' else n


def c_codec(struct):
    """C's hb_rd_ and hb_wr_ for a struct: its fields as words, in order."""
    rd, wr = [], []
    fields = M.fields(struct)
    if struct[2:] in M.defaults:
        rd.append(f'\t*v = b2Default{struct[2:]}();')
    slot = 0
    for f in fields:
        t, n, args = f['type'], f['name'], f['args']
        c = norm(t)
        if t == 'void(*)' or c.endswith('Fcn *'):
            tramp = f'hb_tr_{struct}_{n}' if t == 'void(*)' else f'hb_tr_{element(c)}'
            # A function left unset keeps the def's default: b2DefaultDebugDraw's empty functions, which Box2D calls unchecked.
            rd.append(f'\tif (hb_ri(b))\n\t\tv->{n} = {tramp};' if struct[2:] in M.defaults else f'\tv->{n} = hb_ri(b) ? {tramp} : NULL;')
            wr.append(f'\thb_wi(b, v->{n} != NULL);')
        elif c == 'void *':
            rd.append(f'\thb_ri(b);\n\tv->{n} = NULL;')
            wr.append('\thb_wi(b, 0);')
        elif c == 'char *':
            rd.append(f'\tv->{n} = hb_rs(b, {20 + slot});')
            slot += 1
            wr.append(f'\thb_ws(b, v->{n});')
        elif c.endswith(' *'):
            e = element(c)
            count = pointer_count(struct, n, fields)
            rd.append(f'\t{{\n\t\tint32_t count = hb_ri(b);\n\t\t{e} *a = ({e} *)hb_scratch({24 + slot}, (size_t)(count > 0 ? count : 1) * sizeof({e}));')
            rd.append(f'\t\tfor (int32_t k = 0; k < count; k++) {{\n{indent(c_value_rd("a[k]", e), 3)}\n\t\t}}\n\t\tv->{n} = a;\n\t}}')
            slot += 1
            wr.append(f'\thb_wi(b, v->{count});\n\tfor (int32_t k = 0; k < v->{count}; k++) {{\n{indent(c_value_wr(f"v->{n}[k]", e), 2)}\n\t}}')
        elif args:
            length = array_length(args)
            rd.append(f'\tfor (int k = 0; k < {length}; k++) {{\n{indent(c_value_rd(f"v->{n}[k]", c), 2)}\n\t}}')
            wr.append(f'\tfor (int k = 0; k < {length}; k++) {{\n{indent(c_value_wr(f"v->{n}[k]", c), 2)}\n\t}}')
        else:
            rd.append(indent(c_value_rd(f'v->{n}', c), 1))
            wr.append(indent(c_value_wr(f'v->{n}', c), 1))
    if struct == 'b2WorldDef':
        # The module has no threads: Box2D's own would fail to start.
        rd.append('#ifdef __EMSCRIPTEN__\n\tv->workerCount = 1;\n#endif')
    return (f'static void hb_rd_{struct}(hb_buffer *b, {struct} *v) {{\n' + '\n'.join(rd) + '\n}\n',
            f'static void hb_wr_{struct}(hb_buffer *b, const {struct} *v) {{\n' + '\n'.join(wr) + '\n}\n')


def indent(text, n):
    return '\n'.join('\t' * n + line for line in text.split('\n'))


def c_value_rd(expr, c, b='b'):
    k = kind(c)
    if k == 'f':
        return f'{expr} = hb_rf({b});'
    if k == 'b':
        return f'{expr} = hb_ri({b}) != 0;'
    if k == 'i':
        return f'{expr} = ({c})hb_ri({b});'
    if k == 'l':
        return f'{expr} = hb_rl({b});'
    if k == 'v':
        return f'{expr}.x = hb_rf({b});\n{expr}.y = hb_rf({b});'
    return f'hb_rd_{c}({b}, &{expr});'


def c_value_wr(expr, c, b='b'):
    k = kind(c)
    if k == 'f':
        return f'hb_wf({b}, {expr});'
    if k == 'b':
        return f'hb_wi({b}, {expr} ? 1 : 0);'
    if k == 'i':
        return f'hb_wi({b}, (int32_t){expr});'
    if k == 'l':
        return f'hb_wl({b}, {expr});'
    if k == 'v':
        return f'hb_wf({b}, {expr}.x);\nhb_wf({b}, {expr}.y);'
    return f'hb_wr_{c}({b}, &{expr});'


def hx_codec(struct):
    """Haxe's wr and rd for a struct, matching C's."""
    t = hx_type(struct)
    rd, wr = [], []
    fields = M.fields(struct)
    for f in fields:
        ty, n, args = f['type'], f['name'], f['args']
        c = norm(ty)
        if ty == 'void(*)' or c.endswith('Fcn *'):
            rd.append('\t\tIo.ri();')
            wr.append(f'\t\tIo.wb(v.{n} != null);')
        elif c == 'void *':
            rd.append(f'\t\tIo.ri();\n\t\tv.{n} = null;')
            wr.append('\t\tIo.wi(0);')
        elif c == 'char *':
            rd.append(f'\t\tv.{n} = Io.rs();')
            wr.append(f'\t\tIo.ws(v.{n});')
        elif c.endswith(' *'):
            e = element(c)
            count = pointer_count(struct, n, fields)
            rd.append(f'\t\t{{\n\t\t\tvar count = Io.ri();\n\t\t\tif (v.{n} == null)\n\t\t\t\tv.{n} = [];\n\t\t\tvar a = v.{n};\n'
                      f'\t\t\tfor (k in 0...count) {{\n\t\t\t\tif (k >= a.length)\n\t\t\t\t\ta.push({hx_new(e)});\n'
                      f'{indent(hx_value_rd("a[k]", e), 4)}\n\t\t\t}}\n\t\t}}')
            wr.append(f'\t\tIo.wi(v.{count});\n\t\tfor (k in 0...v.{count})\n{indent(hx_value_wr(f"v.{n}[k]", e), 3)}')
        elif args:
            length = array_length(args)
            rd.append(f'\t\tfor (k in 0...{length})\n{indent(hx_value_rd(f"v.{n}[k]", c), 3)}')
            wr.append(f'\t\tfor (k in 0...{length})\n{indent(hx_value_wr(f"v.{n}[k]", c), 3)}')
        else:
            rd.append(indent(hx_value_rd(f'v.{n}', c), 2))
            wr.append(indent(hx_value_wr(f'v.{n}', c), 2))
    if struct == 'b2BodyMoveEvent':
        # Box2D's user data pointer is never set: the body's is kept by id (Data).
        rd.append('\t\tv.userData = Data.get(v.bodyId);')
    return (f'\tpublic static function rd{t}(v:{t}):{t} {{\n' + '\n'.join(rd) + '\n\t\treturn v;\n\t}\n',
            f'\tpublic static function wr{t}(v:{t}):Void {{\n' + '\n'.join(wr) + '\n\t}\n')


def hx_new(c):
    """A struct made without calling Box2D, as a read or a constructor makes one: a def's own constructor calls Box2D for its defaults."""
    return 'new B2Vec2()' if c == 'b2Vec2' else f'Init.make{hx_type(c)}()'


def hx_value_rd(expr, c):
    k = kind(c)
    if k == 'f':
        return f'{expr} = Io.rf();'
    if k == 'b':
        return f'{expr} = Io.rb();'
    if k == 'i':
        return f'{expr} = cast Io.ri();' if c in M.enums else f'{expr} = Io.ri();'
    if k == 'l':
        return f'{expr} = Io.rl();'
    if k == 'v':
        return f'Io.rv({expr});'
    return f'rd{hx_type(c)}({expr});'


def hx_value_wr(expr, c):
    k = kind(c)
    if k == 'f':
        return f'Io.wf({expr});'
    if k == 'b':
        return f'Io.wb({expr});'
    if k == 'i':
        return f'Io.wi({expr});'
    if k == 'l':
        return f'Io.wl({expr});'
    if k == 'v':
        return f'Io.wv({expr});'
    return f'wr{hx_type(c)}({expr});'


def hx_init(struct):
    """Init's function for a struct: each field made, its numbers zero, its structs and fixed arrays new."""
    t = hx_type(struct)
    lines = []
    for f in M.fields(struct):
        ty, n, args = f['type'], f['name'], f['args']
        c = norm(ty)
        if ty == 'void(*)' or c.endswith('Fcn *') or c in ('void *', 'char *'):
            lines.append(f'\t\tv.{n} = null;')
        elif c.endswith(' *'):
            lines.append(f'\t\tv.{n} = [];')
        elif args:
            e = c
            fill = {'f': '0.', 'i': '0', 'b': 'false'}.get(kind(e)) if kind(e) in 'fib' else hx_new(e)
            if kind(e) == 'l':
                fill = 'haxe.Int64.make(0, 0)'
            lines.append(f'\t\tv.{n} = [for (k in 0...{array_length(args)}) {fill}];')
        else:
            k = kind(c)
            value = {'f': '0.', 'i': '0', 'b': 'false', 'l': 'haxe.Int64.make(0, 0)'}.get(k)
            if k == 'i' and c in M.enums:
                value = 'cast 0'
            lines.append(f'\t\tv.{n} = {value if value is not None else hx_new(c)};')
    if struct == 'b2Rot':
        lines = ['\t\tv.c = 1.;', '\t\tv.s = 0.;']
    return (f'\tpublic static function init{t}(v:{t}):Void {{\n' + '\n'.join(lines) + '\n\t}\n\n'
            f'\tpublic static function make{t}():{t} {{\n\t\tvar v = Type.createEmptyInstance({t});\n\t\tinit{t}(v);\n\t\treturn v;\n\t}}\n')


# The calls.


def c_args_of_direct(name, c):
    """A directly passed struct's C parameters and the expression rebuilding it."""
    params = []
    parts = flat(c)
    for path, k in parts:
        params.append(('float ' if k == 'f' else 'int32_t ') + name + path.replace('.', '_'))
    if kind(c) in 'fib':
        return params, name
    assigns = ', '.join(f'{path} = {name}{path.replace(".", "_")}' for path, _ in parts)
    return params, f'({c}){{0}}', assigns


def c_direct_build(name, c):
    parts = flat(c)
    lines = [f'\t{c} {name}_v;']
    for path, k in parts:
        lines.append(f'\t{name}_v{path} = {name}{path.replace(".", "_")};')
    return lines


def call(f):
    """A function's C shim, its Hb extern line and its Calls function."""
    name, params = f['name'], f['params']
    cparams, cpre, cargs, cpost = [], [], [], []
    hparams, hpre, hargs, hpost = [], [], [], []
    xparams, xargs = [], []  # the extern's parameters
    words_in = False
    for i, p in enumerate(params):
        n, c = p['name'], norm(p['type'])
        k = param_kind(params, i)
        ht = hx_param_type(params, i)
        if k == 'outarray' and name == 'b2ComputeShapeDistance':
            hparams.append(f'?{n}:{ht}')
        elif name == 'b2ComputeShapeDistance' and n == 'simplexCapacity':
            hparams.append(f'{n} = 0')
        else:
            hparams.append(f'{n}:{ht}')
        if k == 'scalar':
            ck = kind(c)
            cparams.append(('float ' if ck == 'f' else 'int32_t ') + n)
            cargs.append(f'({c}){n}' if ck == 'i' else (f'{n} != 0' if ck == 'b' else n))
            xparams.append(f'{n}:' + ('Float' if ck == 'f' else 'Int'))
            xargs.append(f'{n} ? 1 : 0' if ck == 'b' else (f'{n}' if ck == 'f' else f'(cast {n} : Int)' if c in M.enums else n))
        elif k == 'u64':
            cparams += [f'int32_t {n}_low', f'int32_t {n}_high']
            cargs.append(f'((uint64_t)(uint32_t){n}_high << 32) | (uint32_t){n}_low')
            xparams += [f'{n}_low:Int', f'{n}_high:Int']
            xargs += [f'{n}.low', f'{n}.high']
        elif k == 'direct':
            parts = flat(c)
            for path, pk in parts:
                cparams.append(('float ' if pk == 'f' else 'int32_t ') + n + path.replace('.', '_'))
                xparams.append(n + path.replace('.', '_') + ':' + ('Float' if pk == 'f' else 'Int'))
                xargs.append(n + path if pk != 'b' else f'{n}{path} ? 1 : 0')
            cpre += c_direct_build(n, c)
            cargs.append(f'{n}_v' if not p['type'].strip().endswith('*') else f'&{n}_v')
        elif k == 'in':
            e = element(c)
            words_in = True
            cpre.append(f'\t{e} {n}_v;\n\thb_rd_{e}(&hb_call, &{n}_v);')
            cargs.append(f'&{n}_v' if c.endswith(' *') else f'{n}_v')
            hpre.append(f'\t\twr{hx_type(e)}({n});')
        elif k == 'inout':
            e = element(c)
            words_in = True
            cpre.append(f'\t{e} {n}_v;\n\thb_rd_{e}(&hb_call, &{n}_v);')
            cargs.append(f'&{n}_v')
            cpost.append(f'\thb_wr_{e}(&hb_call, &{n}_v);')
            hpre.append(f'\t\twr{hx_type(e)}({n});')
            hpost.append(f'\t\trd{hx_type(e)}({n});')
        elif k == 'inarray':
            e = element(c)
            words_in = True
            count = params[i + 1]['name']
            cpre.append(f'\t{e} *{n}_v = ({e} *)hb_scratch({i}, (size_t)({count} > 0 ? {count} : 1) * sizeof({e}));\n'
                        f'\tfor (int32_t k = 0; k < {count}; k++) {{\n{indent(c_value_rd(f"{n}_v[k]", e, '&hb_call'), 2)}\n\t}}')
            cargs.append(f'{n}_v')
            hpre.append(f'\t\tfor (k in 0...{count})\n{indent(hx_value_wr(f"{n}[k]", e), 3)}')
        elif k == 'outarray':
            e = element(c)
            count = params[i + 1]['name']
            cpre.append(f'\t{e} *{n}_v = ({e} *)hb_scratch({i}, (size_t)({count} > 0 ? {count} : 1) * sizeof({e}));')
            cargs.append(f'{n}_v')
            filled = 'result' if norm(f['return_type']) == 'int' else f'(result.simplexCount < {count} ? result.simplexCount : {count})'
            cpost.append(f'\t{{\n\t\tint32_t filled = {filled};\n\t\thb_wi(&hb_call, filled);\n\t\tfor (int32_t k = 0; k < filled; k++) {{\n'
                         f'{indent(c_value_wr(f"{n}_v[k]", e, '&hb_call'), 3)}\n\t\t}}\n\t}}')
            hpost.append(f'\t\t{{\n\t\t\tvar filled = Io.ri();\n\t\t\tif ({n} != null)\n\t\t\t\tfor (k in 0...filled) {{\n'
                         f'\t\t\t\t\tif (k >= {n}.length)\n\t\t\t\t\t\t{n}.push({hx_new(e)});\n{indent(hx_value_rd(f"{n}[k]", e), 5)}\n\t\t\t\t}}\n\t\t}}')
            if name == 'b2ComputeShapeDistance':
                xargs_count_fix = True  # noqa: F841
        elif k == 'fout':
            cpre.append(f'\tfloat {n}_v = 0;')
            cargs.append(f'&{n}_v')
            cpost.append(f'\thb_wf(&hb_call, {n}_v);')
            hpost.append(f'\t\t{n}[0] = Io.rf();')
        elif k == 'lout':
            cpre.append(f'\tuint64_t {n}_v = 0;')
            cargs.append(f'&{n}_v')
            cpost.append(f'\thb_wl(&hb_call, {n}_v);')
            hpost.append(f'\t\t{n}[0] = Io.rl();')
        elif k == 'string':
            words_in = True
            cpre.append(f'\tconst char *{n}_v = hb_rs(&hb_call, {i});')
            cargs.append(f'{n}_v')
            hpre.append(f'\t\tIo.ws({n});')
        elif k == 'bytesin':
            words_in = True
            count = params[i + 1]['name']
            cpre.append(f'\tconst uint8_t *{n}_v = hb_rbytes(&hb_call, {count}, {i});')
            cargs.append(f'{n}_v')
            hpre.append(f'\t\tIo.wbytes({n}, {count});')
        elif k == 'bytesout':
            count = params[i + 1]['name']
            cparams.append(f'int32_t {n}_given')
            cpre.append(f'\tuint8_t *{n}_v = {n}_given ? (uint8_t *)hb_scratch({i}, (size_t)({count} > 0 ? {count} : 1)) : NULL;')
            cargs.append(f'{n}_v')
            cpost.append(f'\tif ({n}_v != NULL)\n\t\thb_wbytes(&hb_call, {n}_v, result < {count} ? result : {count});')
            xparams.append(f'{n}_given:Int')
            xargs.append(f'{n} != null ? 1 : 0')
            hpost.append(f'\t\tif ({n} != null)\n\t\t\tIo.rbytes({n}, result < {count} ? result : {count});')
        elif k == 'fcn':
            tramp = f'hb_tr_{element(c)}'
            cparams.append(f'int32_t {n}')
            cargs.append(f'{n} ? {tramp} : NULL')
            xparams.append(f'{n}:Int')
            xargs.append(f'{n} != null ? 1 : 0')
        elif k == 'context':
            # A callback's context: the slot holding the callback and its context on the Haxe side.
            cparams.append(f'int32_t {n}')
            cargs.append(f'(void *)(intptr_t){n}')
            xparams.append(f'{n}:Int')
            xargs.append('slot')
        elif k == 'draw':
            words_in = True
            cparams.append('int32_t slot')
            cpre.append(f'\tb2DebugDraw {n}_v;\n\thb_rd_b2DebugDraw(&hb_call, &{n}_v);\n\t{n}_v.context = (void *)(intptr_t)slot;')
            cargs.append(f'&{n}_v')
            hpre.append(f'\t\twrB2DebugDraw({n});')
            xparams.append('slot:Int')
            xargs.append('slot')
        if k in ('outarray',) and name == 'b2ComputeShapeDistance':
            pass
    # The return.
    r = norm(f['return_type'])
    ret_struct = returns_struct(f)
    hret = hx_return(f)
    if ret_struct:
        hparams.append(f'?out:{hret}')
    if r == 'void':
        cret = 'void'
    elif ret_struct or r == 'uint64_t' or r == 'char *':
        cret = 'void'
    else:
        cret = 'float' if kind(r) == 'f' else 'int32_t'
    call_expr = f'{name}({", ".join(cargs)})'
    lines = [f'HB_API {cret} hb_{name}({", ".join(cparams) or "void"}) {{']
    if words_in:
        lines.append('\thb_begin(&hb_call);')
    lines += cpre
    if name == 'b2World_Step':
        lines.append('\thb_stepping = worldId_v.index1;')
    workers = {'b2World_SetWorkerCount': 'count', 'b2CreateWorldFromSnapshot': 'workerCount'}.get(name)
    if workers:
        lines.append(f'#ifdef __EMSCRIPTEN__\n\t{workers} = 1;\n#endif')
    if r == 'void':
        lines.append(f'\t{call_expr};')
    else:
        lines.append(f'\t{r if not r.endswith(" *") else "const " + r} result = {call_expr};')
    if name == 'b2World_Step':
        lines.append('\thb_stepping = 0;')
    out_words = ret_struct or r in ('uint64_t', 'char *') or cpost
    if out_words:
        lines.append('\thb_begin(&hb_call);')
        if ret_struct:
            lines.append(indent(c_value_wr('result', r, '&hb_call'), 1))
        elif r == 'uint64_t':
            lines.append('\thb_wl(&hb_call, result);')
        elif r == 'char *':
            lines.append('\thb_ws(&hb_call, result);')
        lines += cpost
    if cret != 'void':
        lines.append('\treturn ' + ('result ? 1 : 0' if kind(r) == 'b' else 'result') + ';')
    lines.append('}\n')
    c_text = '\n'.join(lines)
    # The extern.
    xret = 'Void' if cret == 'void' else ('Float' if cret == 'float' else 'Int')
    extern = f'\t@:native("hb_{name}") static function {name}({", ".join(xparams)}):{xret};'
    # The Calls function.
    body = []
    fcns = [p['name'] for j, p in enumerate(params) if param_kind(params, j) == 'fcn']
    if fcns:
        context = next((p['name'] for j, p in enumerate(params) if param_kind(params, j) == 'context'), 'null')
        kinds = ', '.join(f'{fn}' for fn in fcns)
        if name in QUERIES:
            body.append(f'\t\tvar slot = Callbacks.open([{kinds}], {context});')
        elif name == 'b2SetLogCallback':
            body.append(f'\t\tCallbacks.log = {fcns[0]};')
        elif context != 'null':
            body.append(f'\t\tvar slot = Callbacks.world(worldId, "{name}", [{kinds}], {context});')
        else:
            typedef = element(norm(next(p['type'] for p in params if p['name'] == fcns[0])))
            body.append(f'\t\tCallbacks.setWorldFunction(worldId, "{typedef}", {fcns[0]});')
    if name == 'b2World_Draw':
        body.append('\t\tvar slot = Callbacks.open([draw], draw.context);')
    if ret_struct:
        body.append(f'\t\tvar value = out == null ? {"new B2Vec2()" if r == "b2Vec2" else "new " + hret + "()"} : out;')
    if hpre:
        body.append('\t\tIo.begin();')
        body += hpre
    hcall = f'Hb.{name}({", ".join(xargs)})'
    if xret == 'Void':
        body.append(f'\t\t{hcall};')
    else:
        body.append(f'\t\tvar result = {hcall};')
    if out_words:
        body.append('\t\tIo.begin();')
        if ret_struct:
            body.append(f'\t\trd{hret}(value);' if r != 'b2Vec2' else '\t\tIo.rv(value);')
        elif r == 'uint64_t':
            body.append('\t\tvar value = Io.rl();')
        elif r == 'char *':
            body.append('\t\tvar value = Io.rs();')
        body += hpost
    if name in QUERIES or name == 'b2World_Draw':
        body.append('\t\tCallbacks.close(slot);')
    after = post_create(f)
    if after:
        body.append(after)
    if hret != 'Void':
        if out_words and (ret_struct or r in ('uint64_t', 'char *')):
            body.append('\t\treturn value;')
        elif kind(r) == 'b' if r not in ('void', 'void *', 'char *') and kind(r) in 'fibl' else False:
            body.append('\t\treturn result != 0;')
        elif r in M.enums:
            body.append('\t\treturn cast result;')
        else:
            body.append('\t\treturn result;')
    hx_text = f'\tpublic static inline function {name}({", ".join(hparams)}):{hret} {{\n' + '\n'.join(body) + '\n\t}\n'
    return c_text, extern, hx_text


def post_create(f):
    """What a creating or destroying call does on the Haxe side: the new object's user data kept, a world's entries cleared."""
    name = f['name']
    if name == 'b2DestroyWorld':
        return '\t\tData.clear(worldId);\n\t\tCallbacks.clear(worldId);'
    if name == 'b2CreateWorld':
        return ('\t\tData.set(value, def.userData);\n\t\tCallbacks.setWorldFunction(value, "b2FrictionCallbackFcn", def.frictionCallback);\n'
                '\t\tCallbacks.setWorldFunction(value, "b2RestitutionCallbackFcn", def.restitutionCallback);')
    if re.match(r'^b2Create\w+(Shape|Joint)$|^b2CreateBody$|^b2CreateChain$', name):
        what = 'base.userData' if name.endswith('Joint') else 'userData'
        return f'\t\tif (def.{what} != null)\n\t\t\tData.set(value, def.{what});'
    return ''


def user_data(f):
    """The Calls function of a user data getter or setter, kept by id on the Haxe side."""
    name = f['name']
    p = f['params']
    if '_Set' in name:
        return f'\tpublic static inline function {name}({p[0]["name"]}:{hx_type(norm(p[0]["type"]))}, userData:Dynamic):Void {{\n\t\tData.set({p[0]["name"]}, userData);\n\t}}\n'
    return f'\tpublic static inline function {name}({p[0]["name"]}:{hx_type(norm(p[0]["type"]))}):Dynamic {{\n\t\treturn Data.get({p[0]["name"]});\n\t}}\n'


# Callbacks.


def callback_signatures():
    """Each callback Box2D calls: a name, its parameters as (name, C type) and its C return type."""
    out = []
    for name, fn in M.callbacks.items():
        out.append((name, [(p['name'], p['type']) for p in fn['params']], fn['return_type']))
    for f in M.fields('b2DebugDraw'):
        if f['type'] == 'void(*)':
            params = []
            for part in f['args'].strip('()').split(','):
                m = re.match(r'(.*?)(\w+)$', part.strip())
                params.append((m.group(2), m.group(1).strip()))
            out.append((f'b2DebugDraw_{f["name"]}', params, 'void'))
    return out


def trampoline(name, params, ret):
    """C's trampoline for a callback, which Box2D calls and which calls Haxe, and the Haxe function it calls."""
    r = norm(ret)
    cret = 'void' if r == 'void' else ('float' if kind(r) == 'f' else 'int32_t')
    cparams, xargs, pre, post = [], [], [], []
    hparams, hpre, hpost, uargs = [], [], [], []
    has_context = any(norm(t) == 'void *' for _, t in params)
    xargs.append('(int32_t)(intptr_t)context' if has_context else 'hb_stepping')
    hparams.append('slot:Int')
    for i, (n, t) in enumerate(params):
        c = norm(t)
        cparams.append(f'{t} {n}')
        if c == 'void *':
            uargs.append('Callbacks.context(slot)')
            continue
        if c == 'char *':
            pre.append(f'\thb_ws(&hb_back, {n});')
            hpre.append(f'\t\tvar {n} = Io.rs();')
            uargs.append(n)
            continue
        if c.endswith(' *'):
            e = element(c)
            if i + 1 < len(params) and norm(params[i + 1][1]) == 'int':
                count = params[i + 1][0]
                pre.append(f'\tfor (int k = 0; k < {count}; k++) {{\n{indent(c_value_wr(f"{n}[k]", e, '&hb_back'), 2)}\n\t}}')
                hpre.append(f'\t\tvar {n} = scratch{hx_type(e)}s;\n\t\tfor (k in 0...{count}) {{\n\t\t\tif (k >= {n}.length)\n\t\t\t\t{n}.push({hx_new(e)});\n'
                            f'{indent(hx_value_rd(f"{n}[k]", e), 3)}\n\t\t}}')
                uargs.append(n)
                continue
            pre.append(f'\thb_wr_{e}(&hb_back, {n});')
            hpre.append(f'\t\tvar {n} = rd{hx_type(e)}(scratch{hx_type(e)});')
            if 'const' not in t:
                post.append(f'\thb_begin(&hb_back);\n\thb_rd_{e}(&hb_back, {n});')
                hpost.append(f'\t\tIo.beginBack();\n\t\twr{hx_type(e)}({n});')
            uargs.append(n)
            continue
        k = kind(c)
        if k in 'fib':
            cparams_x = 'float' if k == 'f' else 'int32_t'
            xargs.append(n if k != 'b' else f'{n} ? 1 : 0')
            hparams.append(f'{n}:{"F32" if k == "f" else "Int"}')
            uargs.append(n if k == 'i' and c not in M.enums else (f'{n} != 0' if k == 'b' else (f'cast {n}' if c in M.enums else n)))
            continue
        if k == 'l':
            xargs += [f'(int32_t)(uint32_t){n}', f'(int32_t)(uint32_t)({n} >> 32)']
            hparams += [f'{n}_low:Int', f'{n}_high:Int']
            uargs.append(f'haxe.Int64.make({n}_high, {n}_low)')
            continue
        parts = flat(c)
        for path, pk in parts:
            xargs.append(n + path if pk != 'b' else f'{n}{path} ? 1 : 0')
            hparams.append(n + path.replace('.', '_') + ':' + ('F32' if pk == 'f' else 'Int'))
        hpre.append(f'\t\tvar {n} = scratch{i}{name};')
        for path, pk in parts:
            hpre.append(f'\t\t{n}{path} = {n}{path.replace(".", "_")};')
        uargs.append(n)
    xparam_types = ['int32_t']
    for a in xargs[1:]:
        xparam_types.append('float' if not a.startswith('(int32_t)') and not a.endswith('? 1 : 0') and float_arg(a, params) else 'int32_t')
    import_name = f'hb_cb_{name}'
    decl_params = ', '.join(xparam_types)
    c = [f'#ifdef __EMSCRIPTEN__\n{cret} {import_name}({decl_params}) HB_IMPORT({import_name});\n#else\nstatic {cret} (*{import_name})({decl_params});\n'
         f'HB_API void hb_set_{import_name}(void *f) {{ {import_name} = ({cret} (*)({decl_params}))f; }}\n#endif']
    body = []
    if pre:
        body.append('\thb_begin(&hb_back);')
        body += pre
    call_text = f'{import_name}({", ".join(xargs)})'
    if cret == 'void':
        body.append(f'\t{call_text};')
    else:
        body.append(f'\t{cret} result = {call_text};')
    body += post
    if cret != 'void':
        body.append('\treturn ' + ('result != 0' if kind(r) == 'b' else 'result') + ';')
    tramp_name = f'hb_tr_{name}'
    c.append(f'static {r if r != "bool" else "bool"} {tramp_name}({", ".join(cparams)}) {{\n' + '\n'.join(body) + '\n}\n')
    return '\n'.join(c), (name, hparams, hpre, hpost, uargs, r)


def float_arg(arg, params):
    """Whether a trampoline's argument expression is a float."""
    base = arg.split('.')[0]
    for n, t in params:
        if n == base:
            c = norm(t)
            if kind(c) == 'f':
                return True
            if kind(c) in 'vs':
                for path, pk in flat(c):
                    if arg == n + path:
                        return pk == 'f'
    return False


def callbacks_hx(entries):
    """Callbacks.hx's dispatchers: each reads a callback's arguments and calls the Haxe function its slot holds."""
    out = []
    scratch = set()
    for name, hparams, hpre, hpost, uargs, r in entries:
        hret = 'Void' if r == 'void' else ('F32' if kind(r) == 'f' else 'Int')
        lines = [f'\tstatic function {name}({", ".join(hparams)}):{hret} {{', '\t\t#if cpp\n\t\tuntyped __cpp__("hx::NativeAttach attach");\n\t\t#end']
        for line in hpre:
            for m in re.finditer(r'scratch(\w+)', line):
                scratch.add(m.group(1))
        if any('Io.' in line or 'rd' in line for line in hpre):
            lines.append('\t\tIo.beginBack();')
        lines += hpre
        if name.startswith('b2DebugDraw_'):
            field = name[len('b2DebugDraw_'):]
            lines.append(f'\t\tvar draw:B2DebugDraw = Callbacks.get(slot, 0);')
            call_text = f'draw.{field}({", ".join(uargs)})'
        elif name == 'b2LogCallbackFcn':
            lines.append('\t\tvar f:B2LogCallbackFcn = Callbacks.log;\n\t\tif (f == null)\n\t\t\tf = Callbacks.print;')
            call_text = f'f({", ".join(uargs)})'
        elif name in ('b2FrictionCallbackFcn', 'b2RestitutionCallbackFcn'):
            lines.append(f'\t\tvar f:{hx_type(name)} = Callbacks.worldFunction(slot, "{name}");')
            call_text = f'f({", ".join(uargs)})'
        else:
            typed = hx_type(name)
            lines.append(f'\t\tvar f:{typed} = Callbacks.get(slot, {INDEX[name]});')
            call_text = f'f({", ".join(uargs)})'
        if r == 'void':
            lines.append(f'\t\t{call_text};')
            lines += hpost
        else:
            lines.append(f'\t\tvar result = {call_text};')
            lines += hpost
            lines.append('\t\treturn ' + ('result ? 1 : 0' if kind(r) == 'b' else 'result') + ';')
        lines.append('\t}\n')
        out.append('\n'.join(lines))
    fields = []
    for s in sorted(scratch):
        m = re.match(r'(\d+)(\w+)$', s)
        if m:
            # A directly passed struct's scratch, by its parameter index and callback.
            name = m.group(2)
            params = next(p for n, p, _ in callback_signatures() if n == name)
            t = norm(params[int(m.group(1))][1])
            fields.append(f'\tstatic var scratch{s} = {hx_new(t)};')
        elif s.endswith('s'):
            fields.append(f'\tstatic var scratch{s}:Array<{s[:-1]}> = [];')
        else:
            fields.append(f'\tstatic var scratch{s} = new {s}();')
    return fields, out


INDEX = {}


def generate():
    """hb.c, hb.h, Hb.hx, Calls.hx, Init.hx and the Callbacks dispatchers, as text by file name."""
    global M
    M = Model()
    used = needed_structs()
    c_codecs, hx_codecs, inits = [], [], []
    for s in sorted(used):
        rd, wr = c_codec(s)
        c_codecs += [rd, wr]
        hrd, hwr = hx_codec(s)
        hx_codecs += [hrd, hwr]
    for s in sorted(M.structs):
        if s == 'b2Vec2' or s not in HAXE_TYPES:
            continue
        inits.append(hx_init(s))
    sigs = callback_signatures()
    for n, (name, _, _) in enumerate(s for s in sigs if not s[0].startswith('b2DebugDraw_')):
        INDEX[name] = 0
    # Each slot holds its callbacks in the order its call names them: a query's one, the pre-solve pair, a world def's two.
    INDEX.update({'b2PreContinuousCallbackFcn': 1})
    tramps, entries = [], []
    for name, params, ret in sigs:
        c, entry = trampoline(name, params, ret)
        tramps.append(c)
        entries.append(entry)
    shims, externs, calls = [], [], []
    for f in M.functions:
        if USER_DATA.match(f['name']):
            calls.append(user_data(f))
            continue
        c, x, h = call(f)
        shims.append(c)
        externs.append(x)
        calls.append(h)
    hb_c = ('/* Written by tools/gen_box2d.py: a call of numbers alone for each function of Box2D\'s that helix-box2d has (hb_io.h says how\n'
            '   its structs, arrays and strings cross), and a trampoline for each callback, calling Haxe. */\n'
            '#include "hb.h"\n#include "hb_io.h"\n\n#include <box2d/box2d.h>\n#include <box2d/collision.h>\n#include <box2d/math_functions.h>\n\n'
            '/* The world being stepped, for a callback Box2D calls without a context (friction, restitution). */\n'
            'static int32_t hb_stepping;\n\n'
            + ''.join(f'static void hb_rd_{s}(hb_buffer *b, {s} *v);\nstatic void hb_wr_{s}(hb_buffer *b, const {s} *v);\n' for s in sorted(used))
            + '\n' + '\n'.join(tramps) + '\n' + '\n'.join(c_codecs) + '\n' + '\n'.join(shims))
    hb_h = ('/* Written by tools/gen_box2d.py: helix-box2d\'s calls (hb.c) and buffers (hb_io.c), as Haxe\'s extern declares them. */\n'
            '#ifndef HB_H\n#define HB_H\n\n#include <stdint.h>\n\n#ifdef __cplusplus\nextern "C" {\n#endif\n\n'
            'void *hb_call_words(void);\nint32_t hb_call_capacity(void);\nvoid hb_call_reserve(int32_t words);\n'
            'void *hb_back_words(void);\nint32_t hb_back_capacity(void);\nvoid hb_back_reserve(int32_t words);\n'
            + ''.join(f'void hb_set_hb_cb_{name}(void *f);\n' for name, _, _ in sigs)
            + ''.join(re.match(r'HB_API (.*?) \{', s).group(1) + ';\n' for s in shims)
            + '\n#ifdef __cplusplus\n}\n#endif\n\n#endif\n')
    scratch_fields, dispatchers = callbacks_hx(entries)
    return {'hb.c': hb_c, 'hb.h': hb_h, 'Hb.hx': hb_hx(externs), 'Calls.hx': calls_hx(calls, hx_codecs), 'Init.hx': init_hx(inits),
            'Dispatch.hx': dispatch_hx(scratch_fields, dispatchers, sigs)}


HAXE_TYPES = None


def needed_structs():
    """Every struct a call or a callback carries as words, with the structs it holds."""
    global HAXE_TYPES
    HAXE_TYPES = {s for s in M.structs if s not in ('b2ReplayInfo', 'b2ReplayQueryHit', 'b2ReplayQueryInfo', 'b2MoverJointDef', 'b2PogoJointDef',
                                                    'b2PlaneResult', 'b2CollisionPlane', 'b2PlaneSolverResult', 'b2BoxCastInput')}
    found = set()

    def add(c):
        if c in found or c not in M.structs or c == 'b2Vec2':
            return
        found.add(c)
        for f in M.fields(c):
            e = element(norm(f['type'])) if f['type'] != 'void(*)' else None
            if e:
                add(e)

    for s in HAXE_TYPES:
        add(s)
    return found & HAXE_TYPES


def hb_hx(externs):
    return ('package helix.box2d.internal;\n\n/** Written by tools/gen_box2d.py: helix-box2d\'s calls (hb.h), natively compiled with the program by hxcpp, in a page the\n'
            '\texports of the loaded box2d.wasm, which `Box2D.loadAsync` puts in the global `helixBox2d`. */\n'
            '#if cpp\n@:include("hb.h")\n'
            '@:buildXml("<set name=\'HELIX_BOX2D\' value=\'${haxelib:helix-box2d}\' unless=\'HELIX_BOX2D\'/>\n'
            '<include name=\'${HELIX_BOX2D}/vendor/box2d/files.xml\'/>\n'
            '<files id=\'haxe\'><compilerflag value=\'-I${HELIX_BOX2D}/src/helix/box2d/internal\'/></files>\n'
            '<target id=\'haxe\'><files id=\'helix-box2d\'/></target>")\n#else\n@:native("helixBox2d")\n#end\n@:noCompletion\nextern class Hb {\n'
            + '\n'.join(externs) + '\n}\n')


def calls_hx(calls, codecs):
    return ('package helix.box2d.internal;\n\nimport helix.box2d.*;\n\n/** Written by tools/gen_box2d.py: each of Box2D\'s functions helix-box2d has, its arguments written to the call buffer\n'
            '\tor passed as numbers, its results read back, and each struct\'s words. */\n@:noCompletion\nclass Calls {\n'
            + '\n'.join(calls) + '\n' + '\n'.join(codecs) + '}\n')


def init_hx(inits):
    return ('package helix.box2d.internal;\n\nimport helix.box2d.*;\n\n/** Written by tools/gen_box2d.py: each struct\'s fields made by its constructor, numbers zero and structs new. */\n'
            '@:noCompletion\nclass Init {\n' + '\n'.join(inits) + '}\n')


def dispatch_hx(scratch_fields, dispatchers, sigs):
    hook = []
    for name, _, _ in sigs:
        hook.append(f'\t\tuntyped __cpp__("hb_set_hb_cb_{name}((void *){{0}})", cpp.Callable.fromStaticFunction({name}));')
    imports = ',\n'.join(f'\t\t\thb_cb_{name}: {name}' for name, _, _ in sigs)
    return ('package helix.box2d.internal;\n\nimport helix.box2d.*;\nimport helix.box2d.internal.Calls.*;\n\n'
            'private typedef F32 = #if cpp cpp.Float32 #else Float #end;\n\n'
            '/** Written by tools/gen_box2d.py: the Haxe end of each callback Box2D calls, reading its arguments and calling the function\n'
            '\tits slot holds. A struct or an id a callback receives is reused between calls. */\n'
            '#if cpp\n@:cppInclude("hb.h")\n@:cppFileCode("#include <hx/Native.h>")\n#end\n@:noCompletion\nclass Dispatch {\n'
            + '\n'.join(scratch_fields) + '\n\n'
            + '\t/** The callbacks, natively each handed to hb.c, in a page as the module\'s imports. */\n'
            + '\tpublic static function hooks():Dynamic {\n\t\t#if cpp\n' + '\n'.join(hook) + '\n\t\treturn null;\n\t\t#else\n\t\treturn {\n'
            + imports + '\n\t\t};\n\t\t#end\n\t}\n\n' + '\n'.join(dispatchers) + '}\n')


def emsdk_env():
    """The environment Emscripten's emsdk_env.sh sets."""
    home = os.environ.get('HELIX_EMSDK') or os.environ.get('EMSDK') or str(Path.home() / 'toolchains/emsdk')
    script = Path(home) / 'emsdk_env.sh'
    if not script.exists():
        sys.exit(f'gen_box2d: no Emscripten at {home} (HELIX_EMSDK, EMSDK or ~/toolchains/emsdk)')
    out = subprocess.run(['bash', '-c', f'source "{script}" >/dev/null 2>&1 && env -0'], capture_output=True, check=True).stdout
    return dict(line.split('=', 1) for line in out.decode().split('\0') if '=' in line)


def build_wasm():
    """Builds box2d.wasm: each source compiled into build/box2d-wasm once and again only when it or a header changed, then linked."""
    env = emsdk_env()
    flags = ['-Oz', '-std=gnu17', '-ffp-contract=off', '-msimd128', '-msse2', f'-I{VENDOR / "include"}', f'-I{INTERNAL}'] + [f'-D{d}' for d in DEFINES]
    units = [VENDOR / 'src' / s for s in sources()] + [INTERNAL / 'hb.c', INTERNAL / 'hb_io.c']
    headers = max(p.stat().st_mtime for p in list((VENDOR / 'src').glob('*.h')) + list((VENDOR / 'src').glob('*.inl'))
                  + list((VENDOR / 'include').rglob('*.h')) + list(INTERNAL.glob('*.h')))
    OBJECTS.mkdir(parents=True, exist_ok=True)

    def compile_unit(unit):
        target = OBJECTS / (unit.relative_to(ROOT).as_posix().replace('/', '_') + '.o')
        if not target.exists() or target.stat().st_mtime < max(unit.stat().st_mtime, headers):
            subprocess.run(['emcc', *flags, '-c', str(unit), '-o', str(target)], env=env, check=True)
        return target

    with ThreadPoolExecutor(max(1, os.cpu_count() or 1)) as pool:
        objects = list(pool.map(compile_unit, units))
    WASM.parent.mkdir(parents=True, exist_ok=True)
    link = ['emcc', *flags, *map(str, objects), '-o', str(WASM), '--no-entry', '-sSTANDALONE_WASM', '-sFILESYSTEM=0', '-sALLOW_MEMORY_GROWTH=1',
            '-sINITIAL_MEMORY=16777216', '-sSTACK_SIZE=1048576', '-sERROR_ON_UNDEFINED_SYMBOLS=0', '-sSUPPORT_LONGJMP=0']
    subprocess.run(link, env=env, check=True)
    print(f'gen_box2d: {WASM.relative_to(ROOT)}, {WASM.stat().st_size:,} bytes')


def written():
    """Each file this tool writes and its text."""
    files = {VENDOR / 'files.xml': files_xml()}
    for name, text in generate().items():
        files[INTERNAL / name] = text
    return files


def main():
    parser = cli.parser(__doc__)
    parser.add_argument('--vendor', action='store_true', help='vendor the sources again from the pinned archive')
    parser.add_argument('--check', action='store_true', help='fail when a file here is not current')
    args = parser.parse_args()
    if args.check:
        problems = []
        if tree_hash() != pin().get('treeSha256'):
            problems.append(f'{VENDOR.relative_to(ROOT)} is not the pinned release\'s sources (python3 tools/gen_box2d.py --vendor)')
        else:
            for path, text in written().items():
                if not path.exists() or path.read_text(encoding='utf-8') != text:
                    problems.append(f'{path.relative_to(ROOT)} is not current (python3 tools/gen_box2d.py)')
        for problem in problems:
            print(f'gen_box2d: {problem}')
        sys.exit(1 if problems else 0)
    if args.vendor or not (VENDOR / 'src').exists():
        vendor()
        print(f'gen_box2d: tree sha256 {tree_hash()}')
    for path, text in written().items():
        path.write_text(text, encoding='utf-8')
    build_wasm()


if __name__ == '__main__':
    main()
