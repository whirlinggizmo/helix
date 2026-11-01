# helix.formats.gltf

[Back to the index](README.md)

## GltfFile

*class* in [`formats/src/helix/formats/gltf/GltfFile.hx`](../../formats/src/helix/formats/gltf/GltfFile.hx), `import helix.formats.gltf.GltfFile;`

Represents a glTF 2.0 model read from a .gltf or GLB file: its nodes, its scene, its meshes, materials and images, as plain data.

`read` takes the file's bytes and its path. A buffer held in the file (a GLB's BIN chunk, a base64 `data:` URI) is read then; one in a file of its own is listed in `missingBuffers`, its path resolved against the model's, for the caller to fetch and give to `setBuffer`. `nodes`, `scene` and `materials` are read with the file; `meshes` and `images` read the buffers when asked for, and throw while a buffer they need is missing.

Accessors of every component type are read, normalized integers scaled to 0..1 or -1..1; one with no buffer view is zeros, and a sparse accessor throws. Positions and normals are in each mesh's own units: no node's transform is applied. Skins, animations, morph targets, cameras, samplers and extensions are not read yet.

```haxe
var model = GltfFile.read(bytes, "models/ship.gltf");
for (missing in model.missingBuffers) model.setBuffer(missing.index, fetched(missing.path));
var positions = model.meshes[0].primitives[0].positions;
```

```haxe
static function read(bytes:haxe.io.Bytes, path:String):GltfFile
final nodes:Array<GltfNode>
final scene:Array<Int>
final materials:Array<GltfMaterial>
var meshes(get, never):Array<GltfMesh>
var images(get, never):Array<GltfImage>
var missingBuffers(get, never):Array<{path:String, index:Int}>
function setBuffer(index:Int, bytes:haxe.io.Bytes):Void
```

- `read`: Reads a glTF 2.0 model: a .gltf (its JSON, as UTF-8) or a GLB, told apart by its first bytes.
  - `bytes`: The file's bytes.
  - `path`: The file's path, against whose directory the paths of its buffers and images are resolved.
  - returns: The model.
  - throws `String`: It is neither a glTF 2.0 file nor a GLB, or its JSON or a chunk is broken.

  Buffers held in the file are read now; those in files of their own are listed in `missingBuffers`.
- `nodes`: Gets the model's nodes, in the file's order: nodes name each other, and `scene` names its roots, by their index here.
- `scene`: Gets the indices in `nodes` of the default scene's roots: the file's `scene`, or its first scene; with no scenes, every node that is no node's child.
- `materials`: Gets the model's materials, in the file's order: a primitive names its own by its index here.
- `meshes`: Gets the model's meshes, in the file's order, read from the buffers when first asked for.
  - throws `String`: A buffer a mesh needs is missing (`missingBuffers`, which the message names), or an accessor can't be read.
- `images`: Gets the model's images, in the file's order, those held in a buffer read from it when first asked for.
  - throws `String`: A buffer an image needs is missing (`missingBuffers`, which the message names).
- `missingBuffers`: Gets the buffers in files of their own that are still missing, each its index and its file's path: URI-decoded and resolved against the model's directory. Empty when every buffer is read.
- `setBuffer`: Sets a buffer in a file of its own to that file's bytes, so the meshes and images that need it can be read.
  - `index`: The buffer's index, as `missingBuffers` gives it.
  - `bytes`: The buffer's file.
  - throws `String`: The index is out of range, or the bytes are fewer than the buffer's `byteLength`.

## GltfImage

*class* in [`formats/src/helix/formats/gltf/GltfImage.hx`](../../formats/src/helix/formats/gltf/GltfImage.hx), `import helix.formats.gltf.GltfImage;`

Represents one image of a glTF model: its encoded file's bytes when the model holds them, or the path of its own file.

An image held in the model (a buffer view, a base64 `data:` URI) has `encoded` and no `path`; one in a file of its own has `path`, URI-decoded and resolved against the model's directory, and no `encoded`. Nothing is decoded: `encoded` is the PNG or JPEG file.

```haxe
final encoded:Null<haxe.io.Bytes>
final path:Null<String>
final mimeType:Null<String>
```

- `encoded`: Gets the image's encoded file, or null when it is in a file of its own (`path`).
- `path`: Gets the path of the image's own file, resolved against the model's directory, or null when the model holds it (`encoded`).
- `mimeType`: Gets the image's media type as the file gives it (`image/png`, `image/jpeg`), or null when it gives none.

## GltfMaterial

*class* in [`formats/src/helix/formats/gltf/GltfMaterial.hx`](../../formats/src/helix/formats/gltf/GltfMaterial.hx), `import helix.formats.gltf.GltfMaterial;`

Represents one material of a glTF model: its metallic-roughness factors and the images its textures sample.

Each texture is given as the index of its image in `GltfFile.images`, the image its glTF texture's `source` names; a sampler, a texture coordinate set other than the first and a texture's transform are not read. Factors the file omits take glTF's defaults.

