# helix.services.assets

[Back to the library](README.md)

## AssetCache

*class* in [`libs/services/src/helix/services/assets/AssetCache.hx`](../src/helix/services/assets/AssetCache.hx), `import helix.services.assets.AssetCache;`

Decides whether a server's kept copy of a file is current, and keeps the copies. Construct one of its kinds.

## AssetSource

*class* in [`libs/services/src/helix/services/assets/AssetSource.hx`](../src/helix/services/assets/AssetSource.hx), `import helix.services.assets.AssetSource;`

Specifies a place `Assets` finds files. Construct a `FileSystemSource` or a `ServerSource`.

```haxe
function resolve(path:String):Null<String>
var writable(get, never):Bool
```

- `resolve`: Returns where this source reads a path from: the path, its `.` and `..` followed by the rules of this source's root, joined to the root when it is relative, or as it is when it is absolute and under the root.
  - `path`: The path as passed to `Assets`.
  - returns: The location, or null when the path is not under this source's root.
- `writable`: Gets a value indicating whether `Assets.write` writes to this source.

## Assets

*class* in [`libs/services/src/helix/services/assets/Assets.hx`](../src/helix/services/assets/Assets.hx), `import helix.services.assets.Assets;`, implements `IPollable`

Provides files by path, from file systems on this machine and from HTTP servers whose files it keeps copies of, and writes files to the file systems that accept them.

It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next: a read of a file the program hasn't written yet asks the server after the data directory, and the server answers that it has none. A game whose files never change lists its file system alone (`FileSystemSource`). A game that writes files of its own lists a writable file system over its data directory first, so a file it writes is the one it reads back. A game patched from a server lists the server first, with a `ManifestCache` provided the shipped files, and its shipped files after it. A shipped file that the server's manifest lists at the same hash is then read in place, and only what changed is downloaded. A page, whose files are on the server that served it, lists a `ServerSource` at "".

A path is passed to each source unchanged: a name (`levels/1.json`), a relative path (`./a.png`, `../b.png`), an absolute directory path, or a URL. Each source reads it by its own root's rules and resolves it against that root (`AssetSource.resolve`). A source the path isn't under is passed over. A relative path is under every root it doesn't climb above, and an absolute path or a URL is under the roots it is under. A source follows a path's `.` and `..`: `levels/../custom/1.json` reads `custom/1.json`. A path one file names relative to itself is made with `join`. A path not under any asset source's root is refused with "Invalid file path: <path> is outside every asset source's root", or the reason a subclass words (`outside`). The name a path resolves to under a root is the kind `IFileSystem` accepts (`FilePath`), from every source, so a name is refused alike on every target.

A failure names the path as passed. A file not found in any asset source fails with "<path>: file not found in any of the asset sources". Each call answers once, on the main thread, in a later poll, never during the call. The failure callback is optional; when it is omitted, the failure is logged with the path.

The program polls the assets once a frame, with the HTTP client and file systems it was provided. Downloads and copies finish in their polls, and what Assets answers with nothing of theirs to wait on (a file held in memory, a refused path) in its own. Assets that are never polled answer nothing.

A file can change while the program runs, as a development server's do. Assets doesn't watch for it: whoever knows a file changed calls `notifyChanged` with its path or the URL it was served at, and each `watch` of that file receives the new bytes. A page's development build wires hotreload-hx in one line, `reloader.assetsChanged = urls -> for (url in urls) assets.notifyChanged(url);`. Natively nothing calls it, and there is no watcher.

```haxe
var httpClient:IHttp = new HaxeHttpAdapter();
var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
var data:IFileSystem = new NativeFileSystemAdapter({directory: system.getDataDirectory()});
var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory()});

// The shipped files alone, never checked:
var assets = new Assets([new FileSystemSource(shipped)]);
// The game's own files first, written there, then the shipped files:
var assets = new Assets([new FileSystemSource(data, true), new FileSystemSource(shipped)]);
// The shipped files first, a server for what they don't have:
var assets = new Assets([new FileSystemSource(shipped), new ServerSource("https://example.com/game/", httpClient, new RevalidateCache(downloads))]);
// A server first, patching what shipped by its manifests:
var patching = new ManifestCache(downloads, {shipped: [shipped]});
var assets = new Assets([new ServerSource("https://example.com/game/", httpClient, patching), new FileSystemSource(shipped)]);
// In a page, the game's own files in a database, then the files beside the page:
var kept = new RevalidateCache(new BrowserFileSystemAdapter({name: system.getCacheDirectory()}));
var own = new BrowserFileSystemAdapter({name: system.getDataDirectory()});
var assets = new Assets([new FileSystemSource(own, true), new ServerSource("", new FetchApiHttpAdapter(), kept)]);

assets.read("levels/1.json", bytes -> start(bytes));
assets.write("progress.json", Bytes.ofString(progress));
// each frame, with the platform's other polls:
httpClient.poll();
data.poll();
downloads.poll();
shipped.poll();
assets.poll();
```

