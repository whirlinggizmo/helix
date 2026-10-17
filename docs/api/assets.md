# helix.assets

[Back to the index](README.md)

## AssetCacheMode

*enum* in `src/helix/assets/IAssets.hx`

How the cache treats a downloaded copy no manifest lists (IAssets.setCacheMode); a listed one follows its manifest in every mode, and ensure's forceFetch downloads past the cache in every mode. - Revalidate, the default: a copy fresh by the host's Cache-Control (max-age not passed, or immutable) is used with no request; any other is asked about first: 304, the copy is used (and fresh again); 200, the new file replaces it; 4xx, the copy is deleted and the load fails; no answer (offline, a timeout) or a 5xx, the copy is used. no-cache and no-store make a copy never fresh, but it's kept, for the next check and for starting offline. - Trust: a copy is used without asking, however old: offline-first play, files that never change, or a game that evicts by itself. - Off: nothing is kept between runs, and what earlier runs kept is neither used nor deleted (development); this run's downloads are held in memory, so a file loads once a run.

- `Revalidate`
- `Trust`
- `Off`

## AssetManifest

*class* in `src/helix/assets/AssetManifest.hx`

One directory's asset manifest (tools/gen_manifest.py writes them): the hash of each file in it, and of each subdirectory's own manifest, so an unchanged directory is known unchanged from its parent alone, as git knows a tree. The JSON is `{"manifest": 1, "files": {"name": "sha256:<64 hex>"}, "dirs": {"name": "sha256:<64 hex>"}}`; other top-level keys are ignored.

```haxe
static function parse(bytes:haxe.io.Bytes):Null<AssetManifest>
static function isHash(value:String):Bool
static function hash(bytes:haxe.io.Bytes):String
final files:Map<String, String>
final dirs:Map<String, String>
```

- `parse`: The manifest in bytes, or null for anything that isn't one exactly: not JSON, another version, a hash that isn't "sha256:" and 64 lower-case hex digits, or a name that is empty, "." or "..", or holds a "/". A manifest wrong anywhere is trusted nowhere.
- `isHash`: Whether value is a hash as manifests write them: "sha256:" and 64 lower-case hex digits.
- `hash`: bytes' hash as manifests write it.
- `files`: The hash of each file, by name.
- `dirs`: The hash of each subdirectory's manifest, by name.

## AssetPath

*class* in `src/helix/assets/AssetPath.hx`

Validates asset and storage keys, for the asset service, the shared Storage and model files.

```haxe
static function isValid(path:String):Bool
```

- `isValid`: Whether path is a safe relative path: 1 to 256 characters of A-Z, a-z, 0-9, '_', '.', '-' and '/', with no empty, "." or ".." segment (so no leading slash and no URL).

## AssetProgress

*typedef* in `src/helix/assets/IAssets.hx`

Load progress: phase ("locating", "downloading", "storing" or "ready"), bytes received, and total bytes, or null when unknown.

- `totalBytes:Null<Int>`
- `receivedBytes:Int`
- `phase:String`

## AssetResult

*enum* in `src/helix/assets/IAssets.hx`

How an asset load ended: its bytes, a failure message, or cancellation.

- `Loaded(bytes:haxe.io.Bytes)`
- `Failed(message:String)`
- `Cancelled`

## AssetService

*class* in `src/helix/assets/AssetService.hx`

Asset identity/cache policy stays shared. No target conditionals.

```haxe
function new(fetcher:Fetch, cache:Storage, packaged:Storage, base:Null<String>)
function load(path:String, complete:AssetResult -> Void):Void
function ensure(path:String, complete:AssetResult -> Void, ?progress:AssetProgress -> Void, ?options:Null<EnsureOptions>):IRequest
function getManifest():Null<String>
function setManifest(path:Null<String>):Bool
function getHost():Null<String>
function setHost(host:Null<String>):Bool
function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool -> Void):IRequest
function getCacheMode():AssetCacheMode
function setCacheMode(mode:AssetCacheMode):Void
function clearCache(complete:StorageWriteResult -> Void):IRequest
function streamSource(path:String, complete:AssetSourceResult -> Void):IRequest
function subscribe(path:String, target:IReloadable):Void
function unsubscribe(path:String, target:IReloadable):Void
function changed(path:String):Void
function isBusy():Bool
function poll():Void
function shutdown():Void
```

