# helix.services.models

[Back to the index](README.md)

## Model3D

*class* in [`services/src/helix/services/models/Model3D.hx`](../../services/src/helix/services/models/Model3D.hx), `import helix.services.models.Model3D;`

Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images decoded.

```haxe
final path:String
final meshes:Array<Mesh3D>
final meshMaterials:Array<Int>
final meshSkins:Array<Int>
final meshTransforms:Array<Matrix3D>
final skeleton:Null<Skeleton3D>
final skins:Array<Skin3D>
final animations:Array<Animation3D>
final materials:Array<GltfMaterial>
final images:Array<Null<Image>>
function findAnimation(name:String):Int
```

- `path`: Gets the file it was read from, as the assets name it.
- `meshes`: Gets the meshes, each node's triangles in the scene's order: its transform in their positions, normals and tangents, but for a skinned mesh's (`meshSkins`), whose vertices are as the file gives them, in the space its skin binds them in, as glTF has it.
- `meshMaterials`: Gets each mesh's material, by its index in `materials`, beside it in `meshes`; -1 for none.
- `meshSkins`: Gets each mesh's skin, by its index in `skins`, beside it in `meshes`; -1 for a mesh without one.
- `meshTransforms`: Gets each mesh's node's transform in the model, beside it in `meshes`. A mesh without a skin has it in its vertices already; a skinned one hasn't, and doesn't need it: its skin's matrices put it in the model. It is kept for an engine that places skinned meshes by their nodes anyway, as raylib does.
- `skeleton`: Gets the skeleton its skinned meshes follow: every node any of the file's skins names as a joint, and the nodes above them, each a bone (its node's name, its parent, its node's own transform at rest), parents first; null for a model without skins.
- `skins`: Gets the skins, as the file has them, their bones the skeleton's.
- `animations`: Gets the animations of the skeleton's bones, each the file's animation's channels that move them (translation, rotation, scale); a channel moving another node, or morph weights, is left out. Empty without a skeleton.
- `materials`: Gets the materials, as the file has them; a material names its images by their index in `images`.
- `images`: Gets the images, decoded, by their index in the file; null for one that couldn't be read or decoded (the failure logged).
- `findAnimation`: Returns the index of the first animation of a name.
  - `name`: The name.
  - returns: Its index in `animations`, or -1 for none.

## Models

*class* in [`services/src/helix/services/models/Models.hx`](../../services/src/helix/services/models/Models.hx), `import helix.services.models.Models;`

Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) read through the assets, with the files it names (its buffers and images) brought in and its images decoded, as one `Model3D`.

The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes' positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are; a skinned mesh's vertices stay as the file gives them, its skin's matrices placing it. Its skins become a skeleton (`Model3D.skeleton`), and its animations of that skeleton's bones `Animation3D`s. Only triangles are read; morph targets aren't yet. Its answers come as the assets and images it reads through are polled.

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
