"""core_62: raylib 6.2's pure core functions and raymath's QuaternionFromVector3ToVector3 against helix-raylib's. One list for both sides
(shared/gen.py's syntax), printed by the helpers in ref.c.in and CoreBits62.hx.in: sha1 hashes n bytes of 'a' to 'z' over and over, b64
decodes text, text prints a string and quat a quaternion.

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
B64 = [('one', 'YQ=='), ('two', 'YWI='), ('three', 'YWJj'), ('text', 'aGVsbG8gd29ybGQ='), ('bad5', 'YWJjZ'), ('bad6', 'YWJjZA'),
       ('bad7', 'YWJjZGU'), ('stray', 'Y*Jj'), ('three9', 'YWJjYWJjYWJj')]
VECTORS = [('unit', 'V3(1, 0, 0)', 'V3(0, 1, 0)'), ('scaled', 'V3(2, 0, 0)', 'V3(0, 0, 3)'), ('same', 'V3(0, 2, 0)', 'V3(0, 5, 0)'),
           ('opposite', 'V3(1, 0, 0)', 'V3(-1, 0, 0)'), ('oppositez', 'V3(0, 0.5, 2)', 'V3(0, -1, -4)'), ('zero', 'V3(0, 0, 0)', 'V3(1, 0, 0)'),
           ('slant', 'V3(1, 2, 3)', 'V3(-2, 0.5, 1)')]

CASES = []
CASES += [f'flag("ext{n}", IsFileExtension("{f}", "{e}"));' for n, f, e in EXTENSIONS]
CASES += [f'text("prev{i}", GetPrevDirectoryPath("{p}"));' for i, p in enumerate(PATHS)]
for n in [0, 1, 3, 31, 32, 55, 56, 63, 64, 100, 200, 300]:
    CASES += [f'sha1("sha1_{n}", {n});']
CASES += [f'b64("b64{n}", "{t}");' for n, t in B64]
CASES += [f'quat("fromto{n}", QuaternionFromVector3ToVector3({a}, {b}));' for n, a, b in VECTORS]
CASES += [
    'num("mkdir", MakeDirectory("made/sub"));',
]
