"""core_62: raylib 6.2's pure core functions and raymath additions against helix-ray's. One list for both sides (shared/gen.py's syntax),
printed by the helpers in ref.c.in and CoreBits62.hx.in: sha1 and sha256 hash n bytes of 'a' to 'z' over and over, b64 decodes text,
text prints a string, quat a quaternion and mat a matrix. The file functions, written apart on each side (raylib's waiting, helix-ray's
async), follow in the templates.

6.2's fixes: IsFileExtension matches an extension given without its dot (#5071), GetPrevDirectoryPath skips a separator at the end and
takes a short path to its root (#6073), ComputeSHA1 pads with the whole length (#5397, #5957; 5.5's was wrong from 32 bytes),
DecodeDataBase64 stops at text whose length isn't a multiple of 4 (#5170), QuaternionFromVector3ToVector3 takes directions of any length
and opposite ones (#5508, #6230)."""

EXTENSIONS = [('png', 'image.png', '.png'), ('dotless', 'image.png', 'png'), ('upper', 'IMAGE.PNG', '.jpg;.Png'),
              ('dotlessupper', 'a.TXT', 'bmp;TxT'), ('none', 'image', '.png'), ('second', 'a.b.ogg', '.wav;.ogg'),
              ('nomatch', 'a.png', '.pn;.pngx;png.'), ('hidden', '.png', '.png'), ('trailingdot', 'file.', '.png;'),
              ('long', 'a.abcdefghijklmnopqrst', '.abcdefghijklmn'), ('many', 'a.z33', ';'.join(f'.z{i}' for i in range(40))),
              ('within32', 'a.z31', ';'.join(f'.z{i}' for i in range(40)))]
PATHS = ['/a/b/c', '/a/b/', '/a', '/', 'abc', 'a/b', 'C:\\\\raylib\\\\', 'C:\\\\raylib', 'C:\\\\', 'dir/sub/', 'x', '']
HIDDEN = ['.git', 'a/.config', 'a/b', '.', '..', 'a/..', 'plain', '']
ABSOLUTE = ['/usr/bin', 'usr/bin', '', './a', '/']
B64 = [('one', 'YQ=='), ('two', 'YWI='), ('three', 'YWJj'), ('text', 'aGVsbG8gd29ybGQ='), ('bad5', 'YWJjZ'), ('bad6', 'YWJjZA'),
       ('bad7', 'YWJjZGU'), ('stray', 'Y*Jj'), ('three9', 'YWJjYWJjYWJj')]
VECTORS = [('unit', 'V3(1, 0, 0)', 'V3(0, 1, 0)'), ('scaled', 'V3(2, 0, 0)', 'V3(0, 0, 3)'), ('same', 'V3(0, 2, 0)', 'V3(0, 5, 0)'),
           ('opposite', 'V3(1, 0, 0)', 'V3(-1, 0, 0)'), ('oppositez', 'V3(0, 0.5, 2)', 'V3(0, -1, -4)'), ('zero', 'V3(0, 0, 0)', 'V3(1, 0, 0)'),
           ('slant', 'V3(1, 2, 3)', 'V3(-2, 0.5, 1)')]

CASES = []
CASES += [f'flag("ext{n}", IsFileExtension("{f}", "{e}"));' for n, f, e in EXTENSIONS]
CASES += [f'text("prev{i}", GetPrevDirectoryPath("{p}"));' for i, p in enumerate(PATHS)]
CASES += [f'flag("hidden{i}", IsFileHidden("{p}"));' for i, p in enumerate(HIDDEN)]
CASES += [f'flag("absolute{i}", IsPathAbsolute("{p}"));' for i, p in enumerate(ABSOLUTE)]
for n in [0, 1, 3, 31, 32, 55, 56, 63, 64, 100, 200, 300]:
    CASES += [f'sha1("sha1_{n}", {n});', f'sha256("sha256_{n}", {n});']
CASES += [f'b64("b64{n}", "{t}");' for n, t in B64]
CASES += [f'quat("fromto{n}", QuaternionFromVector3ToVector3({a}, {b}));' for n, a, b in VECTORS]
CASES += [
    'num("cross2d", Vector2CrossProduct(V2(1.5, -2), V2(0.25, 3)));',
    'num("cross2dswap", Vector2CrossProduct(V2(0.25, 3), V2(1.5, -2)));',
    'mat("multiplyvalue", MatrixMultiplyValue(NEW(Matrix, 1, -2, 3.5, 4, 0.5, 6, -7, 8, 9, 10.25, -11, 12, -13, 14, 15, 16), -2.5));',
    'mat("compose", MatrixCompose(V3(1, -2, 3), QuaternionFromAxisAngle(V3(0.2, 1, -0.4), 0.9), V3(2, 0.5, -1.5)));',
    'mat("composeidentity", MatrixCompose(V3(0, 0, 0), QuaternionIdentity(), V3(1, 1, 1)));',
    'num("mkdir", MakeDirectory("made/sub"));',
]
