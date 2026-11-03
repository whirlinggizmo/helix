"""Writes the rig the animation suite reads as web/rig.gltf, to the path its command line names (tools/raylib_parity.py runs it): a two-joint
skin without inverse bind matrices, non-joint nodes above and between the joints, a mesh on a joint without joints of its own, and
animations of each interpolation, keys off the 60 Hz grid, one before its first key."""
import base64, json, math, struct, sys
def quat(axis, deg):
    a = math.radians(deg) / 2; s = math.sin(a); n = math.sqrt(sum(c * c for c in axis))
    return [axis[0] / n * s, axis[1] / n * s, axis[2] / n * s, math.cos(a)]
buf = bytearray(); views = []; accessors = []
def add(fmt, values, comp, typ, count, target=None, minmax=False):
    while len(buf) % 4: buf.append(0)
    off = len(buf); buf.extend(struct.pack('<' + fmt * len(values), *values))
    v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(buf) - off}
    if target: v['target'] = target
    views.append(v)
    a = {'bufferView': len(views) - 1, 'componentType': comp, 'type': typ, 'count': count}
    if minmax:
        a['min'] = [min(values[i::3]) for i in range(3)]; a['max'] = [max(values[i::3]) for i in range(3)]
    accessors.append(a); return len(accessors) - 1
# Mesh 0: a column of quads from y 0 to 2, vertices at y 0, 0.5, ... 2, two a row, the lower bound to J0, the upper to J1, mixed between.
pos, nor, jo, we = [], [], [], []
for r in range(5):
    y = r * 0.5; w1 = min(1, max(0, (y - 0.5) / 1.0))
    for x in (-0.2, 0.2):
        pos += [x, y, 0.1 * r]; nor += [0, 0.28734789, 0.95782629]; jo += [0, 1, 0, 0]; we += [1 - w1, w1, 0, 0]
idx = []
for r in range(4):
    a = r * 2; idx += [a, a + 1, a + 3, a, a + 3, a + 2]
p0 = add('f', pos, 5126, 'VEC3', 10, 34962, True); n0 = add('f', nor, 5126, 'VEC3', 10, 34962)
j0 = add('B', jo, 5121, 'VEC4', 10, 34962); w0 = add('f', we, 5126, 'VEC4', 10, 34962); i0 = add('H', idx, 5123, 'SCALAR', len(idx), 34963)
p1 = add('f', [0, 0, 0, 0.3, 0, 0, 0, 0.3, 0], 5126, 'VEC3', 3, 34962, True); n1 = add('f', [0, 0, 1] * 3, 5126, 'VEC3', 3, 34962)
def sampler(times, values, interp, typ):
    i = add('f', times, 5126, 'SCALAR', len(times)); i_acc = accessors[i]; i_acc['min'] = [min(times)]; i_acc['max'] = [max(times)]
    o = add('f', values, 5126, typ, len(values) // (3 if typ == 'VEC3' else 4))
    return {'input': i, 'output': o, 'interpolation': interp}
# Wave: J0 rotation, cubic spline (in-tangent, value, out-tangent a key); J1 translation, step; J0 scale, linear from 0.1; J1 rotation, linear.
rot_keys = [quat([1, 0, 0], 0), quat([1, 0, 0], 40), quat([0, 0, 1], 25)]
cubic = []
for k, q in enumerate(rot_keys):
    cubic += [0.1 * k, -0.2, 0.05, 0.0] + q + [0.3, 0.1 * k, -0.1, 0.0]
samplers = [
    sampler([0, 0.5, 1.0], cubic, 'CUBICSPLINE', 'VEC4'),
    sampler([0, 0.3, 0.7], [0, 0.7, 0, 0.2, 0.9, 0, -0.1, 0.6, 0.3], 'STEP', 'VEC3'),
    sampler([0.1, 0.9], [1, 1, 1, 1.3, 0.8, 1.1], 'LINEAR', 'VEC3'),
    sampler([0, 0.8333333], quat([0, 1, 0], 0) + quat([0, 1, 0], 70), 'LINEAR', 'VEC4'),
    sampler([0, 0.4, 1.2], [0, 0, 0, 0.1, 0.2, 0.3, 0.3, 0.2, 0.1, 0.5, 0.5, 0.5, 0.1, 0.1, 0.1, 0.0, 0.0, 0.0, -0.1, 0.4, 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 'CUBICSPLINE', 'VEC3'),
]
wave = {'name': 'Wave', 'samplers': samplers[:4] + [samplers[4]], 'channels': [
    {'sampler': 0, 'target': {'node': 1, 'path': 'rotation'}},
    {'sampler': 1, 'target': {'node': 3, 'path': 'translation'}},
    {'sampler': 2, 'target': {'node': 1, 'path': 'scale'}},
    {'sampler': 3, 'target': {'node': 3, 'path': 'rotation'}},
    {'sampler': 4, 'target': {'node': 1, 'path': 'translation'}}]}
still = {'name': 'Still', 'samplers': [sampler([0, 2], [0, 0, 0, 1, 0, 0], 'LINEAR', 'VEC3')], 'channels': [{'sampler': 0, 'target': {'node': 0, 'path': 'translation'}}]}
doc = {
    'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0]}],
    'nodes': [
        {'name': 'Root', 'translation': [0.5, 0, 0], 'rotation': quat([0, 1, 0], 30), 'children': [1, 6]},
        {'name': 'J0', 'translation': [0, 1, 0], 'rotation': quat([1, 0, 0], 10), 'children': [4, 2]},
        {'name': 'Mid', 'translation': [0, 0.5, 0], 'rotation': quat([0, 0, 1], 20), 'children': [3]},
        {'name': 'J1', 'translation': [0, 0.7, 0], 'children': [5]},
        {'name': 'Skinned', 'mesh': 0, 'skin': 0},
        {'name': 'Attached', 'mesh': 1, 'translation': [0.1, 0.2, 0]},
        {'name': 'Plain', 'mesh': 1, 'translation': [-1, 0, 0]},
    ],
    'meshes': [
        {'primitives': [{'attributes': {'POSITION': p0, 'NORMAL': n0, 'JOINTS_0': j0, 'WEIGHTS_0': w0}, 'indices': i0}]},
        {'primitives': [{'attributes': {'POSITION': p1, 'NORMAL': n1}}]},
    ],
    'skins': [{'joints': [1, 3]}],
    'animations': [wave, still],
    'accessors': accessors, 'bufferViews': views,
    'buffers': [{'byteLength': len(buf), 'uri': 'data:application/octet-stream;base64,' + base64.b64encode(bytes(buf)).decode()}],
}
with open(sys.argv[1], 'w') as f:
    f.write(json.dumps(doc))
