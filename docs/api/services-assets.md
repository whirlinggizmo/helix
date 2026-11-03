# helix.services.assets

[Back to the index](README.md)

## AssetCache

*class* in [`services/src/helix/services/assets/AssetCache.hx`](../../services/src/helix/services/assets/AssetCache.hx), `import helix.services.assets.AssetCache;`

Decides whether a server's kept copy of a file is current, and keeps the copies. Construct one of its kinds.

## AssetSource

*class* in [`services/src/helix/services/assets/AssetSource.hx`](../../services/src/helix/services/assets/AssetSource.hx), `import helix.services.assets.AssetSource;`

Specifies a place `Assets` finds files. Construct a `FileSystemSource` or a `ServerSource`.

## Assets

*class* in [`services/src/helix/services/assets/Assets.hx`](../../services/src/helix/services/assets/Assets.hx), `import helix.services.assets.Assets;`, implements `IPollable`

Provides files by path, from a file system on this machine or from an HTTP server whose files it keeps copies of.

It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next. A game whose files never change lists its file system alone (`FileSystemSource`). A game patched from a server lists the server first, with a `ManifestCache` given the shipped files, and its shipped files after it. A shipped file that the server's manifest lists at the same hash is then read in place, and only what changed is downloaded. A page, whose files are on the server that served it, lists a `ServerSource` at "".

A path is plain names joined by `/`, as in `IFileSystem` (`FilePath`), from every source: a server is never asked for one the file systems would refuse, so a name fails alike in a page and natively. Each call answers once, on the main thread, in a later poll, never during the call. The failure callback is optional; when it is omitted, the failure is logged with the path.

The program polls the assets once a frame, with the HTTP client and file systems it was given. Downloads and copies finish in their polls, and what Assets answers with nothing of theirs to wait on (a file held in memory, a refused path) in its own. Assets that are never polled answer nothing.

A file can change while the program runs, as a development server's do. Assets doesn't watch for it: whoever knows a file changed calls `notifyChanged` with its path, or `notifyUrlChanged` with the URL it was served at, and each `watch` of that path receives the new bytes. A page's development build wires hotreload-hx in one line, `reloader.assetsChanged = urls -> for (url in urls) assets.notifyUrlChanged(url);`. Natively nothing calls it, and there is no watcher.

```haxe
var httpClient:IHttp = new HaxeHttpAdapter();
var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory()});

// The shipped files alone, never checked:
var assets = new Assets([new FileSystemSource(shipped)]);
// The shipped files first, a server for what they don't have:
var assets = new Assets([new FileSystemSource(shipped), new ServerSource("https://example.com/game/", httpClient, new RevalidateCache(downloads))]);
// A server first, patching what shipped by its manifests:
var patching = new ManifestCache(downloads, {shipped: [shipped]});
var assets = new Assets([new ServerSource("https://example.com/game/", httpClient, patching), new FileSystemSource(shipped)]);
// In a page, the files beside the page:
var kept = new RevalidateCache(new BrowserFileSystemAdapter({name: system.getCacheDirectory()}));
var assets = new Assets([new ServerSource("", new FetchApiHttpAdapter(), kept)]);

assets.load("levels/1.json", bytes -> start(bytes));
// each frame, with the platform's other polls:
httpClient.poll();
downloads.poll();
shipped.poll();
assets.poll();
```

