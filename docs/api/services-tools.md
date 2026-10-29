# helix.services.tools

[Back to the index](README.md)

## AssetManifests

*class* in [`services/src/helix/services/tools/AssetManifests.hx`](../../services/src/helix/services/tools/AssetManifests.hx), `import helix.services.tools.AssetManifests;`

Provides a build-time macro that writes the manifests `Assets` reads.

Each directory of a tree gets a manifest listing the hash of each file in it and of each subdirectory's own manifest. An unchanged directory is then known from its parent's manifest alone.

Call `write` once in the program, over the directory its files ship in and its server serves. It runs while the program builds. A manifest is rewritten only when what it lists changed. A file is hashed again only when its size or modification time changed since the last run. Those are kept in a hidden file beside the directory, such as `.assets.manifests` for `assets`. Hidden files, and names `IFileSystem` refuses, are skipped.

```haxe
AssetManifests.write("assets");
```

```haxe
static macro function write(directory:String, name:String = "manifest.json"):Void
```

- `write`: Writes the manifests of a directory and every directory under it, while the program builds.
  - `directory`: The tree's root, relative to where the build runs.
  - `name`: Optional. Each manifest's file name, which matches `AssetsOptions.manifestName`. Defaults to "manifest.json".

  The build fails when the path isn't a directory.