```haxe
function new(sources:Array<AssetSource>)
static function join(from:String, path:String):String
function setSources(sources:Array<AssetSource>):Void
function read(path:String, read:haxe.io.Bytes -> Void, ?missing:() -> Void, ?failed:String -> Void):() -> Void
function write(path:String, bytes:haxe.io.Bytes, ?written:() -> Void, ?failed:String -> Void):() -> Void
function list(path:String, listed:Array<String> -> Void, ?failed:String -> Void):() -> Void
function listCache(path:String, listed:(Array<{url:String, path:String}>) -> Void, ?failed:String -> Void):() -> Void
function watch(path:String, changed:haxe.io.Bytes -> Void):() -> Void
function notifyChanged(path:String):Void
function locate(path:String, located:(source:StreamSource, release:() -> Void) -> Void, ?failed:String -> Void):() -> Void
function clearCache(?cleared:() -> Void, ?failed:String -> Void):Void
function deleteCopy(path:String, ?deleted:() -> Void, ?failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the assets over their sources, asked in order.
  - `sources`: The places files are found. A file missing from one source is looked for in the next.
- `join`: Returns the path a file names relative to itself, as a link in a page does: the path joined to the directory of the file naming it. Its `.` and `..` are kept, for the sources to follow.
  - `from`: The path of the file naming the other, as passed to `read`.
  - `path`: The path it names. An absolute path or a URL is returned as it is.
  - returns: The path to pass to `read`.

  `join("levels/1.json", "../custom/1.json")` returns `"levels/../custom/1.json"`, which reads `custom/1.json`.
- `setSources`: Sets the sources, as a program does when a player turns a mod on. Every call made from now on asks them.
  - `sources`: The places files are found, asked in order.

  A call in flight is answered by the sources it was made over. Poll their HTTP clients and file systems until it is.
- `read`: Reads a whole file.
  - `path`: The file's path: a name, a relative or absolute directory path, or a URL.
  - `read`: Receives the file's bytes.
  - `missing`: Optional. Called when the file is not found in any asset source, or the path is invalid, and the reason is logged. When omitted, either is a failure.
  - `failed`: Optional. Receives why the file can't be read: the last source asked failed, or, when `missing` is omitted, the file is not found in any asset source or the path is invalid.
  - returns: The abort: nothing is called after it.
- `write`: Writes a whole file, to the first source that resolves the path and is writable, and hands the bytes to each `watch` of it.
  - `path`: The file's path: a name, or a relative or absolute directory path.
  - `bytes`: The file's bytes.
  - `written`: Optional. Called once the file is written.
  - `failed`: Optional. Receives why it wasn't: the path is not under any asset source's root, "<path>: not under any writable asset source's root", or the file system's failure.
  - returns: The abort: nothing is called after it, though the write may still finish.

  A file written is read back from that source, unless a source before it has the path too.
- `list`: Lists a directory's files and subdirectories in every file system source that resolves it, as one sorted list.
  - `path`: The directory's path: a name, a relative or absolute directory path, or "" for every root.
  - `listed`: Receives the names, a subdirectory's ending in `/`, such as `["1.json", "bonus/"]`. A name in two sources is listed once. A directory not found in any file system source is listed as `[]`.
  - `failed`: Optional. Receives why the directory can't be listed: the path is not under any asset source's root, or a file system's failure.
  - returns: The abort: nothing is called after it.

  A server source's files aren't listed, since a server can't list a directory. Each server source that resolves the directory is logged at INFO: "<path>: files served from <url> aren't listed". Its cache's copies are listed by `listCache`.
- `listCache`: Lists the files currently cached under a path.
  - `path`: The directory's path: a name, a relative or absolute directory path, a URL, or "" for every root.
  - `listed`: Receives the copies, sorted by path. Each has its path from its server source's root, the form `read` accepts (`levels/1.json` for `listCache("levels")`), and the URL it was downloaded from.
  - `failed`: Optional. Receives why a cache can't be listed.
  - returns: The abort: nothing is called after it.
- `watch`: Calls a function with a file's new bytes each time a change of it is brought in (`notifyChanged`) or written (`write`), until the returned function is called.
  - `path`: The file's path: a name, a relative or absolute directory path, or a URL.
  - `changed`: Receives the file's bytes, each time a change brings a new copy.
  - returns: A function that stops the watch; nothing is called after it.

  Two paths are the same file when a source resolves them to the same location, so a change notified or written by one reaches a watch of the other: a watch of `levels/../custom/1.json` receives a change of `custom/1.json`, and the other way round.

  Nothing is read now: a path watched and never changed is never read by the watch.
- `notifyChanged`: Brings a file in again because it changed, past every cache, and hands the new bytes to each `watch` of it.
  - `path`: The file's path: a name, a relative or absolute directory path, or a URL. A URL a development server reports is one: `reloader.assetsChanged = urls -> for (url in urls) assets.notifyChanged(url);`.

  The file is asked of the sources in order, as `read` asks: a server's past the browser's HTTP cache (no-store) and past the copy its cache keeps, the new copy then kept in its place, so a later `read` gets it. A file that can't be brought in keeps the old copy, and no watch is called; the failure is logged with the path. Nothing is called during the call.

  A file a file system source has is read again from it, and a written file's watches already received it from `write`. A file no source has is logged with its path, and no watch receives anything.

  In a page at `https://example.com/game/` with a `ServerSource` at "", `notifyChanged("https://example.com/game/levels/2.json")`, `notifyChanged("/game/levels/2.json")` and `notifyChanged("levels/2.json")` each reach a watch of `levels/2.json`.
