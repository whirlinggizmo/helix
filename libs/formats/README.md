# helix-formats

File formats read into plain data, and written from it: bytes or text in, typed data out, and pixels in, a file's bytes out. Pure Haxe,
with no I/O: a program reads the file, hands its bytes to a parser, and loads whatever other files the data names (a model's buffers and
images, a font's pages) itself; it saves what a writer returns. Depends on helix-math (a glTF node's transform is a `Matrix3D`).

- `gltf.GltfFile`: a glTF 2.0 model, from a .gltf or a GLB: its nodes and their transforms, the default scene, meshes (positions,
  normals, texture coordinates, colors, indices), metallic-roughness materials and images. Buffers held in the file are read at once;
  those in files of their own are listed, their paths resolved, for the program to fetch and set. Skins and animations aren't read yet.
- `obj.ObjFile` and `obj.MtlFile`: a Wavefront OBJ model (.obj) and its material libraries (.mtl): positions (and the six-value
  positions' colors), texture coordinates and normals, faces as the file writes them, their groups and materials, split into
  triangles and gathered into parts; each material's colors, factors and texture paths, the PBR extension's too. The libraries a
  model names are listed, their paths resolved, for the program to fetch and read.
- `bmfont.BmFontFile`: an AngelCode BMFont text file (.fnt): its size and line metrics, pages, glyphs and kerning pairs.
- `truetype.TrueTypeTables`: a TrueType or OpenType font's tables as stb_truetype reads them: vertical metrics, each codepoint's
  glyph, advances and boxes. helix-platform's canvas font rasterizer places its glyphs with it.
- `png.PngFile`: writes a PNG from 8-bit pixels of 1 to 4 channels, byte for byte as raylib 5.5's `ExportImage` does
  (stb_image_write's writer).
- `qoi.QoiFile`: a QOI image ("Quite OK Image"), read and written byte for byte as raylib 5.5 does (qoi.h's).
- `gif.GifFile`: a GIF file (GIF87a or GIF89a): its screen, color tables, loop count (NETSCAPE2.0) and every frame as the file gives
  it (its rectangle, color indices with interlaced rows put in order, transparent index, disposal and delay), and the frames
  composited onto the screen as RGBA, as a browser shows them.
- `qoa.QoaFile`: a QOA sound ("Quite OK Audio"): its rate, channels and 16-bit samples, read as raylib 5.5 does (qoa.h's), bit for bit.
- `deflate.Deflate`: DEFLATE compression, byte for byte as raylib 5.5's `CompressData` compresses (sdefl's).
- `wav.WavFile`: a WAV file's sound, read as raylib 5.5's `LoadWave` reads it (dr_wav's: integer, floating-point, A-law and mu-law
  samples, its 16-bit samples identical) and written byte for byte as its `ExportWave` writes one.
- `audio.AudioHeader`: a sound file's length in seconds, its channels and its rate from its first bytes (and its last, for Ogg's length),
  without decoding it: WAV, Ogg (Vorbis, Opus, FLAC, Speex), FLAC and MP3.

```haxe
import helix.formats.gltf.GltfFile;

var model = GltfFile.read(bytes, "models/ship.gltf");
for (missing in model.missingBuffers)
	model.setBuffer(missing.bufferIndex, fetched(missing.path));
for (mesh in model.meshes)
	for (primitive in mesh.primitives)
		trace(primitive.positions.length / 3, primitive.materialIndex);
```

## Using it

```
-lib helix-formats
```

The API reference is [api/](api/README.md). Its tests, in `tests/`, build with `-lib helix-formats` alone, from this repository's root: `TrueTypeTests` embeds the font
in `tests/assets` as it compiles, and `GifTests` the GIF files in `tests/assets/gif`.

## Credit

`TrueTypeTables` reads a font's tables as [stb_truetype](https://github.com/nothings/stb), by Sean Barrett, reads them (public
domain); no code of it is included. `BmFontFile` reads [AngelCode BMFont](https://www.angelcode.com/products/bmfont/)'s text format as
documented, and the fields raylib 5.5's `LoadBMFont` reads.
`PngFile` is [stb_image_write](https://github.com/nothings/stb) 1.16's PNG writer, by Sean Barrett, ported; `QoiFile` is
[qoi.h](https://github.com/phoboslab/qoi), Copyright (c) 2021 Dominic Szablewski, ported; `Deflate` is
[sdefl](https://github.com/vurtun/lib) 1.0, Copyright (c) 2020-2023 Micha Mettke, ported; `WavFile` is
[dr_wav](https://github.com/mackron/dr_libs) 0.13.16, by David Reid, ported; each from raylib 5.5's copy. stb_image_write and sdefl
are public domain or MIT, qoi.h MIT, dr_wav public domain or MIT No Attribution; their notices are in the files ported from them.
The tests' font is [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono Project
Authors, under the SIL Open Font License 1.1 (`tests/assets/OFL.txt`).
