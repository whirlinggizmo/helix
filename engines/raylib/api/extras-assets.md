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
static function SetAssetHost(host:String):Void
static function GetAssetHost():String
static function EnsureAssetAsync(fileName:String, ensured:() -> Void, ?failed:String -> Void):Void
static function EnsureAssetsAsync(fileNames:Array<String>, ensured:() -> Void, ?failed:String -> Void, ?progress:(done:Int, total:Int) -> Void):Void
static function IsAssetEnsured(fileName:String):Bool
static function ReleaseAsset(fileName:String):Void
static function ReleaseAssets(fileNames:Array<String>):Void
```

- `SetAssetHost`: Sets where the program's assets come from, unless the option `asset_host` gives a host. Assets ensured before the call stay ensured.
  - `host`: A URL (`https://...`, `http://...`), or a directory, relative to the program's directory when relative.

  The host is the first given of: the option `asset_host` (`--asset_host=https://example.com/game/` on the command line, the environment variable HELIX_ASSET_HOST, `?asset_host=...` in a page's query), this call, the build's define (`-D helix-raylib-asset-host=...`), and the default: natively `../web` beside the program's directory, in a page the page's own.

  A URL's assets are fetched over HTTP and kept in the program's cache, natively and in a page alike. A directory's are read in place.

  Every asset is read from the host, as a web server reads a file from its own root: a name starting with `/` from the host's root, `.` and `..` followed, and nothing above the host. A name whose `..` climbs above it fails as a missing file does.
- `GetAssetHost`: Returns the asset host in use: the option's, `SetAssetHost`'s, the build's define's, or the default.
  - returns: The host.
- `EnsureAssetAsync`: Asynchronously ensures an asset is available for raylib's `Load*` functions. Ensuring an asset fetches its bytes (if absent) from the asset host into the program's cache, then decodes the asset into memory. See `EnsureAssetsAsync` for ensuring several assets in parallel.
  - `fileName`: The asset's file name, relative to the asset host.
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
  - `fileNames`: The assets' file names, relative to the asset host.
  - `ensured`: Called once every asset is ensured.
  - `failed`: Optional. Called once, with the reason an asset can't be ensured, in place of `ensured`. When omitted, the reason is logged. The assets already ensured stay ensured.
  - `progress`: Optional. Called as each asset is ensured, with the number ensured and the total.
- `IsAssetEnsured`: Returns whether an asset has been ensured in this run (`EnsureAssetAsync`).
  - `fileName`: The asset's file name, relative to the asset host.
  - returns: True when the asset has been ensured.
- `ReleaseAsset`: Releases an ensured asset's bytes and decoded data from memory. A load of the asset then behaves as a load of an asset never ensured. What a load already made from the asset (a texture, a sound) stays, released by raylib's `Unload*` functions. The program's cache keeps the asset's fetched bytes, and ensuring the asset again doesn't refetch it.
  - `fileName`: The asset's file name, relative to the asset host.

  A program releases a level's assets when the player leaves the level.
- `ReleaseAssets`: Releases several assets, each as `ReleaseAsset` does.
  - `fileNames`: The assets' file names, relative to the asset host.