```haxe
function new(sources:Array<AssetSource>)
function load(path:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):() -> Void
function watch(path:String, changed:haxe.io.Bytes -> Void):() -> Void
function notifyChanged(path:String):Void
function notifyUrlChanged(url:String):Void
function locate(path:String, located:(source:StreamSource, release:() -> Void) -> Void, ?failed:String -> Void):() -> Void
function clearCache(?cleared:() -> Void, ?failed:String -> Void):Void
function deleteCopy(path:String, ?deleted:() -> Void, ?failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the assets over their sources, asked in order.
  - `sources`: The places files are found. A file missing from one source is looked for in the next.
- `load`: Loads a whole file.
  - `path`: The file's path.
  - `loaded`: Receives the file's bytes.
  - `failed`: Optional. Receives why the file can't be loaded, because no source has it or the last source asked failed.
  - returns: The abort: nothing is called after it.
- `watch`: Calls a function with a file's new bytes each time a change of it is brought in (`notifyChanged`), until the returned function is called.
  - `path`: The file's path.
  - `changed`: Receives the file's bytes, each time a change brings a new copy.
  - returns: A function that stops the watch; nothing is called after it.

  Nothing is read now: a path watched and never changed is never read by the watch.
- `notifyChanged`: Brings a file in again because it changed, past every cache, and hands the new bytes to each `watch` of it.
  - `path`: The file's path.

  The file is asked of the sources in order, as `load` asks: a server's past the browser's HTTP cache (no-store) and past the copy its cache keeps, the new copy then kept in its place, so a later `load` gets it. A file that can't be brought in keeps the old copy, and no watch is called; the failure is logged with the path. Nothing is called during the call.
- `notifyUrlChanged`: Brings a file in again because the URL it is served at changed, as `notifyChanged` does for its path.
  - `url`: The URL, absolute or from the server's root, as a development server reports it.

  The URL is matched against each `ServerSource`'s, resolved against the page's location in a page (a source `"assets/"` on a page at `http://localhost:8080/` serves `/assets/shaders/glow.shader` as `shaders/glow.shader`); a URL no source serves is skipped.
- `locate`: Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` takes.
  - `path`: The file's path.
  - `located`: Receives the source, and a release function to call once when the source is no longer read.
  - `failed`: Optional. Receives why the file can't be found.
  - returns: The abort: nothing is called after it.

  A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise, natively, it plays as it downloads, and the copy is kept; in a page it is located once it is kept. A native download asks for the file's last 64 KiB first and then the rest, so the stream's length can be read before it has all arrived, as a browser's media element does. A server that doesn't take range requests sends the whole file at the first request.
- `clearCache`: Empties each server source's cache, so its files are downloaded again.
  - `cleared`: Optional. Called once the caches are empty.
  - `failed`: Optional. Receives why a cache can't be emptied. When omitted, the failure is logged.
- `deleteCopy`: Deletes every server source's kept copy of a file, and its record, so the next load downloads it.
  - `path`: The file's path.
  - `deleted`: Optional. Called once the copies are gone.
  - `failed`: Optional. Receives why a copy can't be deleted. When omitted, the failure is logged with the path.

  A file system source's file is left alone. A copy that isn't there is already deleted.
- `poll`: Answers what finished with nothing of the platform's to wait on: a file held in memory, a refused path, a clearCache or deleteCopy.
  The program calls it once a frame, with the HTTP client's and file systems' polls.
- `dispose`: Aborts every load and locate in flight.
  Call it before disposing the HTTP client and file systems it was given.

## FileSystemSource

*class* in [`services/src/helix/services/assets/FileSystemSource.hx`](../../services/src/helix/services/assets/FileSystemSource.hx), `import helix.services.assets.FileSystemSource;`, extends `AssetSource`

Reads files as they are from a file system.

Natively this is usually the files the program ships with, a read-only `NativeFileSystemAdapter` over `ISystem.getProgramDirectory()`. Its files are never checked: they are what shipped.

```haxe
function new(fileSystem:IFileSystem)
```

- `new`: Creates the source over a file system.
  - `fileSystem`: The file system the files are read from.

## ManifestCache

*class* in [`services/src/helix/services/assets/ManifestCache.hx`](../../services/src/helix/services/assets/ManifestCache.hx), `import helix.services.assets.ManifestCache;`, extends `AssetCache`

Uses the server's manifests to tell whether a copy is current, so a run asks for the root manifest alone.

A copy kept under the hash its manifest lists is used without asking. A shipped file that its own manifests list at that hash is read in place. Otherwise the file is downloaded and hashed once: bytes that don't have the listed hash are not kept, and the load fails. A file its directory's manifest leaves out is asked about, and a copy of a name a newer manifest no longer lists is removed when that manifest arrives. A server with no manifest is warned about once a run and treated as `RevalidateCache` treats it.

The manifests are the ones `AssetManifests` writes.

```haxe
function new(fileSystem:IFileSystem, ?options:ManifestCacheOptions)
```

- `new`: Creates the cache over a file system used for nothing else.
  - `fileSystem`: Where copies are kept.
  - `options`: Optional. The manifests' file name, and the shipped file systems whose manifests show a file is already here.

## ManifestCacheOptions

*class* in [`services/src/helix/services/assets/ManifestCacheOptions.hx`](../../services/src/helix/services/assets/ManifestCacheOptions.hx), `import helix.services.assets.ManifestCacheOptions;`

Specifies how a `ManifestCache` finds manifests.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?manifestName:String, ?shipped:Array<IFileSystem>}
```

