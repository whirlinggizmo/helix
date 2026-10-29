# helix.services.assets

[Back to the index](README.md)

## AssetCacheMode

*enum* in [`services/src/helix/services/assets/AssetCacheMode.hx`](../../services/src/helix/services/assets/AssetCacheMode.hx), `import helix.services.assets.AssetCacheMode;`

Specifies when `Assets` uses its kept copy of an `HttpServer` file that no manifest lists, and when it asks the server.

- `Revalidate`: Uses a copy the server said is still fresh (its Cache-Control) and asks about any other. Unchanged, the copy is used; changed, the new file replaces it; gone, the copy is removed and the load fails. When the server doesn't answer (offline, an error) the copy is used. The default.
- `Trust`: Uses a copy without asking, however old: for files that never change, or a game that plays offline.
- `Off`: Keeps nothing between runs and uses nothing earlier runs kept; each file is downloaded once a run and held in memory. For development.

## AssetSource

*enum* in [`services/src/helix/services/assets/AssetSource.hx`](../../services/src/helix/services/assets/AssetSource.hx), `import helix.services.assets.AssetSource;`

Specifies a place `Assets` finds files: a file system on this machine, or an HTTP server.

- `FileSystem(fileSystem:IFileSystem)`: Files read as they are from a file system: natively the files the program ships with, a read-only `NativeFileSystemAdapter` over `ISystem.getProgramDirectory()`. In a page a file system starts empty, so the page's files come from an `HttpServer`.
- `HttpServer(url:String, ?cacheMode:AssetCacheMode)`: Files on an HTTP server, under a URL: downloaded through `AssetsOptions.httpClient` and kept in `AssetsOptions.cacheFileSystem`, so a later run downloads one again only when it's missing or changed.

## Assets

*class* in [`services/src/helix/services/assets/Assets.hx`](../../services/src/helix/services/assets/Assets.hx), `import helix.services.assets.Assets;`

Provides files by path, from the places its sources name: a file system on this machine, or an HTTP server whose files it keeps copies of.

It asks its sources in order, and the first that has the path answers: a file missing from one is looked for in the next. A game whose files never change lists its file system alone; one patched from a server lists the server first and its shipped files after, and a shipped file the server's manifest lists at the same hash is read in place, so only what changed is downloaded (`AssetManifests` writes the manifests); a page, whose files are on the server that served it, lists `HttpServer("")`. A path is plain names joined by `/`, as `IFileSystem`'s. Each call answers once, on the main thread, in the platform's `poll` that finished it, never during the call; the failure's lambda may be left out, and the failure is then logged with the path. Its downloads and copies finish in the polls of the HTTP client and file systems it was given, which the program polls each frame; Assets has no `poll` of its own.

```haxe
#if js
var httpClient:IHttp = new FetchApiHttpAdapter();
var downloads:IFileSystem = new BrowserFileSystemAdapter({name: "cache"});
var assets = new Assets({sources: [HttpServer("")], httpClient: httpClient, cacheFileSystem: downloads});
#else
var httpClient:IHttp = new HaxeHttpAdapter();
var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory("Company", "Game")});
var assets = new Assets({
sources: [HttpServer("https://example.com/game/"), FileSystem(shipped)],
httpClient: httpClient,
cacheFileSystem: downloads,
});
#end
assets.load("levels/1.json", bytes -> start(bytes));
// each frame, with the platform's other polls:
httpClient.poll();
downloads.poll();
```

```haxe
function new(options:AssetsOptions)
function load(path:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):() -> Void
function locate(path:String, located:(source:StreamSource, release:() -> Void) -> Void, ?failed:String -> Void):() -> Void
function clearCache(?cleared:() -> Void, ?failed:String -> Void):Void
function dispose():Void
```

- `new`: Creates the assets over their sources.
  - `options`: The sources, and the HTTP client and file system an `HttpServer` source needs.
  - throws `String`: When a source is an `HttpServer` and `httpClient` or `cacheFileSystem` is null.
- `load`: Loads a whole file.
  - `path`: The file's path.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it can't be had: no source has it, or the last one asked failed.
  - returns: The abort: nothing is called after it.
- `locate`: Finds a file for playing as it's read, without loading it whole, as `IAudio.openStream` takes it.
  - `path`: The file's path.
  - `located`: Receives the source, and the function that lets it go, called once when it's no longer read.
  - `failed`: Optional. Receives why it can't be had.
  - returns: The abort: nothing is called after it.

  A file system's file is located where it is; a server's file is its kept copy when there is one, and otherwise is played as it downloads while the copy is kept.
- `clearCache`: Empties `cacheFileSystem`, so each server's file is downloaded again.
  - `cleared`: Optional. Called once it's empty.
  - `failed`: Optional. Receives why it can't be emptied.
- `dispose`: Aborts every load and locate in flight; before the HTTP client and file systems it was given are disposed.

## AssetsOptions

*class* in [`services/src/helix/services/assets/AssetsOptions.hx`](../../services/src/helix/services/assets/AssetsOptions.hx), `import helix.services.assets.AssetsOptions;`

Specifies where `Assets` finds files, and what it downloads with and keeps copies in when a source is an HTTP server.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{sources:Array<AssetSource>, ?httpClient:IHttp, ?cacheFileSystem:IFileSystem, ?manifestName:String}
```

```haxe
final sources:Array<AssetSource>
final httpClient:IHttp = null
final cacheFileSystem:IFileSystem = null
final manifestName:String = "manifest.json"
```

- `sources`: Gets where files are found, asked in this order: a file missing from one is looked for in the next.
- `httpClient`: Gets the HTTP client `HttpServer` sources download with; null by default, and needed when there is one.
- `cacheFileSystem`: Gets the file system `HttpServer` sources' files are kept in; null by default, and needed when there is one. A file system of its own, as `clearCache` empties it: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory`, in a page a `BrowserFileSystemAdapter` with its own name.
- `manifestName`: Gets the name of each directory's manifest, as `AssetManifests` writes them: the hash of each file in it and of each subdirectory's manifest. "manifest.json" by default; "" looks for none.