- `new`: Loads through fetcher when base (the URL put before each path) is set, or else from the read-only packaged store, keeping each asset in cache under a key of base and path. It polls and shuts down all three.
- `changed`: A file changed: load it again past every cache, keep the new copy, and tell the path's subscribers. A failure keeps what they have.
- `poll`: Polls the fetcher, cache and packaged store, then runs queued work and completions within the work budget. Call once per frame on the host thread.
- `shutdown`: Cancels every pending request (each completes Cancelled), shuts down the fetcher, cache and packaged store, and runs queued completions. Later requests fail.

## AssetSourceResult

*enum* in `src/helix/assets/IAssets.hx`

How locating a streamed asset ended: its location, a failure message, or cancellation.

- `Located(value:AudioLocation)`
- `Failed(message:String)`
- `Cancelled`

## AudioLocation

*enum* in `src/helix/assets/IAssets.hx`

Where a streamed audio asset is read from: a leased local copy, which its holder releases, or a remote URL.

- `Stored(value:Lease)`
- `Remote(url:String)`

## CacheRecord

*typedef* in `src/helix/assets/AssetManifest.hx`

What the cache keeps beside a downloaded file: the response's validators (its ETag and Last-Modified), until when the copy is fresh (seconds since 1970, from Cache-Control: max-age, or a year for immutable; no time at all otherwise), and the hash of the bytes kept.

- `source:Null<String>`: The URL the bytes came from when it isn't the path's own (an ensure with a source): the copy is asked about there, and streamed from there when it's stale, as the host has nothing at the path.
- `lastModified:Null<String>`
- `hash:String`
- `freshUntil:Float`
- `etag:Null<String>`

## CacheRecords

*class* in `src/helix/assets/AssetManifest.hx`

Reading and writing CacheRecords.

```haxe
static function parse(bytes:haxe.io.Bytes):Null<CacheRecord>
static function of(headers:Map<String, String>, hash:String, now:Float, ?source:String):CacheRecord
static function freshSeconds(control:Null<String>):Float
static function encode(record:CacheRecord):haxe.io.Bytes
```

- `parse`: The record in bytes, or null when they aren't one (or are from before records were kept).
- `of`: The record for a response's headers (lower-case names) at now (seconds since 1970), for bytes of hash, from source when that isn't the path's own URL.
- `freshSeconds`: How long a response stays fresh by its Cache-Control, in seconds: its max-age, a year for immutable without one, none when it says no-store or no-cache, or says nothing.
- `encode`: The record as bytes to keep.

## EnsureOptions

*typedef* in `src/helix/assets/IAssets.hx`

How ensure finds a file. source: where its bytes come from instead of its own path, a path read against the host as a browser reads a URL against a directory, or a whole URL; they're kept under the path asked for, remembering where they came from: a later plain load of the path asks about the copy there, and it streams from there when it's stale, as the host has nothing at the path. forceFetch: go past the cache to the host (or the packaged files), replacing what the cache holds.

- `source:Null<String>`
- `forceFetch:Null<Bool>`

## ExportResult

*enum* in `src/helix/assets/IExport.hx`

Where an exported file went: a path natively, the downloaded file's name in a browser; or why it couldn't be.

- `Exported(where:String)`
- `Failed(message:String)`

## Fetch

*class* in `src/helix/assets/Fetch.hx`

Bounded whole-response GETs over a platform's IHttp, the same on every platform: at most two at once, each body limited and the whole transfer timed, progress coalesced to once a frame, completions on the host thread.

```haxe
function new(http:IHttp)
function fetch(request:FetchRequest, complete:FetchResult -> Void, ?progress:FetchProgress -> Void):IRequest
function poll():Void
function shutdown():Void
```