- `locate`: Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` accepts.
  - `path`: The file's path: a name, a relative or absolute directory path, or a URL.
  - `located`: Receives the source, and a release function to call once when the source is no longer read.
  - `failed`: Optional. Receives why the file can't be found.
  - returns: The abort: nothing is called after it.

  A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise, natively, it plays as it downloads, and the copy is kept; in a page it is located once it is kept. A native download asks for the file's last 64 KiB first and then the rest, so the stream's length can be read before it has all arrived, as a browser's media element does. A server that doesn't accept range requests sends the whole file at the first request.
- `clearCache`: Empties each server source's cache, so its files are downloaded again.
  - `cleared`: Optional. Called once the caches are empty.
  - `failed`: Optional. Receives why a cache can't be emptied. When omitted, the failure is logged.
- `deleteCopy`: Deletes every server source's kept copy of a file, and its record, so the next load downloads it.
  - `path`: The file's path: a name, a relative or absolute directory path, or a URL.
  - `deleted`: Optional. Called once the copies are gone.
  - `failed`: Optional. Receives why a copy can't be deleted. When omitted, the failure is logged with the path.

  A file system source's file is left alone. A copy that isn't there is already deleted.
- `poll`: Answers what finished with nothing of the platform's to wait on: a file held in memory, a refused path, a clearCache or deleteCopy.
  The program calls it once a frame, with the HTTP client's and file systems' polls.
- `dispose`: Aborts every call in flight.
  Call it before disposing the HTTP client and file systems it was provided.

## FileSystemSource

*class* in [`libs/services/src/helix/services/assets/FileSystemSource.hx`](../src/helix/services/assets/FileSystemSource.hx), `import helix.services.assets.FileSystemSource;`, extends `AssetSource`

Reads files as they are from a file system, and writes them there when it is writable.

Natively the shipped files are usually a read-only `NativeFileSystemAdapter` over `ISystem.getProgramDirectory()`. Its files are never checked: they are what shipped. A game's own files are a `NativeFileSystemAdapter` over `ISystem.getDataDirectory()`, made writable, or in a page a `BrowserFileSystemAdapter` named for it.

Its root is the file system's (`IFileSystem.root`). Natively, when the root is a directory, a path is read as a directory path: `\` is a separator on Windows, where a drive letter's case is ignored, and `..` climbs a directory. A page's database stores names alone: a relative path's `.` and `..` are followed, and an absolute path is not under any database's root.

A link under the root is followed: a file reached through it is read and written, even when it is outside the root.

```haxe
function new(fileSystem:IFileSystem, ?writable:Bool = false)
```

- `new`: Creates the source over a file system.
  - `fileSystem`: The file system the files are read from.
  - `writable`: Optional, false by default. Whether `Assets.write` writes files to it.

## KeptCopies

*class* in [`libs/services/src/helix/services/assets/KeptCopies.hx`](../src/helix/services/assets/KeptCopies.hx), `import helix.services.assets.KeptCopies;`

Represents the copies a server's files are kept as in a file system, each with its record, which `RevalidateCache`, `TrustCache` and `ManifestCache` keep their copies in.

A program constructs one over a cache's file system to list or empty every server's copies without a server source, as a settings screen showing the cache does. Several caches can keep their copies in one file system, and emptying one empties them all.

A server's copies are under a directory of its own: the bytes at `files/<path>`, the record at `records/<path>`, and the server's URL in `url`. The pair is kept in an order that never leaves a record beside bytes it doesn't describe: a replacement deletes the old record, writes the bytes, then writes the record; a removal deletes the record, then the bytes. A copy is read only with its record, and only when it has the record's byte count; otherwise both are deleted and the file is downloaded again.

```haxe
function new(fileSystem:IFileSystem)
final fileSystem:IFileSystem
function listCopies(directory:String, listed:(Array<{url:String, path:String}>) -> Void, failed:String -> Void):Void
function clearCopies(cleared:() -> Void, failed:String -> Void):Void
```

- `new`: Creates the copies over a file system used for nothing else.
  - `fileSystem`: Where the copies are kept.
- `fileSystem`: Gets the file system the copies are kept in.
- `listCopies`: Lists every server's copies under a directory, its subdirectories' too, whatever server sources use the file system now.
  - `directory`: The directory, from each server's root. "" lists every copy.
  - `listed`: Receives the copies, sorted by path and then by URL. Each is its path from its server's root, and the URL it was downloaded from. The URL is the path alone when the server's URL isn't recorded.
  - `failed`: Receives why the copies can't be listed.

  It answers in the file system's polls.
- `clearCopies`: Deletes every server's copies and records.
  - `cleared`: Called once the file system is empty.
  - `failed`: Receives why the copies can't be deleted.

  It answers in the file system's polls.

## ManifestCache

*class* in [`libs/services/src/helix/services/assets/ManifestCache.hx`](../src/helix/services/assets/ManifestCache.hx), `import helix.services.assets.ManifestCache;`, extends `AssetCache`

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

*class* in [`libs/services/src/helix/services/assets/ManifestCacheOptions.hx`](../src/helix/services/assets/ManifestCacheOptions.hx), `import helix.services.assets.ManifestCacheOptions;`

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

*class* in [`libs/services/src/helix/services/assets/MemoryCache.hx`](../src/helix/services/assets/MemoryCache.hx), `import helix.services.assets.MemoryCache;`, extends `AssetCache`

Keeps nothing between runs. Each file is downloaded once a run and held in memory. It is meant for development.

Its downloads ask past the HTTP caches, so a run sees the server's files as they are now.

```haxe
function new()
```

- `new`: Creates the cache.

## RevalidateCache

*class* in [`libs/services/src/helix/services/assets/RevalidateCache.hx`](../src/helix/services/assets/RevalidateCache.hx), `import helix.services.assets.RevalidateCache;`, extends `AssetCache`

Uses a copy without asking while the server's Cache-Control says it is fresh, and asks the server about any other copy.

A copy is known by the server's ETag and Last-Modified. An unchanged file keeps its copy, a changed one replaces it, and a file the server says is gone (4xx) removes it. When the server doesn't answer, the copy is used. Nothing is hashed.

```haxe
function new(fileSystem:IFileSystem)
```

- `new`: Creates the cache over a file system used for nothing else, which `Assets.clearCache` empties.
  - `fileSystem`: Where copies are kept: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory()`, in a page a `BrowserFileSystemAdapter` named by it.

