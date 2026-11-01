"""Writes the OBJ files the obj_62 suite reads, and the MTL file and textures the obj suite reads, by the path its command line names
(ray_parity runs it once for each): web/obj/shapes.obj writes web/obj's models, their library and its textures; lib.mtl writes the
library LoadMaterials reads from the working directory, and its textures beside it.

web/obj/shapes.obj: faces before any usemtl, a quad and a pentagon split into fans, a group starting after a polygon (raylib counts the
group's start in faces against its triangles), materials changing within a group and an object, negative numbers, corners without
normals or texture coordinates, a position's w, a usemtl naming no material of the library and one after it (raylib joins them), its
library's materials in another order than they're used, with textures (a diffuse, specular, bump and displacement one, and one
missing), Kd, Ks, Ke and Ns, and materials giving none of them (tinyobj_loader_c's defaults: black, and an Ns of 1), a name given twice
(the last wins), the bump texture's statements (bump and map_bump, the last of them; map_Bump, which tinyobj_loader_c doesn't read).
web/obj/nolib.obj names a library that isn't there: usemtl changes split nothing, and the model has the default material.
web/obj/plain.obj names none: six-value positions (their colors not read), an object and a group starting after a quad.
web/obj/groups.obj splits as tinyobj_loader_c splits shapes: g lines with no faces between, a name given again with faces after
each, o lines, faces of 1 and 2 corners (counted among a group's faces, giving no triangles), a polygon after them, g lines at the end
with no faces after them. web/obj/missing.obj's corners name positions, texture coordinates and normals the file doesn't have, and
ones on lines after the face (raylib 6.2's zeros, (0, 1, 0) normals and (0, 0) texture coordinates; the later lines read).
web/obj/empty.obj is empty, read as a file that can't be read. web/obj/latin.obj and its library latin.mtl are Latin-1 (Windows-1252)
text, a material named with é (0xE9): tinyobj_loader_c matches the names' bytes, helix-formats their characters."""
import struct, sys, zlib
from pathlib import Path


def png(width, height, pixel):
    """A PNG of 8-bit RGBA pixels, each pixel(x, y) a tuple, every row filtered by none."""
    rows = b''.join(b'\0' + bytes(c for x in range(width) for c in pixel(x, y)) for y in range(height))
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    header = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')


TEXTURES = {
    'red.png': png(3, 2, lambda x, y: (200 + 20 * x, 30 * y, 10 * x, 255 - 50 * y)),
    'spec.png': png(2, 2, lambda x, y: (90 * x, 90 * y, 120, 255)),
    'normal.png': png(2, 1, lambda x, y: (128 + 60 * x, 128, 255, 255)),
    'height.png': png(1, 3, lambda x, y: (60 * y, 60 * y, 60 * y, 255)),
}

LIBRARY = """# materials, in another order than shapes.obj uses them
newmtl blue
Kd 0.1 0.2 0.9
Ks 0.5 0.5 0.5
Ke 0 0 0.25
Ns 32
newmtl red
Kd 0.8 0.1 0.1
Ks 0.25 0.3 0.35
Ke 0.1 0 0
Ns 96.078431
map_Kd red.png
map_Ks spec.png
bump normal.png
disp height.png
newmtl green
Kd 0.2 0.7 0.3
Ks 0 0 0
Ns 10
map_Kd missing.png
newmtl spare
Kd 1 0.5 0.25
Ks 0.6 0.6 0.6
Ns 0.5
newmtl bare
newmtl bumpy
Kd 0.5 0.5 0.5
bump spec.png
map_Bump red.png
map_bump normal.png
newmtl blender
Ks 0.2 0.4 0.6
map_Bump normal.png
newmtl spare
Kd 0.25 0.75 0.5
Ns 7
"""

SHAPES = """# shapes.obj
mtllib shapes.mtl
v 0 0 0
v 1 0 0 1
v 1 1 0
v 0 1 0
v 0.5 1.5 0.25
v 0.25 0.125 -0.5
v 2 0 1
v 2.5 0.75 1.5
vt 0 0
vt 1 0
vt 1 1
vt 0 1
vt 0.25 0.75
vn 0 0 1
vn 0 1 0
vn 0.6 0 0.8
f 1/1/1 2/2/1 3/3/1
usemtl red
f 1/1/1 2/2/1 3/3/1 4/4/1
f 3/3/3 5/5/3 4/4/3
g wall
usemtl blue
f -3/-1/-2 -2/-2/-2 -1/-3/-2
usemtl red
f 6/5 7/4 8/3
o thing
usemtl green
f 1 2 3 4 5
usemtl nowhere
f 5 6 7
usemtl blue
f 6 7 8
"""

NOLIB = """mtllib nothere.mtl
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
vt 0 0
vt 1 0
vt 1 1
vt 0 1
vn 0 0 1
usemtl a
f 1/1/1 2/2/1 3/3/1
usemtl b
f 1/1/1 3/3/1 4/4/1
"""

PLAIN = """o plain
v 0 0 0 1 0 0
v 1 0 0 0 1 0
v 1 1 0 0 0 1
v 0 1 0 1 1 1
vt 0.5 0.5
f 1/1 2/1 3/1 4/1
g one
f 1 2 3
"""

GROUPS = """mtllib shapes.mtl
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
vt 0 0
vt 1 1
vn 0 0 1
g a
g b
usemtl bare
f 1/1/1 2/2/1 3/1/1
g a
f 1 3 4
g a
f 2 3 4
f 1 2
g c
f 1 2 3 4
g lone
f 2
g after
f 1 2 3
o thing
f 1 2 3
o thing
g d
f 4 3 2
usemtl spare
f 1 2 3
usemtl bumpy
f 1 2 3
usemtl blender
f 1 3 4
g e
g f
"""

MISSING = """v 0 0 0
vt 0.5 0.25
f 2/1/1 3/2 9//1
v 1 0 0
v 0 1 0
vn 0 0 1
f -1/-1/-1 -5/-3/-2 1/1/1
f 1/1/2 2/1/1 3/7/1
"""

LATIN_OBJ = """mtllib latin.mtl
v 0 0 0
v 1 0 0
v 0 1 0
usemtl café
f 1 2 3
usemtl crème
f 1 3 2
"""

LATIN_MTL = """newmtl crème
Kd 0.9 0.8 0.6
newmtl café
Kd 0.4 0.25 0.1
Ns 12
"""

destination = Path(sys.argv[1])
directory = destination.parent
directory.mkdir(parents=True, exist_ok=True)
if destination.name == 'shapes.obj':
    files = {'shapes.obj': SHAPES, 'shapes.mtl': LIBRARY, 'nolib.obj': NOLIB, 'plain.obj': PLAIN, 'groups.obj': GROUPS, 'missing.obj': MISSING,
             'empty.obj': ''}
    for name, text in files.items():
        (directory / name).write_text(text, encoding='utf-8')
    (directory / 'latin.obj').write_text(LATIN_OBJ, encoding='latin-1')
    (directory / 'latin.mtl').write_text(LATIN_MTL, encoding='latin-1')
elif destination.name == 'lib.mtl':
    destination.write_text(LIBRARY, encoding='utf-8')
else:
    raise SystemExit(f'makeobj.py: no file {destination.name}')
for name, data in TEXTURES.items():
    (directory / name).write_bytes(data)
