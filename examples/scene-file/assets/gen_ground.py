"""The ground under the track: a one-quad glTF binary (kit/ground.glb), a unit square on y = 0 facing up, green, rough. The scene file
scales it to the world. Made here because a scene file's Model needs a file (no mesh is made from code), and the kit has no plain grass
tile. Run by tools/example.py when the file is missing; committed so a build needs nothing."""
import json
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / 'kit' / 'ground.glb'


def generate():
    """Writes kit/ground.glb when it is missing."""
    if OUT.is_file():
        return
    positions = [(-.5, 0, -.5), (.5, 0, -.5), (.5, 0, .5), (-.5, 0, .5)]
    normals = [(0, 1, 0)] * 4
    uvs = [(0, 0), (1, 0), (1, 1), (0, 1)]
    indices = [0, 2, 1, 0, 3, 2]
    binary = b''
    views = []

    def view(data, target):
        nonlocal binary
        views.append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data), 'target': target})
        binary += data + b'\0' * (-len(data) % 4)
        return len(views) - 1

    position_view = view(b''.join(struct.pack('<3f', *p) for p in positions), 34962)
    normal_view = view(b''.join(struct.pack('<3f', *n) for n in normals), 34962)
    uv_view = view(b''.join(struct.pack('<2f', *t) for t in uvs), 34962)
    index_view = view(b''.join(struct.pack('<H', i) for i in indices), 34963)
    gltf = {
        'asset': {'version': '2.0', 'generator': 'HeliX examples/scene-file/assets/gen_ground.py'},
        'scene': 0,
        'scenes': [{'name': 'ground', 'nodes': [0]}],
        'nodes': [{'name': 'ground', 'mesh': 0}],
        'meshes': [{'name': 'ground', 'primitives': [{'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2}, 'indices': 3, 'material': 0}]}],
        'materials': [{'name': 'grass', 'pbrMetallicRoughness': {'baseColorFactor': [.33, .52, .2, 1], 'metallicFactor': 0, 'roughnessFactor': 1}}],
        'accessors': [
            {'bufferView': position_view, 'componentType': 5126, 'count': 4, 'type': 'VEC3', 'min': [-.5, 0, -.5], 'max': [.5, 0, .5]},
            {'bufferView': normal_view, 'componentType': 5126, 'count': 4, 'type': 'VEC3'},
            {'bufferView': uv_view, 'componentType': 5126, 'count': 4, 'type': 'VEC2'},
            {'bufferView': index_view, 'componentType': 5123, 'count': 6, 'type': 'SCALAR'},
        ],
        'bufferViews': views,
        'buffers': [{'byteLength': len(binary)}],
    }
    text = json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    text += b' ' * (-len(text) % 4)
    length = 12 + 8 + len(text) + 8 + len(binary)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, length))
        f.write(struct.pack('<I4s', len(text), b'JSON'))
        f.write(text)
        f.write(struct.pack('<I4s', len(binary), b'BIN\0'))
        f.write(binary)


if __name__ == '__main__':
    generate()
