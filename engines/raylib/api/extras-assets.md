# Assets

[Back to the library](README.md)

## Assets

*class* in [`engines/raylib/src/helix/raylib/extras/Assets.hx`](../src/helix/raylib/extras/Assets.hx), `import helix.raylib.extras.Assets;`

Provides where the program's files come from, and ensures them ahead of raylib's loads, so `LoadTexture`, `LoadSound`, `LoadModel` and the rest answer at once, as in raylib. helix-raylib's own. Imported apart: `import helix.raylib.extras.Assets.*;`. The example `engines/raylib/examples/extras/assets` uses it.

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

Ensuring a file makes its bytes local, fetched from the asset host into the program's cache when they aren't there, and decodes it into memory by its kind. Natively a load needs no ensure: it reads and decodes its file during the call. In a page it does, as the browser reads its cache and decodes only asynchronously: a load of a file not ensured in this run fails as raylib's load of a missing file does, logging why.

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

- `SetAssetHost`: Sets where the program's files come from, unless the option `asset_host` gives a host. Files ensured before the call stay ensured.
  - `host`: A URL (`https://...`, `http://...`), or a directory, relative to the program's directory when relative.

  The host is the first given of: the option `asset_host` (`--asset_host=https://example.com/game/` on the command line, the environment variable HELIX_ASSET_HOST, `?asset_host=...` in a page's query), this call, the build's define (`-D helix-raylib-asset-host=...`), and the default: natively `../web` beside the program's directory, in a page the page's own.

  A URL's files are fetched over HTTP and kept in the program's cache, natively and in a page alike. A directory's are read in place.
- `GetAssetHost`: Returns the asset host in use: the option's, `SetAssetHost`'s, the build's define's, or the default.
  - returns: The host.
- `EnsureAssetAsync`: Asynchronously ensures a file: makes it local, fetching it from the asset host and keeping it in the program's cache when it isn't there, and decodes it into memory by its kind, so raylib's load of it answers at once on every target. An image is decoded to its pixels, a sound file to its wave, a glTF, GLB or OBJ file to its model (its images decoded) and a glTF file's animations read, an .mtl file to its materials, a TrueType or OpenType font opened to be rasterized at any size, a BMFont read with its pages, a compiled shader (a .shader file, as `CompileShaderFile` writes it) read. Any other file is kept as its bytes.
  - `fileName`: The file's name, relative to the asset host.
  - `ensured`: Called once the file is ensured.
  - `failed`: Optional. Called with why the file can't be ensured, in place of `ensured`; when omitted, it is logged.

  A file already ensured is ensured at once, though `ensured` is still called after the call returns. Several calls made in a row fetch and decode their files together, never one after another. See `EnsureAssetsAsync` for several files at once.

  Without an ensure, natively a load reads and decodes its file during the call. In a page a load of a file not ensured in this run fails as raylib's load of a missing file does, logging why: the browser reads its cache and decodes only asynchronously.
- `EnsureAssetsAsync`: Asynchronously ensures several files together, as `EnsureAssetAsync` does each, fetching and decoding them all at once: for the files a program loads as it starts, or a loading screen.
  - `fileNames`: The files' names, relative to the asset host.
  - `ensured`: Called once every file is ensured.
  - `failed`: Optional. Called with why a file can't be ensured, once, in place of `ensured`; when omitted, it is logged. The other files ensured stay ensured.
  - `progress`: Optional. Called as each file is ensured, with how many are and how many there are.
- `IsAssetEnsured`: Returns whether a file has been ensured in this run (`EnsureAssetAsync`), so a load of it answers at once on every target.
  - `fileName`: The file's name, relative to the asset host.
  - returns: True when it has.
- `ReleaseAsset`: Lets go of what ensuring a file kept in memory: its bytes and what was decoded from it. A load of it then behaves as one of a file never ensured. What a load already made from it (a texture, a sound) is the program's, let go of by raylib's unloads, and stays. The program's cache keeps its copy of a fetched file, so ensuring it again needs no fetch.
  - `fileName`: The file's name, relative to the asset host.

  A file's first load takes what was decoded from it, so a program only releases what it ensured and never loaded: a level's files when the player leaves for the menu.
- `ReleaseAssets`: Lets go of several files' ensured data, as `ReleaseAsset` does each.
  - `fileNames`: The files' names, relative to the asset host.