## ServerSource

*class* in [`libs/services/src/helix/services/assets/ServerSource.hx`](../src/helix/services/assets/ServerSource.hx), `import helix.services.assets.ServerSource;`, extends `AssetSource`

Downloads files from an HTTP server, under a URL, and stores copies in its cache, as the cache decides. It is never written to.

A read of a download answers once its copy is written to the cache, so `Assets.listCache` lists it from then on. A copy the cache can't write is logged, and the read still answers with the bytes.

The URL is the directory the paths are under, and the source's root. In a page it may be relative to the page, and "" is the page's own directory. A path is read by URL rules: a relative path is resolved against the URL, a URL under the source's URL is under the root, and so is a path from the server's root under the URL's path (`/assets/a.png` for a source at `https://example.com/assets/`).

```haxe
function new(url:String, http:IHttp, cache:AssetCache)
```

- `new`: Creates the source.
  - `url`: The directory the paths are under.
  - `http`: The HTTP client that downloads the files.
  - `cache`: Decides whether a kept copy is current, and keeps copies: a `RevalidateCache`, `TrustCache`, `MemoryCache` or `ManifestCache`.

## TrustCache

*class* in [`libs/services/src/helix/services/assets/TrustCache.hx`](../src/helix/services/assets/TrustCache.hx), `import helix.services.assets.TrustCache;`, extends `AssetCache`

Uses a copy without asking, however old it is. It suits files that never change, or a game that plays offline.

A file not kept yet is downloaded and kept; a file the server says is gone (4xx) when it is downloaded removes its copy. Nothing is hashed.

```haxe
function new(fileSystem:IFileSystem)
```

- `new`: Creates the cache over a file system used for nothing else, which `Assets.clearCache` empties.
  - `fileSystem`: Where copies are kept: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory()`, in a page a `BrowserFileSystemAdapter` named by it.
