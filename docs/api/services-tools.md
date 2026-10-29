# helix.services.tools

[Back to the index](README.md)

## AssetManifests

*class* in [`services/src/helix/services/tools/AssetManifests.hx`](../../services/src/helix/services/tools/AssetManifests.hx), `import helix.services.tools.AssetManifests;`

Provides writing the manifests `Assets` reads: in each directory of a tree, a file listing the hash of each file in it and of each subdirectory's own manifest, so an unchanged directory is known from its parent alone.

Called once in the program, it runs while the program builds, over the directory its files ship in and its server serves. A manifest is rewritten only when what it lists changed, and a file is hashed again only when its size or time changed since the last run, kept in a hidden file beside the directory (`.assets.manifests` for `assets`). Hidden files and names `IFileSystem` refuses are left out.

```haxe
AssetManifests.write("assets");
```

```haxe
static macro function write(directory:String, name:String = "manifest.json"):Void
```

- `write`: Writes the manifests of a directory and every directory under it, while the program builds; a directory that isn't one fails the build.
  - `directory`: The tree's root, relative to where the build runs.
  - `name`: Optional. Each manifest's file name, as `AssetsOptions.manifestName`; "manifest.json" by default.
