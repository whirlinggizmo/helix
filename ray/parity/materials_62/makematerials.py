"""Writes the model the materials_62 suite reads as web/materials.gltf, to the path its command line names (tools/ray_parity.py runs it):
a triangle on each of four materials, its images PNGs held as data: URIs. "full" has every texture glTF's metallic-roughness flow names
and its factors, its metallic-roughness image RGB, green and blue different at each pixel; "factors" has factors and no textures;
"bare" has a normal and an emissive texture but no pbrMetallicRoughness block; "split" has a metallic-roughness texture alone."""
import base64, json, struct, sys, zlib


def png(width, height, channels, pixel):
    """A PNG of 8-bit RGB (3) or RGBA (4) pixels, each pixel(x, y) a tuple, every row filtered by none."""
    rows = b''.join(b'\0' + bytes(c for x in range(width) for c in pixel(x, y)) for y in range(height))
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    header = struct.pack('>IIBBBBB', width, height, 8, 6 if channels == 4 else 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')


images = [
    # Base color, 4x2, alpha changing.
    png(4, 2, 4, lambda x, y: (40 * x + 10, 90 * y + 20, 200 - 30 * x, 255 - 60 * x - 40 * y)),
    # Metallic-roughness, 3x2, RGB: red unused, green the roughness, blue the metalness, apart at each pixel.
    png(3, 2, 3, lambda x, y: (7, 30 + 50 * x + 11 * y, 240 - 70 * x - 23 * y)),
    # Normal, 2x2.
    png(2, 2, 4, lambda x, y: (128 + 60 * x, 128 - 50 * y, 255, 255)),
    # Occlusion, 2x3.
    png(2, 3, 4, lambda x, y: (60 + 90 * x + 30 * y, 0, 0, 255)),
    # Emissive, 3x1.
    png(3, 1, 4, lambda x, y: (250 * (x == 0), 250 * (x == 1), 250 * (x == 2), 255)),
]
buffer = struct.pack('<9f', 0, 0, 0, 1, 0, 0, 0, 1, 0)
doc = {
    'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0, 1, 2, 3]}],
    'nodes': [{'mesh': i} for i in range(4)],
    'meshes': [{'primitives': [{'attributes': {'POSITION': 0}, 'material': i}]} for i in range(4)],
    'materials': [
        {'name': 'full', 'pbrMetallicRoughness': {'baseColorFactor': [0.6, 0.2, 0.9, 0.5], 'baseColorTexture': {'index': 0},
                                                  'metallicFactor': 0.3, 'roughnessFactor': 0.7, 'metallicRoughnessTexture': {'index': 1}},
         'normalTexture': {'index': 2}, 'occlusionTexture': {'index': 3}, 'emissiveTexture': {'index': 4},
         'emissiveFactor': [0.25, 0.6, 1.0]},
        {'name': 'factors', 'pbrMetallicRoughness': {'baseColorFactor': [0.1, 0.35, 0.6, 0.85], 'metallicFactor': 0.45,
                                                     'roughnessFactor': 0.15}, 'emissiveFactor': [0.5, 0.5, 0.5]},
        {'name': 'bare', 'normalTexture': {'index': 2}, 'emissiveTexture': {'index': 4}, 'emissiveFactor': [1, 0, 0]},
        {'name': 'split', 'pbrMetallicRoughness': {'metallicRoughnessTexture': {'index': 1}}},
    ],
    'textures': [{'source': i} for i in range(5)],
    'images': [{'uri': 'data:image/png;base64,' + base64.b64encode(p).decode()} for p in images],
    'buffers': [{'byteLength': len(buffer), 'uri': 'data:application/octet-stream;base64,' + base64.b64encode(buffer).decode()}],
    'bufferViews': [{'buffer': 0, 'byteOffset': 0, 'byteLength': len(buffer), 'target': 34962}],
    'accessors': [{'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3', 'min': [0, 0, 0], 'max': [1, 1, 0]}],
}
with open(sys.argv[1], 'w') as f:
    json.dump(doc, f)