- `new`: Fetches over http.
- `fetch`: Queues a GET of request.url. complete runs exactly once on the host thread; Failed for a maxBytes or timeoutSeconds not above 0, a closed service, a body over maxBytes, a timeout, or a transport failure. progress, if given, runs on the host thread at most once a frame.
- `poll`: Delivers what arrived, fails fetches past their time, starts queued ones and runs completions. Call once per frame.
- `shutdown`: Cancels every pending fetch (each completes Cancelled), refuses later ones, and aborts the platform's transfers.

## FetchProgress

*typedef* in `src/helix/assets/Fetch.hx`

Body bytes received so far, and the total from Content-Length, or null when unknown (or the body is compressed).

- `totalBytes:Null<Int>`
- `receivedBytes:Int`

## FetchRequest

*typedef* in `src/helix/assets/Fetch.hx`

A GET of url: maxBytes limits the body (default 8 MiB), timeoutSeconds bounds the whole transfer (default 15), noCache bypasses HTTP caches (default false), headers are sent with it (none by default).

- `url:String`
- `timeoutSeconds:Null<Float>`
- `noCache:Null<Bool>`
- `maxBytes:Null<Int>`
- `headers:Null<Map<String, String>>`

## FetchResponse

*typedef* in `src/helix/assets/Fetch.hx`

A complete response: HTTP status, headers with lower-case names, and the whole body.

- `status:Int`
- `headers:Map<String, String>`
- `bytes:haxe.io.Bytes`

## FetchResult

*enum* in `src/helix/assets/Fetch.hx`

How a fetch ended: a response of any HTTP status, a transport failure message, or cancellation.

- `Response(value:FetchResponse)`
- `Failed(message:String)`
- `Cancelled`

## IAssets

*class* in `src/helix/assets/IAssets.hx`

The asset service games load through (AssetService): assets by relative path through the cache, streamed audio locations, and hot reload subscriptions. Completions run on the host thread.

```haxe
function load(path:String, complete:AssetResult -> Void):Void
function ensure(path:String, complete:AssetResult -> Void, ?progress:AssetProgress -> Void, ?options:Null<EnsureOptions>):IRequest
function getHost():Null<String>
function setHost(host:Null<String>):Bool
function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool -> Void):IRequest
function getManifest():Null<String>
function setManifest(path:Null<String>):Bool
function getCacheMode():AssetCacheMode
function setCacheMode(mode:AssetCacheMode):Void
function clearCache(complete:StorageWriteResult -> Void):IRequest
function streamSource(path:String, complete:AssetSourceResult -> Void):IRequest
function subscribe(path:String, target:IReloadable):Void
function unsubscribe(path:String, target:IReloadable):Void
function isBusy():Bool
```

- `load`: Loads path's bytes as ensure does, without progress or a way to cancel.
- `ensure`: Loads path's bytes: downloaded from the host when one is set and kept in the cache, or else read from the packaged files in place. A cached copy is used only while it's current: when a manifest (setManifest) lists the file, while the copy has the manifest's hash (else the file is downloaded past HTTP caches and kept only if it has it); otherwise while the host's Cache-Control says it's fresh, and then after asking the host (its ETag and Last-Modified sent): 304 keeps it, 200 replaces it, 4xx deletes it, and no answer (offline, a 5xx) uses it. complete runs exactly once on the host thread; Failed for an invalid path, a closed service, a missing asset, an HTTP status outside 200-299 with no copy to use, a download that doesn't match its manifest, or a storage or transport error. progress, if given, reports each phase until the request settles.
- `getHost`: What's put before each path to download it, ending in "/": a URL, or a folder relative to the page (the browser's "assets/"); null when files are read from the program's packaged files (natively, unless HELIX_ASSET_HOST names a host).
- `setHost`: Downloads from host from now on (a "/" is added if it has none), or reads the packaged files with null. The cache keeps each host's files apart. False for an empty host.
- `pingHost`: Whether host answers: it serves probePath (an asset it should have) within timeoutSeconds. complete runs once, on the host thread.
- `getManifest`: The root manifest's path under the host ("manifest.json"), or null for none (the default).
- `setManifest`: Uses the manifest tree under the host from path (tools/gen_manifest.py writes one): the root asked about once a run (its cached copy used offline), a directory's manifest loaded only when an asset under it is, and again only when its hash changes; a file it lists is used from the cache with no request while the copy has its hash. A host without one, and a file none lists, are treated as the cache mode says (setCacheMode); a file its directory's manifest leaves out is asked about however fresh, as it has changed or gone. Null for none. False for a path that isn't a valid asset path.
- `getCacheMode`: How downloaded copies no manifest lists are treated (AssetCacheMode); Revalidate by default.
- `setCacheMode`: Treats every copy checked from now on as mode says.
- `clearCache`: Forgets every downloaded file, so the next load downloads it again, and what was read of the manifests, so the root is asked about again. complete runs once, on the host thread.
- `streamSource`: Locates path for streaming without loading it whole: a leased cached copy while it's current (as ensure says, without asking the host), else the remote URL (a base URL is set) or a leased packaged copy. complete runs exactly once on the host thread; the caller releases a Located(Stored) lease, and one that arrives after cancellation is released for it. Failed for an invalid path, a closed service, a missing packaged asset, or a storage error.
- `subscribe`: Tell target when path's file changes and has loaded again (development hot reload). One target per path once.
- `unsubscribe`: Stops telling target about path's changes; does nothing if it was not subscribed.
- `isBusy`: Whether a load is under way or its completion not yet run (Services.isBusy asks it, with the decoders).

