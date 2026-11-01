# helix.services.models

[Back to the index](README.md)

## Model3D

*class* in [`services/src/helix/services/models/Model3D.hx`](../../services/src/helix/services/models/Model3D.hx), `import helix.services.models.Model3D;`

Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images decoded. A glTF file and an OBJ file give the same kinds: an OBJ file's materials are made glTF materials (`materials`), and it has no skeleton, skins or animations.

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
final images:Array<Null<Image>>
function findAnimation(name:String):Int
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
  An OBJ file's are its `usemtl` names' materials, in `ObjFile.materialNames`' order, each made a glTF material: its name; its diffuse color (`Kd`) and opacity the base color factor, its diffuse texture the base color image; its metalness and roughness `MtlMaterial.computeMetalness` and `computeRoughness`, with no metallic-roughness image; its normal map `computeNormalTexturePath`'s; its emissive color (`Ke`) the emissive factor, white when it names an emissive texture without one, and that texture the emissive image; no occlusion image. A name no library gives is a material of every default.
- `images`: Gets the images, decoded, by their index in the file; null for one that couldn't be read or decoded (the failure logged). An OBJ file's are the textures its materials name, each file once, in the order they are first named.
- `findAnimation`: Returns the index of the first animation of a name.
  - `name`: The name.
  - returns: Its index in `animations`, or -1 for none.

## Models

*class* in [`services/src/helix/services/models/Models.hx`](../../services/src/helix/services/models/Models.hx), `import helix.services.models.Models;`

Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) or a Wavefront OBJ file (.obj) read through the assets, with the files it names (a glTF file's buffers and images, an OBJ file's material libraries and their textures) brought in and its images decoded, as one `Model3D`. The file's extension decides how it is read.

The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes' positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are; a skinned mesh's vertices stay as the file gives them, its skin's matrices placing it. Its skins become a skeleton (`Model3D.skeleton`), and its animations of that skeleton's bones `Animation3D`s. Only triangles are read; morph targets aren't yet.

An OBJ file is read by helix-formats' `ObjFile`, and the .mtl files it names by `MtlFile`: a library that can't be read is logged and skipped, its materials' names then standing for materials with every value its default. Its faces become a mesh for each object, group and material (`ObjFile.computeParts`), each corner that differs a vertex of its own, its texture coordinates' v turned to run down the image as glTF's do, and its normals made length 1, or computed from the triangles where the file gives none for some of its corners. Its materials are given as `GltfMaterial`s (`Model3D.materials` says how), and the textures they name decoded. It has no skeleton or animations.

Its answers come as the assets and images it reads through are polled.

```haxe
var models = new Models(assets, images);
models.load("trophy.glb", model -> trophy = model);
```

```haxe
function new(assets:Assets, images:Images)
function load(path:String, loaded:Model3D -> Void, ?failed:String -> Void):() -> Void
```

- `new`: Creates the models over the assets they are found in and the images that decode theirs.
  - `assets`: The assets the files are read through.
  - `images`: The images a model's are decoded by.
- `load`: Loads a model, the files it names and its images.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call. A buffer the file names that can't be read fails the load; an image that can't be read or decoded is null in the model, and logged.
