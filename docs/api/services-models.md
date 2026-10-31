# helix.services.models

[Back to the index](README.md)

## Mesh3D

*class* in [`services/src/helix/services/models/Mesh3D.hx`](../../services/src/helix/services/models/Mesh3D.hx), `import helix.services.models.Mesh3D;`

Represents one of a model's meshes as `Models` reads it: triangles, its node's transform already in its positions and normals.

```haxe
final positions:Array<Float>
final normals:Null<Array<Float>>
final texCoords:Null<Array<Float>>
final colors:Null<Array<Float>>
final indices:Null<Array<Int>>
final material:Int
```

- `positions`: Gets the positions, x, y and z each.
- `normals`: Gets the normals, x, y and z each, unit length; null when the file has none.
- `texCoords`: Gets the texture coordinates, u and v each; null when the file has none.
- `colors`: Gets the colors, red, green, blue and alpha each, 0 to 1; null when the file has none.
- `indices`: Gets the indices, three a triangle; null when the positions are the triangles in order.
- `material`: Gets the material's index in `Model3D.materials`, or -1 for none.

## Model3D

*class* in [`services/src/helix/services/models/Model3D.hx`](../../services/src/helix/services/models/Model3D.hx), `import helix.services.models.Model3D;`

Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images decoded.

```haxe
final path:String
final meshes:Array<Mesh3D>
final materials:Array<GltfMaterial>
final images:Array<Null<Image>>
```

- `path`: Gets the file it was read from, as the assets name it.
- `meshes`: Gets the meshes, each node's triangles in the scene's order, its transform in their positions and normals.
- `materials`: Gets the materials, as the file has them; a material names its images by their index in `images`.
- `images`: Gets the images, decoded, by their index in the file; null for one that couldn't be read or decoded (the failure logged).

## Models

*class* in [`services/src/helix/services/models/Models.hx`](../../services/src/helix/services/models/Models.hx), `import helix.services.models.Models;`

Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) read through the assets, with the files it names (its buffers and images) brought in and its images decoded, as one `Model3D`.

The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes' positions and normals, so a model's meshes are drawn as they are. Only triangles are read; skins and animations aren't yet. Its answers come as the assets and images it reads through are polled.

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
