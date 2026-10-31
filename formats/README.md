# helix-formats

File formats read into plain data: bytes or text in, typed data out. Pure Haxe, with no I/O: a program reads the file, hands its bytes
to a parser, and loads whatever other files the data names (a model's buffers and images, a font's pages) itself. Depends on
helix-math (a glTF node's transform is a `Matrix3D`).

- `gltf.GltfFile`: a glTF 2.0 model, from a .gltf or a GLB: its nodes and their transforms, the default scene, meshes (positions,
  normals, texture coordinates, colors, indices), metallic-roughness materials and images. Buffers held in the file are read at once;
  those in files of their own are listed, their paths resolved, for the program to fetch and set. Skins and animations aren't read yet.
- `bmfont.BmFontFile`: an AngelCode BMFont text file (.fnt): its size and line metrics, pages, glyphs and kerning pairs.
- `truetype.TrueTypeTables`: a TrueType or OpenType font's tables as stb_truetype reads them: vertical metrics, each codepoint's
  glyph, advances and boxes. helix-platform's canvas font rasterizer places its glyphs with it.

```haxe
import helix.formats.gltf.GltfFile;

var model = GltfFile.read(bytes, "models/ship.gltf");
for (missing in model.missingBuffers)
	model.setBuffer(missing.index, fetched(missing.path));
for (mesh in model.meshes)
	for (primitive in mesh.primitives)
		trace(primitive.positions.length / 3, primitive.material);
```

## Using it

```
-lib helix-formats
```

Until it is published, link it, and helix-math, from a checkout:

```
haxelib dev helix-formats <checkout>/formats
haxelib dev helix-math <checkout>/math
```

The API reference is [docs/api/](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/README.md) (the `helix.formats`
packages). Its tests, in `tests/`, build with `-lib helix-formats` alone, from this repository's root: `TrueTypeTests` embeds the font
in `tests/assets` as it compiles.

## Credit

`TrueTypeTables` reads a font's tables as [stb_truetype](https://github.com/nothings/stb), by Sean Barrett, reads them (public
domain); no code of it is included. `BmFontFile` reads [AngelCode BMFont](https://www.angelcode.com/products/bmfont/)'s text format as
documented, and the fields raylib 5.5's `LoadBMFont` reads.
The tests' font is [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono Project
Authors, under the SIL Open Font License 1.1 (`tests/assets/OFL.txt`).