## IExport

*class* in `src/helix/assets/IExport.hx`

Hands a finished file to the user on a platform: a browser downloads it, natively it is written into the directory the profile chose (the user's pictures, say). What is exported and what it is called are the caller's (Screenshots names its files).

```haxe
function export(name:String, mimeType:String, bytes:haxe.io.Bytes, done:ExportResult -> Void):Void
```

- `export`: Hands bytes over as a file called name (a plain file name: no directory, not hidden), of mimeType ("image/png"); a file of that name natively is replaced. done runs once on the host thread, during this call or later: Exported, or Failed (no room, no permission). Throws for a name that isn't a plain file name.

## IHttp

*class* in `src/helix/assets/IHttp.hx`

HTTP GET on a platform: a response arriving in parts. Limits, timeouts, progress and queuing are the shared Fetch's.

```haxe
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(Int, Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, end:Null<String> -> Void):() -> Void
function poll():Void
function shutdown():Void
```

- `get`: Starts a GET of url (relative to the page in a browser; http or https natively) with the request headers given (names in any case), bypassing HTTP caches when noCache (where the platform can). On the host thread, never during this call: head once (the HTTP status, and the headers with lower-case names), body for each part of the body as it arrives, then end once (null when the body is all here, else why the transfer failed). An HTTP error status is a response, not a failure. Returns abort: it stops the transfer where the platform can, and nothing is called after.
- `poll`: Delivers what arrived from the platform's threads since the last poll; the shared Fetch calls it once a frame.
- `shutdown`: Aborts every transfer.

## IReloadable

*class* in `src/helix/assets/IReloadable.hx`

Told when a subscribed asset's file changed and was loaded again (IAssets.subscribe). Called through the object, so after a hot reload its new code runs.

```haxe
function reloaded(path:String, bytes:haxe.io.Bytes):Void
```

- `reloaded`: path's file changed and loaded again as bytes, already in the cache; runs on the host thread. A throw is recorded as a failed reload.

## IRequest

*class* in `src/helix/assets/IRequest.hx`

Host-thread cancellation. Completion is asynchronous and exactly once.

```haxe
function cancel():Void
```

- `cancel`: Cancels the operation if it has not settled, so its completion reports Cancelled; does nothing once settled.

## IStore

*class* in `src/helix/assets/IStore.hx`

Files kept by key on a platform (a directory, IndexedDB). Keys are valid asset paths (the shared Storage checks them); limits, read-only refusal, queuing and cancellation are the shared Storage's. Each answer arrives on the host thread, never during the call that asked, and is never Cancelled.

```haxe
function read(key:String, maxBytes:Int, done:StorageResult -> Void):Void
function write(key:String, bytes:haxe.io.Bytes, done:StorageWriteResult -> Void):Void
function remove(key:String, done:StorageWriteResult -> Void):Void
function clear(done:StorageWriteResult -> Void):Void
function lease(key:String, done:StorageSourceResult -> Void):Void
function poll():Void
function shutdown():Void
```

- `read`: The file under key: Stored, Missing, or Failed (an I/O error, or a file over maxBytes).
- `write`: Stores bytes under key, replacing what is there: Written or Failed.
- `remove`: Deletes the file under key (Written also when there was none), or Failed.
- `clear`: Removes every file: Written or Failed.
- `lease`: Leases the file under key for streaming without reading it (a file path natively, a Blob URL in a browser): Local, Missing or Failed. The lease's release, called once, ends it.
- `poll`: Delivers what arrived from the platform's threads since the last poll; the shared Storage calls it once a frame.
- `shutdown`: Closes the store.

## Lease

*typedef* in `src/helix/assets/Storage.hx`

A lease on a stored file for streaming: location is a file path or URL the audio adapter opens, and release, called once, ends the lease.

- `release:() -> Void`
- `location:String`

## Request

*class* in `src/helix/assets/Request.hx`

The IRequest the asset service and audio resources return for work they settle themselves (Jobs returns its own): it settles exactly once, by finish or by cancel.

```haxe
function new(cancelled:() -> Void)
function isSettled():Bool
function finish():Bool
function cancel():Void
```

- `new`: cancelled runs once, when cancel settles the request.
- `isSettled`: Whether it has finished or been cancelled.
- `finish`: Settles the request: true the first time, false once it has finished or been cancelled.

## Storage

*class* in `src/helix/assets/Storage.hx`

Files by key (an asset path) over a platform's IStore, the same on every platform: keys checked, files at most 8 MiB, a read-only store refusing writes, at most two operations at once, each completing exactly once on the host thread. The app's cache, and the packaged assets read-only.

```haxe
function new(store:IStore, ?readOnly:Bool = false)
static var MAX_BYTES(inline, null):Int
function read(key:String, complete:StorageResult -> Void):IRequest
function write(key:String, bytes:haxe.io.Bytes, complete:StorageWriteResult -> Void):IRequest
function remove(key:String, complete:StorageWriteResult -> Void):IRequest
function source(key:String, complete:StorageSourceResult -> Void):IRequest
function clear(complete:StorageWriteResult -> Void):IRequest
function poll():Void
function shutdown():Void
```

- `new`: Files in store; readOnly refuses write, remove and clear (packaged assets).
- `MAX_BYTES`: The largest file it stores or reads, in bytes.
- `read`: Reads the whole file under key. Failed for an invalid key, a file over 8 MiB, a closed store, or an I/O error.
- `write`: Stores a copy of bytes under key, replacing what is there. Failed for an invalid key, more than 8 MiB, a read-only store, a closed store, or an I/O error.
- `remove`: Deletes the file under key; Written also when there was none. Failed for an invalid key, a read-only store, a closed store, or an I/O error.
- `source`: Leases the file under key for streaming without reading it; the caller releases a Local lease, and one that arrives after cancellation is released for it. Failed for an invalid key, a closed store, or an I/O error.
- `clear`: Removes every stored file; Failed for a read-only store.
- `poll`: Delivers what arrived, starts queued operations and runs completions. Call once per frame.
- `shutdown`: Cancels every pending operation (each completes Cancelled), refuses later ones and closes the store.

## StorageResult

*enum* in `src/helix/assets/Storage.hx`

How a read ended: the stored bytes, Missing, a failure message, or cancellation.

- `Stored(bytes:haxe.io.Bytes)`
- `Missing`
- `Failed(message:String)`
- `Cancelled`

## StorageSourceResult

*enum* in `src/helix/assets/Storage.hx`

How leasing a stored file ended: the lease, Missing, a failure message, or cancellation.

- `Local(value:Lease)`
- `Missing`
- `Failed(message:String)`
- `Cancelled`

## StorageWriteResult

*enum* in `src/helix/assets/Storage.hx`

How a write or remove ended: Written, a failure message, or cancellation.

- `Written`
- `Failed(message:String)`
- `Cancelled`
