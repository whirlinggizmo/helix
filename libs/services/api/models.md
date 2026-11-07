# helix.services.models

[Back to the library](README.md)

## Model3D

*class* in [`libs/services/src/helix/services/models/Model3D.hx`](../src/helix/services/models/Model3D.hx), `import helix.services.models.Model3D;`

Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images decoded for the GPU (`ModelImage3D`). A glTF file and an OBJ file give the same kinds: an OBJ file's materials are made glTF materials (`materials`), and it has no skeleton, skins or animations.

```haxe
final path:String
final meshes:Array<Mesh3D>
final meshMaterialIndices:Array<Int>
final meshSkinIndices:Array<Int>
final meshTransforms:Array<Matrix3D>
final skeleton:Null<Skeleton3D>
final skins:Array<Skin3D>
final animations:Array<Animation3D>
final materials:Array<GltfMaterial>
final images:Array<Null<ModelImage3D>>
function findAnimation(name:String):Int
function dispose():Void
```

- `path`: Gets the file it was read from, as the assets name it.
- `meshes`: Gets the meshes, each node's triangles in the scene's order: its transform in their positions, normals and tangents, but for a skinned mesh's (`meshSkinIndices`), whose vertices are as the file gives them, in the space its skin binds them in, as glTF has it. An OBJ file's are a mesh for each object, group and material (`ObjFile.computeParts`), in the order of their first faces, their texture coordinates' v running down the image as glTF's do.
- `meshMaterialIndices`: Gets the index of each mesh's material in `materials`, beside it in `meshes`; -1 for none (an OBJ file's faces before any `usemtl`).
- `meshSkinIndices`: Gets the index of each mesh's skin in `skins`, beside it in `meshes`; -1 for a mesh without one.
- `meshTransforms`: Gets each mesh's node's transform in the model, beside it in `meshes`. A mesh without a skin has it in its vertices already; a skinned one hasn't, and doesn't need it: its skin's matrices put it in the model. It is kept for an engine that places skinned meshes by their nodes anyway, as raylib does. An OBJ file's are identities.
- `skeleton`: Gets the skeleton its skinned meshes follow: every node any of the file's skins names as a joint, and the nodes above them, each a bone (its node's name, its parent, its node's own transform at rest), parents first; null for a model without skins.
- `skins`: Gets the skins, as the file has them, their bones the skeleton's.
- `animations`: Gets the animations of the skeleton's bones, each the file's animation's channels that move them (translation, rotation, scale); a channel moving another node, or morph weights, is left out. Empty without a skeleton.
- `materials`: Gets the materials, as the file has them; a material names its images by their index in `images`.
  An OBJ file's are its `usemtl` names' materials, in `ObjFile.materialNames`' order, each made a glTF material: its name; its diffuse color and opacity (`MtlMaterial.computeDiffuse` and `computeOpacity`) the base color factor, its diffuse texture the base color image; its metalness and roughness `computeMetalness` and `computeRoughness`, with no metallic-roughness image; its normal map `computeNormalTexturePath`'s; its emissive color (`computeEmission`) the emissive factor, white when it names an emissive texture with that color black, and that texture the emissive image; no occlusion image. A name no library gives is a material of every default.
- `images`: Gets the images, each decoded for the GPU with its file's bytes, by their index in the file; null for one that couldn't be read or decoded (the failure logged). An OBJ file's are the textures its materials name, each file once, in the order they are first named.
- `findAnimation`: Returns the index of the first animation of a name.
  - `name`: The name.
  - returns: Its index in `animations`, or -1 for none.
- `dispose`: Frees each image's decoded image still held (`ModelImage3D.dispose`): those nothing uploaded. The meshes, materials and each image's `encoded` stay.

## ModelImage3D

*class* in [`libs/services/src/helix/services/models/ModelImage3D.hx`](../src/helix/services/models/ModelImage3D.hx), `import helix.services.models.ModelImage3D;`

Represents one of a model's images: its file's bytes, and the image decoded for the GPU from them.