```haxe
final manifestName:String = "manifest.json"
final shipped:Array<IFileSystem> = []
```

- `manifestName`: Gets each directory's manifest's file name. Defaults to "manifest.json", the name `AssetManifests` writes.
- `shipped`: Gets the file systems whose files may be read in place of a download, by their own manifests. Defaults to none.
  List the same file systems as `FileSystemSource`s after the server, so they also answer offline.

## MemoryCache

*class* in [`services/src/helix/services/assets/MemoryCache.hx`](../../services/src/helix/services/assets/MemoryCache.hx), `import helix.services.assets.MemoryCache;`, extends `AssetCache`

Keeps nothing between runs. Each file is downloaded once a run and held in memory. It is meant for development.

Its downloads ask past the HTTP caches, so a run sees the server's files as they are now.

```haxe
function new()
```

- `new`: Creates the cache.

## RevalidateCache

*class* in [`services/src/helix/services/assets/RevalidateCache.hx`](../../services/src/helix/services/assets/RevalidateCache.hx), `import helix.services.assets.RevalidateCache;`, extends `AssetCache`

Uses a copy without asking while the server's Cache-Control says it is fresh, and asks the server about any other copy.

A copy is known by the server's ETag and Last-Modified. An unchanged file keeps its copy, a changed one replaces it, and a file the server says is gone (4xx) removes it. When the server doesn't answer, the copy is used. Nothing is hashed.

```haxe
function new(fileSystem:IFileSystem)
```

- `new`: Creates the cache over a file system used for nothing else, which `Assets.clearCache` empties.
  - `fileSystem`: Where copies are kept: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory()`, in a page a `BrowserFileSystemAdapter` named by it.

## ServerSource

*class* in [`services/src/helix/services/assets/ServerSource.hx`](../../services/src/helix/services/assets/ServerSource.hx), `import helix.services.assets.ServerSource;`, extends `AssetSource`

Downloads files from an HTTP server, under a URL, and keeps copies as its cache decides.

The URL is the directory the paths are under. In a page it may be relative to the page, and "" is the page's own directory.

```haxe
function new(url:String, http:IHttp, cache:AssetCache)
```

- `new`: Creates the source.
  - `url`: The directory the paths are under.
  - `http`: The HTTP client that downloads the files.
  - `cache`: Decides whether a kept copy is current, and keeps copies: a `RevalidateCache`, `TrustCache`, `MemoryCache` or `ManifestCache`.

## TrustCache

*class* in [`services/src/helix/services/assets/TrustCache.hx`](../../services/src/helix/services/assets/TrustCache.hx), `import helix.services.assets.TrustCache;`, extends `AssetCache`

Uses a copy without asking, however old it is. It suits files that never change, or a game that plays offline.

A file not kept yet is downloaded and kept; a file the server says is gone (4xx) when it is downloaded removes its copy. Nothing is hashed.

```haxe
function new(fileSystem:IFileSystem)
```

- `new`: Creates the cache over a file system used for nothing else, which `Assets.clearCache` empties.
  - `fileSystem`: Where copies are kept: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory()`, in a page a `BrowserFileSystemAdapter` named by it.
