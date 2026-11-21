# Assets

[Back to the library](README.md)

## Assets

*class* in [`engines/raylib/src/helix/raylib/extras/Assets.hx`](../src/helix/raylib/extras/Assets.hx), `import helix.raylib.extras.Assets;`

Provides the path to the asset host, and ensures assets are available for raylib's `Load*` functions. Imported alongside `Raylib`: `import helix.raylib.extras.Assets.*;`. Used by the example `engines/raylib/examples/extras/assets`.

```haxe
InitWindow(1280, 720, "ensured");
var ready = false;
EnsureAssetsAsync(["assets/hero.png", "assets/ground.png"], () -> ready = true);
var hero:Texture2D = null;
while (!WindowShouldClose()) {
if (ready && hero == null)
hero = LoadTexture("assets/hero.png");
BeginDrawing();
// ...
EndDrawing();
}
```

Ensuring an asset will fetch its bytes (if absent) from the asset host into the program's cache, then decode the asset into memory. A load of an already ensured asset returns without refetching.

_Note that in a page, attempting to load an asset before it has been ensured is treated as a missing file._

### assets: the asset host, and files ensured ahead of raylib's loads

```haxe
static function SetAssetHosts(hosts:Array<String>):Void
static function GetAssetHosts(?out:Array<String>):Array<String>
static function ListAssetCacheAsync(path:String, listed:(Array<{host:String, fileName:String}>) -> Void, ?failed:String -> Void):Void
static function ClearAssetCacheAsync(?cleared:() -> Void, ?failed:String -> Void):Void
static function EnsureAssetAsync(fileName:String, ensured:() -> Void, ?failed:String -> Void):Void
static function EnsureAssetsAsync(fileNames:Array<String>, ensured:() -> Void, ?failed:String -> Void, ?progress:(done:Int, total:Int) -> Void):Void
static function IsAssetEnsured(fileName:String):Bool
static function ReleaseAsset(fileName:String):Void
static function ReleaseAssets(fileNames:Array<String>):Void
```

- `SetAssetHosts`: Sets where the program's assets come from, unless the option `asset_hosts` names the hosts. An asset is read from the first host with a file at its path. Assets ensured before the call are released, and a load after the call reads the new hosts. An asset being ensured or loaded during the call is read from the hosts set before it.
  - `hosts`: The hosts, in the order they are asked.

  Each host is a URL (`https://...`, `http://...`) or a directory, relative to the program's directory when relative. A URL's assets are fetched over HTTP and stored in the program's cache, and a changed file on the server replaces its cached copy. Natively a directory's assets are read in place. In a page a directory is relative to the page's, and its assets are fetched as a URL's are.

  A directory before a URL overrides the URL's files, as a mod does. Natively a directory after a URL is the URL's shipped files: a shipped file the server's manifest lists at the same hash is read in place, and only a changed file is downloaded. The manifests are written as the program builds, by `helix.services.tools.AssetManifests.write` over the shipped directory and the served one.

  An asset's path is relative to each host, with `.` and `..` followed. An absolute path or a URL is read from the host it is under. A path outside every host is refused as an invalid file path.

  The hosts are the first of these that is set: the option `asset_hosts`, a list separated by commas (`--asset_hosts=mods/bigheads/,https://example.com/game/` on the command line, the environment variable HELIX_ASSET_HOSTS, `?asset_hosts=...` in a page's query), this call, the build's define (`-D helix-raylib-asset-hosts=...`), and the default: natively `../web` beside the program's directory, in a page the page's own directory.
- `GetAssetHosts`: Returns the asset hosts in use, in the order they are asked.
  - `out`: Optional. The array to fill and return.
  - returns: The hosts.
- `ListAssetCacheAsync`: Asynchronously lists the assets stored in the program's cache under a directory. The cache contains every asset fetched from a URL host, in this run or an earlier one, whatever the hosts in use now. Natively a host's manifests are listed among them.
  - `path`: The directory, relative to each host. "" lists the whole cache.
  - `listed`: Called with each cached asset's file name, relative to its host, and its host's URL.
  - `failed`: Optional. Called with the reason the cache can't be listed, in place of `listed`. When omitted, the reason is logged.
- `ClearAssetCacheAsync`: Asynchronously deletes every asset stored in the program's cache, whatever the hosts in use now. Ensured assets stay ensured, and the files the program saved are untouched. A later ensure of a deleted asset fetches it again.
  - `cleared`: Optional. Called once the cache is empty.
  - `failed`: Optional. Called with the reason the cache can't be emptied, in place of `cleared`. When omitted, the reason is logged.
- `EnsureAssetAsync`: Asynchronously ensures an asset is available for raylib's `Load*` functions. Ensuring an asset fetches its bytes (if absent) from its asset host into the program's cache, then decodes the asset into memory. See `EnsureAssetsAsync` for ensuring several assets in parallel.
  - `fileName`: The asset's file name, relative to the asset hosts.
  - `ensured`: Called once the asset is ensured.
  - `failed`: Optional. Called with the reason the asset can't be ensured, in place of `ensured`. When omitted, the reason is logged.

  Each kind of asset is decoded to:

  - an image: its pixels.
  - a sound: its wave.
  - a glTF, GLB or OBJ model: the model, with its images decoded and a glTF model's animations read.
  - an .mtl material library: its materials.
  - a TrueType or OpenType font: a font ready to be rasterized at any size.
  - a BMFont: the font with its pages.
  - a compiled shader (a .shader file from `CompileShaderFile`): the shader.
  - any other asset: its bytes, unchanged.

  Ensuring an asset already ensured doesn't refetch it, and the `ensured` callback is still called. Sequential `EnsureAssetAsync` calls fetch and decode their assets in parallel.
- `EnsureAssetsAsync`: Asynchronously ensures several assets in parallel, each as `EnsureAssetAsync` does.
  - `fileNames`: The assets' file names, relative to the asset hosts.
  - `ensured`: Called once every asset is ensured.
  - `failed`: Optional. Called once, with the reason an asset can't be ensured, in place of `ensured`. When omitted, the reason is logged. The assets already ensured stay ensured.
  - `progress`: Optional. Called as each asset is ensured, with the number ensured and the total.
- `IsAssetEnsured`: Returns whether an asset has been ensured in this run (`EnsureAssetAsync`).
  - `fileName`: The asset's file name, relative to the asset hosts.
  - returns: True when the asset has been ensured.
- `ReleaseAsset`: Releases an ensured asset's bytes and decoded data from memory. A load of the asset then behaves as a load of an asset never ensured. What a load already made from the asset (a texture, a sound) stays, released by raylib's `Unload*` functions. The program's cache keeps the asset's fetched bytes, and ensuring the asset again doesn't refetch it.
  - `fileName`: The asset's file name, relative to the asset hosts.

  A program releases a level's assets when the player leaves the level.
- `ReleaseAssets`: Releases several assets, each as `ReleaseAsset` does.
  - `fileNames`: The assets' file names, relative to the asset hosts.