```haxe
final name:String
final baseColorFactor:Array<Float>
final baseColorImage:Int
final metallic:Float
final roughness:Float
final normalImage:Int
final emissiveFactor:Array<Float>
final emissiveImage:Int
```

- `name`: Gets the material's name: empty when the file gives none.
- `baseColorFactor`: Gets the base color factor: red, green, blue and alpha, each 0 to 1, multiplying the base color image. Defaults to 1, 1, 1, 1.
- `baseColorImage`: Gets the index of the base color image in `GltfFile.images`, or -1 when there is none.
- `metallic`: Gets the metalness factor, 0 to 1. Defaults to 1.
- `roughness`: Gets the roughness factor, 0 to 1. Defaults to 1.
- `normalImage`: Gets the index of the normal map's image in `GltfFile.images`, or -1 when there is none.
- `emissiveFactor`: Gets the emissive factor: red, green and blue, each 0 to 1, multiplying the emissive image. Defaults to 0, 0, 0.
- `emissiveImage`: Gets the index of the emissive image in `GltfFile.images`, or -1 when there is none.

## GltfMesh

*class* in [`formats/src/helix/formats/gltf/GltfMesh.hx`](../../formats/src/helix/formats/gltf/GltfMesh.hx), `import helix.formats.gltf.GltfMesh;`

Represents one mesh of a glTF model: its name and its primitives, each drawn with a material of its own.

A mesh is read from the file's `meshes`, as `GltfFile.meshes` lists them; nodes name it by its index there.

```haxe
final name:String
final primitives:Array<GltfPrimitive>
```

- `name`: Gets the mesh's name: empty when the file gives none.
- `primitives`: Gets the mesh's primitives, in the file's order.

## GltfNode

*class* in [`formats/src/helix/formats/gltf/GltfNode.hx`](../../formats/src/helix/formats/gltf/GltfNode.hx), `import helix.formats.gltf.GltfNode;`

Represents one node of a glTF model: its name, its mesh, its children and its transform relative to its parent.

A node is read from the file's `nodes`, as `GltfFile.nodes` lists them; its children and its mesh are indices into `GltfFile.nodes` and `GltfFile.meshes`. A node's world transform is its own composed with its ancestors', from a root in `GltfFile.scene` down.

```haxe
final name:String
final mesh:Int
final children:Array<Int>
final transform:Matrix3D
```

- `name`: Gets the node's name: empty when the file gives none.
- `mesh`: Gets the index of the node's mesh in `GltfFile.meshes`, or -1 when it has none.
- `children`: Gets the indices of the node's children in `GltfFile.nodes`: empty when it has none.
- `transform`: Gets the node's transform relative to its parent: its `matrix`, or its scale, then rotation, then translation, applied in that order. Identity when the file gives none.

## GltfPrimitive

*class* in [`formats/src/helix/formats/gltf/GltfPrimitive.hx`](../../formats/src/helix/formats/gltf/GltfPrimitive.hx), `import helix.formats.gltf.GltfPrimitive;`

Represents one primitive of a glTF mesh: its vertices, read from their accessors, its indices and its material.

Each attribute is every component of every vertex in order, as floats: a normalized integer is scaled to 0..1 when unsigned and -1..1 when signed, any other value is as the file has it. Positions, normals and tangents are in the mesh's own units: no node's transform is applied. Only the first set of texture coordinates (`TEXCOORD_0`) and of colors (`COLOR_0`) is read.

```haxe
final mode:Int
final positions:Array<Float>
final normals:Null<Array<Float>>
final tangents:Null<Array<Float>>
final texCoords:Null<Array<Float>>
final colors:Null<Array<Float>>
final indices:Null<Array<Int>>
final material:Int
```

- `mode`: Gets what the primitive draws, glTF's `mode`: 0 points, 1 lines, 2 a line loop, 3 a line strip, 4 triangles, 5 a triangle strip, 6 a triangle fan. Defaults to 4.
- `positions`: Gets the vertices' positions, `POSITION`: x, y and z for each vertex. Empty when the primitive has none.
- `normals`: Gets the vertices' normals, `NORMAL`: x, y and z for each vertex, or null when the primitive has none.
- `tangents`: Gets the vertices' tangents, `TANGENT`: x, y, z and w for each vertex, w 1 or -1 for the bitangent's side, or null when the primitive has none.
- `texCoords`: Gets the vertices' texture coordinates, `TEXCOORD_0`: u and v for each vertex, v down from the image's top, or null when the primitive has none.
- `colors`: Gets the vertices' colors, `COLOR_0`: red, green, blue and alpha for each vertex, each 0 to 1 (alpha 1 when the file gives three components), or null when the primitive has none.
- `indices`: Gets the vertices' indices, or null when the primitive has none and its vertices are drawn in order.
- `material`: Gets the index of the primitive's material in `GltfFile.materials`, or -1 when it has none (glTF's default material).