`Models` decodes each image through `Images.decodeForGpu`, so a program draws it without holding its pixels. What uploads it takes the decoded image once (`takeDecoded`) and disposes it once sent. `encoded` stays with the model, so the image can be decoded again (`Images.decodeForGpu`), as a texture lost with the GPU's context is.

```haxe
final path:String
final encoded:haxe.io.Bytes
final width:Int
final height:Int
function takeDecoded():Null<IDecodedImage>
function dispose():Void
```

- `path`: Gets the path of the image's own file, as the assets name it, or "" for an image held in the model's file.
- `encoded`: Gets the image file's bytes: the file at `path`, or the model's bytes holding the image (a glTF buffer view, or a `data:` URI decoded). `Images.decodeForGpu` decodes them again.
- `width`: Gets its width, in pixels.
- `height`: Gets its height, in pixels.
- `takeDecoded`: Returns the image decoded for the GPU, once: the caller owns it, uploads it (`IGraphics.createTextureFromImage`) or reads its pixels, and disposes it after.
  - returns: The decoded image, or null once it was taken or disposed.
- `dispose`: Frees the decoded image while it is held. `encoded` stays.

## Models

*class* in [`libs/services/src/helix/services/models/Models.hx`](../src/helix/services/models/Models.hx), `import helix.services.models.Models;`

Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) or a Wavefront OBJ file (.obj) read through the assets, with the files it names (a glTF file's buffers and images, an OBJ file's material libraries and their textures) brought in and its images decoded for the GPU, as one `Model3D`. `loadGltf` and `loadObj` each read one format, so a program carries only the reader it calls. A program that takes a name as it runs chooses between them itself.

The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes' positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are; a skinned mesh's vertices stay as the file gives them, its skin's matrices placing it. Its skins become a skeleton (`Model3D.skeleton`), and its animations of that skeleton's bones `Animation3D`s. Only triangles are read; morph targets aren't yet.

An OBJ file is read by helix-formats' `ObjFile`, and the .mtl files it names by `MtlFile`: a file whose corners name a position, texture coordinate or normal it doesn't have fails, and a library that can't be read is logged and skipped, its materials' names then standing for materials with every value its default. Its faces become a mesh for each object, group and material (`ObjFile.computeParts`), each corner that differs a vertex of its own, its texture coordinates' v turned to run down the image as glTF's do, and its normals made length 1, or computed from the triangles where the file gives none for some of its corners. Its materials are given as `GltfMaterial`s (`Model3D.materials` says how), and the textures they name decoded. It has no skeleton or animations.

Each image, held in the model's file or in a file of its own, is decoded through `Images.decodeForGpu`, so in a page the program never holds its pixels: a `ModelImage3D` carries the decoded image for what uploads it, and the image file's bytes for decoding it again.

Its answers come as the assets and images it reads through are polled.

```haxe
var models = new Models(assets, images);
models.loadGltf("trophy.glb", model -> trophy = model);
```

```haxe
function new(assets:Assets, images:Images)
function loadGltf(path:String, loaded:Model3D -> Void, ?failed:String -> Void):() -> Void
function loadObj(path:String, loaded:Model3D -> Void, ?failed:String -> Void):() -> Void
```

- `new`: Creates the models over the assets they are found in and the images that decode theirs.
  - `assets`: The assets the files are read through.
  - `images`: The images a model's are decoded by (`Images.decodeForGpu`).
- `loadGltf`: Loads a glTF 2.0 model (.gltf or .glb), the files it names and its images.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call. A buffer the file names that can't be read fails the load; an image that can't be read or decoded is null in the model, and logged. A load that fails or is aborted disposes the images it decoded.
- `loadObj`: Loads a Wavefront OBJ model, the material libraries it names and their textures.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  The file is read first, then each library it names (one that can't be read logged and skipped), then each texture its materials name, decoded (one that can't be, null in the model and logged). One of `loaded` or `failed` is called once, at a later poll, never during this call. A load that fails or is aborted disposes the images it decoded.
