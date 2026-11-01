"""images_62: the image functions helix-ray takes from raylib 6.2 (docs/DECISIONS.md 24), their images compared byte for byte: those 6.2
fixed (lines, thick lines, circles, the convolution and the blur, a rectangle of an image, the pixel reads and sizes, text with no text),
those reading through them (ImageFormat from R32 and R16, ImageDraw from R5G5B5A1, the triangle outline), and 6.2's own (the
ImageDrawImage family, the line strip, gradients, the turned rectangle, LoadRenderTextureEx). One list for both sides (shared/gen.py's
syntax): A, B, C and D are colors, sharpen, ones, box5 and edge4 kernels, noise(width, height, seed) an RGBA image of noise and
noiseIn(width, height, seed, format) one in a format, all made in ref.c.in and ImageBits.hx.in. Each case's image is a local of its own
block. A case named for a bug is built from the input that shows it."""


def drawn(name, statements, width=48, height=32, seed=1):
    """A case drawing into a noise image i, then printing it."""
    return f'{{ LET(i, Image, noise({width}, {height}, {seed})); {statements} image("{name}", i); }}'


CASES = [
    # #5896: the end pixel drawn and the minor axis rounded, where 5.5 left the end out and truncated.
    drawn('line', 'ImageDrawLine(OUT(i), 5, 30, 40, 2, A);'),
    drawn('lineback', 'ImageDrawLine(OUT(i), 40, 2, 5, 30, A);'),
    drawn('linesteep', 'ImageDrawLine(OUT(i), 10, 1, 17, 30, B);'),
    drawn('linesteepback', 'ImageDrawLine(OUT(i), 17, 30, 10, 1, B);'),
    drawn('lineclipped', 'ImageDrawLine(OUT(i), -20, -5, 80, 60, A);'),
    drawn('linepoint', 'ImageDrawLine(OUT(i), 7, 9, 7, 9, A);'),
    drawn('linev', 'ImageDrawLineV(OUT(i), V2(3.4, 4.6), V2(44.5, 20.49), C);'),
    drawn('trianglelines', 'ImageDrawTriangleLines(OUT(i), V2(10.5, 3.25), V2(40.75, 20.5), V2(2.5, 30.125), B);'),
    # #5042: as many lines as it is thick, where 5.5 drew an odd count scaled by the line's slope.
    drawn('lineex', 'ImageDrawLineEx(OUT(i), V2(5.3, 28.6), V2(40.5, 2.2), 6, A);'),
    drawn('lineex4', 'ImageDrawLineEx(OUT(i), V2(4, 16), V2(44, 16), 4, A);'),
    drawn('lineex1', 'ImageDrawLineEx(OUT(i), V2(4, 16), V2(44, 20), 1, A);'),
    drawn('lineex0', 'ImageDrawLineEx(OUT(i), V2(4, 16), V2(44, 20), 0, A);'),
    drawn('lineexdown', 'ImageDrawLineEx(OUT(i), V2(20, 2), V2(23, 30), 3, B);'),
    drawn('lineexdiagonal', 'ImageDrawLineEx(OUT(i), V2(2, 2), V2(30, 30), 5, C);'),
    drawn('lineexpoint', 'ImageDrawLineEx(OUT(i), V2(10, 10), V2(10.2, 10.3), 5, C);'),
    drawn('linestrip', 'ImageDrawLineStrip(OUT(i), PTS(V2(2, 2), V2(30, 5.5), V2(12, 28), V2(45, 30)), 4, D);'),
    drawn('linestripshort', 'ImageDrawLineStrip(OUT(i), PTS(V2(2, 2)), 1, D);'),
    # #6118: each row as wide either side of the middle, where 5.5's were a pixel short on the right.
    drawn('circle', 'ImageDrawCircle(OUT(i), 20, 14, 9, A);'),
    drawn('circleedge', 'ImageDrawCircle(OUT(i), 44, 30, 12, B);'),
    drawn('circlezero', 'ImageDrawCircle(OUT(i), 20, 14, 0, A);'),
    drawn('circlev', 'ImageDrawCircleV(OUT(i), V2(24.7, 15.2), 6, C);'),
    drawn('circlelines', 'ImageDrawCircleLines(OUT(i), 20, 14, 9, A);'),
    drawn('circlegradient', 'ImageDrawCircleGradient(OUT(i), V2(20.5, 14.25), 11.5, A, D);'),
    drawn('circlegradientedge', 'ImageDrawCircleGradient(OUT(i), V2(44, 2), 9, C, B);'),
    drawn('circlegradientnone', 'ImageDrawCircleGradient(OUT(i), V2(20, 14), 0, C, B);'),
    drawn('rectanglegradient', 'ImageDrawRectangleGradientEx(OUT(i), R(4.5, 3.25, 30, 20.5), A, B, C, D);'),
    drawn('rectanglegradientclipped', 'ImageDrawRectangleGradientEx(OUT(i), R(-6, -4, 30, 20), A, B, C, D);'),
    drawn('rectanglegradientnone', 'ImageDrawRectangleGradientEx(OUT(i), R(4, 3, 0, 20), A, B, C, D);'),
    drawn('rectanglelinesex', 'ImageDrawRectangleLinesEx(OUT(i), R(4.5, 3.75, 30, 20), 3, B);'),
    drawn('rectanglepro', 'ImageDrawRectanglePro(OUT(i), R(24, 16, 20, 10), V2(10, 5), 30, A);'),
    drawn('rectanglepro0', 'ImageDrawRectanglePro(OUT(i), R(4.5, 3.5, 20, 10), V2(0, 0), 0, B);'),
    drawn('rectangleproturned', 'ImageDrawRectanglePro(OUT(i), R(40, 4, 30, 8), V2(-2, 3), -115, C);'),
    drawn('triangle', 'ImageDrawTriangle(OUT(i), V2(10.5, 3.25), V2(40.75, 20.5), V2(2.5, 30.125), A);'),
    drawn('trianglegradient', 'ImageDrawTriangleGradient(OUT(i), V2(4, 3), V2(44, 10), V2(20, 30), A, B, C);'),
    # #6192: taps past an edge taken from the edge, and alpha clamped, where 5.5 wrapped into the next row, read 0 past the top and
    # bottom, and left alpha unclamped.
    drawn('convolution', 'ImageKernelConvolution(OUT(i), sharpen, 9);', 20, 12),
    drawn('convolutionones', 'ImageKernelConvolution(OUT(i), ones, 9);', 20, 12),
    drawn('convolution5', 'ImageKernelConvolution(OUT(i), box5, 25);', 20, 12),
    drawn('convolutioneven', 'ImageKernelConvolution(OUT(i), edge4, 4);', 20, 12),
    drawn('convolutionnotsquare', 'ImageKernelConvolution(OUT(i), sharpen, 8);', 20, 12),
    # #5037: channels taken back from premultiplied alpha no higher than 255, where 5.5 overflowed.
    drawn('blur', 'ImageBlurGaussian(OUT(i), 2);', 24, 16),
    drawn('blur1', 'ImageBlurGaussian(OUT(i), 1);', 24, 16, 7),
    # #5979: a rectangle not wholly inside gives an empty image, where 5.5 read past the pixels.
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimage", ImageFromImage(i, R(3, 2, 8, 5))); }',
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimagefraction", ImageFromImage(i, R(3.7, 2.2, 8.9, 5.5))); }',
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimagewide", ImageFromImage(i, R(10, 2, 8, 5))); }',
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimagenegative", ImageFromImage(i, R(-1, 2, 8, 5))); }',
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimageempty", ImageFromImage(i, R(3, 2, 0, 5))); }',
    '{ LET(i, Image, noise(16, 12, 3)); image("fromimagewhole", ImageFromImage(i, R(0, 0, 16, 12))); }',
    '{ LET(i, Image, noiseIn(16, 12, 3, PIXELFORMAT_UNCOMPRESSED_R5G6B5)); image("fromimage565", ImageFromImage(i, R(3, 2, 8, 5))); }',
    # CLN-013: 0 for no size, and integer bits.
    'num("datasize", GetPixelDataSize(13, 7, PIXELFORMAT_UNCOMPRESSED_R8G8B8));',
    'num("datasizezero", GetPixelDataSize(0, 7, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8));',
    'num("datasizenegative", GetPixelDataSize(-4, -4, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8));',
    'num("datasizedxt", GetPixelDataSize(5, 3, PIXELFORMAT_COMPRESSED_DXT1_RGB));',
    'num("datasizesmall", GetPixelDataSize(2, 2, PIXELFORMAT_COMPRESSED_DXT5_RGBA));',
    'num("datasizeastc", GetPixelDataSize(9, 9, PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA));',
    'num("datasizehuge", GetPixelDataSize(50000, 50000, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8));',
    # #5560: R32G32B32A32's and R16G16B16A16's channels each read from their own place, where 5.5 read all four from red.
    '{ LET(i, Image, noiseIn(8, 4, 5, PIXELFORMAT_UNCOMPRESSED_R32G32B32A32)); color("color32", GetImageColor(i, 3, 2)); '
        'color("color32b", GetImageColor(i, 0, 0)); }',
    '{ LET(i, Image, noiseIn(8, 4, 5, PIXELFORMAT_UNCOMPRESSED_R16G16B16A16)); color("color16", GetImageColor(i, 3, 2)); '
        'color("color16b", GetImageColor(i, 7, 3)); }',
    '{ LET(i, Image, noiseIn(8, 4, 5, PIXELFORMAT_UNCOMPRESSED_R32)); color("colorr32", GetImageColor(i, 3, 2)); }',
    '{ LET(i, Image, noiseIn(8, 4, 5, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); color("color5551", GetImageColor(i, 3, 2)); }',
    '{ LET(i, Image, noiseIn(8, 4, 5, PIXELFORMAT_UNCOMPRESSED_R4G4B4A4)); color("color4444", GetImageColor(i, 3, 2)); }',
    '{ LET(i, Image, noise(8, 4, 5)); color("colorout", GetImageColor(i, 8, 2)); }',
    # #4745: R32 and R16 read pixel by pixel, where 5.5 read every pixel from the first.
    '{ LET(i, Image, noiseIn(12, 6, 9, PIXELFORMAT_UNCOMPRESSED_R32)); ImageFormat(OUT(i), PIXELFORMAT_UNCOMPRESSED_R8G8B8A8); image("formatr32", i); }',
    '{ LET(i, Image, noiseIn(12, 6, 9, PIXELFORMAT_UNCOMPRESSED_R16)); ImageFormat(OUT(i), PIXELFORMAT_UNCOMPRESSED_R8G8B8A8); image("formatr16", i); }',
    '{ LET(i, Image, noiseIn(12, 6, 9, PIXELFORMAT_UNCOMPRESSED_R32)); ImageFormat(OUT(i), PIXELFORMAT_UNCOMPRESSED_GRAYSCALE); image("formatr32gray", i); }',
    # #6113: R5G5B5A1's blue from its own bits, where 5.5 took in the alpha bit: drawn from, and read.
    '{ LET(i, Image, noise(24, 16, 1)); LET(s, Image, noiseIn(24, 16, 11, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); '
        'ImageDrawImage(OUT(i), s, 2, 3, WHITE); image("draw5551", i); }',
    '{ LET(i, Image, noise(24, 16, 1)); LET(s, Image, noiseIn(24, 16, 11, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); '
        'ImageDrawImage(OUT(i), s, 2, 3, C); image("draw5551tinted", i); }',
    '{ LET(i, Image, noiseIn(24, 16, 1, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); LET(s, Image, noise(24, 16, 11)); '
        'ImageDrawImage(OUT(i), s, -3, 2, WHITE); image("drawinto5551", i); }',
    '{ LET(s, Image, noiseIn(4, 2, 11, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); color("pixel5551", GetPixelColor(s.data, PIXELFORMAT_UNCOMPRESSED_R5G5B5A1)); }',
    # ImageDraw, raylib 6's ImageDrawImagePro, and the rest of its family.
    {'c': '{ Image i = noise(48, 32, 1); Image s = noise(20, 16, 4); ImageDrawImagePro(&i, s, R(2, 3, 12, 10), R(10.5, 7.75, 12, 10), V2(0, 0), 0, D); '
          'image("draw", i); }',
     'hx': '{ var i = noise(48, 32, 1); var s = noise(20, 16, 4); ImageDraw(i, s, R(2, 3, 12, 10), R(10.5, 7.75, 12, 10), D); image("draw", i); }'},
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(20, 16, 4)); ImageDrawImage(OUT(i), s, 40, -5, WHITE); image("drawimage", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(20, 16, 4)); ImageDrawImageRec(OUT(i), s, R(-2, 4, 12, 30), V2(3.5, 6), B); '
        'image("drawimagerec", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(20, 16, 4)); ImageDrawImagePro(OUT(i), s, R(2, 3, 12, 10), R(-4, 20, 12, 10), V2(3, 4), 45, D); '
        'image("drawimagepro", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noiseIn(20, 16, 4, PIXELFORMAT_UNCOMPRESSED_R8G8B8)); '
        'ImageDrawImage(OUT(i), s, 5, 5, WHITE); image("drawimageopaque", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(12, 8, 4)); ImageDrawImageEx(OUT(i), s, V2(10, 4), 0, 1, WHITE); image("drawimageex", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(12, 8, 4)); ImageDrawImageEx(OUT(i), s, V2(20.5, 2.25), 30, 1.5, D); '
        'image("drawimageexturned", i); }',
    '{ LET(i, Image, noise(48, 32, 1)); LET(s, Image, noise(12, 8, 4)); ImageDrawImageEx(OUT(i), s, V2(40, 28), 200, 0.75, C); '
        'image("drawimageexback", i); }',
    '{ LET(i, Image, noiseIn(48, 32, 1, PIXELFORMAT_UNCOMPRESSED_R5G6B5)); LET(s, Image, noise(12, 8, 4)); '
        'ImageDrawImageEx(OUT(i), s, V2(4, 4), -60, 2, WHITE); image("drawimageexinto565", i); }',
    # ImageDrawTextPro is still to be written in 6.2: the image is left as it is.
    '{ LET(i, Image, noise(16, 8, 1)); ImageDrawTextPro(OUT(i), GetFontDefault(), "Hi", V2(1, 1), V2(0, 0), 30, 10, 1, A); image("textpro", i); }',
    # Text: none gives an image of none, or a black one.
    {'c': 'image("textnull", ImageTextEx(GetFontDefault(), NULL, 20, 2, A)); image("gentextnull", GenImageText(6, 3, NULL));',
     'hx': 'image("textnull", ImageTextEx(GetFontDefault(), null, 20, 2, A)); image("gentextnull", GenImageText(6, 3, null));'},
    'image("gentext", GenImageText(6, 3, "hello raylib"));',
    'image("text", ImageTextEx(GetFontDefault(), "Hi!", 10, 1, A));',
    'image("textscaled", ImageText("Ab", 20, B));',
    # A render texture in a format: RGBA is made, a compressed format isn't.
    'flag("rendertexture", IsRenderTextureValid(LoadRenderTextureEx(16, 8, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)));',
    'flag("rendertexturedxt", IsRenderTextureValid(LoadRenderTextureEx(16, 8, PIXELFORMAT_COMPRESSED_DXT1_RGB)));',
]
