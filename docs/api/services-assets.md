# helix.services.assets

[Back to the index](README.md)

## AssetCacheMode

*enum* in [`services/src/helix/services/assets/AssetCacheMode.hx`](../../services/src/helix/services/assets/AssetCacheMode.hx), `import helix.services.assets.AssetCacheMode;`

Specifies how an `HttpServer` source decides whether its kept copy of a file is current.

The copy can be checked with the server, trusted, not kept at all, or checked against the server's manifests.

- `Revalidate`: Uses a copy without asking while the server's Cache-Control says it is fresh, and asks the server about any other copy.
- `Trust`: Uses a copy without asking, however old it is.
- `Off`: Keeps nothing between runs and ignores what earlier runs kept.
- `Manifest`: Uses the server's manifests to tell whether a copy is current.

## AssetSource

*enum* in [`services/src/helix/services/assets/AssetSource.hx`](../../services/src/helix/services/assets/AssetSource.hx), `import helix.services.assets.AssetSource;`

Specifies a place `Assets` finds files: a file system on this machine, or an HTTP server.

- `FileSystem(fileSystem:IFileSystem)`: Reads files as they are from a file system.
- `HttpServer(url:String, ?cacheMode:AssetCacheMode)`: Downloads files from an HTTP server, under a URL.

## Assets

*class* in [`services/src/helix/services/assets/Assets.hx`](../../services/src/helix/services/assets/Assets.hx), `import helix.services.assets.Assets;`

Provides files by path, from a file system on this machine or from an HTTP server whose files it keeps copies of.

It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next. A game whose files never change lists its file system alone. A game patched from a server lists the server first, in `Manifest` mode, and its shipped files after it. A shipped file that the server's manifest lists at the same hash is then read in place, and only what changed is downloaded. A page, whose files are on the server that served it, lists `HttpServer("")`.

A path is plain names joined by `/`, as in `IFileSystem`. Each call answers once, on the main thread, in the platform `poll` that finished it, and never during the call. The failure callback is optional; when it is omitted, the failure is logged with the path.

Downloads and copies finish in the polls of the HTTP client and file systems it was given, which the program polls each frame. Assets has no `poll` of its own.

```haxe
var httpClient:IHttp = new HaxeHttpAdapter();
var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory("Company", "Game")});

// The shipped files alone, never checked:
var assets = new Assets({sources: [FileSystem(shipped)]});
// The shipped files first, a server for what they don't have:
var assets = new Assets({sources: [FileSystem(shipped), HttpServer("https://example.com/game/")], httpClient: httpClient, cacheFileSystem: downloads});
// A server first, patching what shipped by its manifests:
var assets = new Assets({sources: [HttpServer("https://example.com/game/", Manifest), FileSystem(shipped)], httpClient: httpClient, cacheFileSystem: downloads});
// In a page, the files beside the page:
var assets = new Assets({sources: [HttpServer("")], httpClient: new FetchApiHttpAdapter(), cacheFileSystem: new BrowserFileSystemAdapter({name: system.getCacheDirectory("Company", "Game")})});

assets.load("levels/1.json", bytes -> start(bytes));
// each frame, with the platform's other polls:
httpClient.poll();
downloads.poll();
shipped.poll();
```

```haxe
function new(options:AssetsOptions)
function load(path:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):() -> Void
function locate(path:String, located:(source:StreamSource, release:() -> Void) -> Void, ?failed:String -> Void):() -> Void
function clearCache(?cleared:() -> Void, ?failed:String -> Void):Void
function dispose():Void
```

- `new`: Creates the assets over their sources.
  - `options`: The sources, and the HTTP client and file system that an `HttpServer` source needs.
  - throws `String`: When a source is an `HttpServer` and `httpClient` or `cacheFileSystem` is null.
- `load`: Loads a whole file.
  - `path`: The file's path.
  - `loaded`: Receives the file's bytes.
  - `failed`: Optional. Receives why the file can't be loaded, because no source has it or the last source asked failed.
  - returns: The abort: nothing is called after it.
- `locate`: Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` takes.
  - `path`: The file's path.
  - `located`: Receives the source, and a release function to call once when the source is no longer read.
  - `failed`: Optional. Receives why the file can't be found.
  - returns: The abort: nothing is called after it.

  A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise it plays as it downloads, and the copy is kept.
- `clearCache`: Empties `cacheFileSystem`, so each server's files are downloaded again.
  - `cleared`: Optional. Called once the cache is empty.
  - `failed`: Optional. Receives why the cache can't be emptied. When omitted, the failure is logged.
- `dispose`: Aborts every load and locate in flight.
  Call it before disposing the HTTP client and file systems it was given.

## AssetsOptions

*class* in [`services/src/helix/services/assets/AssetsOptions.hx`](../../services/src/helix/services/assets/AssetsOptions.hx), `import helix.services.assets.AssetsOptions;`

Specifies where `Assets` finds files, and, for an HTTP server source, what downloads them and where copies are kept.

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

- `sources`: Gets the places files are found, asked in order. A file missing from one source is looked for in the next.
- `httpClient`: Gets the HTTP client that `HttpServer` sources download with. Defaults to null, and must be provided when there is an `HttpServer` source.
- `cacheFileSystem`: Gets the file system that `HttpServer` sources keep their copies in. Defaults to null, and must be provided when there is an `HttpServer` source.
  It must be a file system used for nothing else, because `clearCache` empties it. Make it over `ISystem.getCacheDirectory`: a `NativeFileSystemAdapter` natively, and a `BrowserFileSystemAdapter` in a page.
- `manifestName`: Gets the file name of each directory's manifest, which a `Manifest` source reads. Defaults to "manifest.json".
  It matches the name `AssetManifests` writes.
