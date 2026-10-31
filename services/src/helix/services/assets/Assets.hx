package helix.services.assets;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.log.Log;
import helix.platform.FilePath;
import helix.platform.GrowingSource;
import helix.platform.IFileSystem;
import helix.platform.IHttp;
import helix.platform.StreamSource;

/** Provides files by path, from a file system on this machine or from an HTTP server whose files it keeps copies of.

	It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next.
	A game whose files never change lists its file system alone. A game patched from a server lists the server first, in `Manifest`
	mode, and its shipped files after it. A shipped file that the server's manifest lists at the same hash is then read in place, and
	only what changed is downloaded. A page, whose files are on the server that served it, lists `HttpServer("")`.

	A path is plain names joined by `/`, as in `IFileSystem` (`FilePath`), from every source: a server is never asked for one the file
	systems would refuse, so a name fails alike in a page and natively. Each call answers once, on the main thread, in the platform `poll` that
	finished it, and never during the call. The failure callback is optional; when it is omitted, the failure is logged with the path.

	Downloads and copies finish in the polls of the HTTP client and file systems it was given, which the program polls each frame.
	Assets has no `poll` of its own.

	```haxe
	var httpClient:IHttp = new HaxeHttpAdapter();
	var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
	var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory()});

	// The shipped files alone, never checked:
	var assets = new Assets({sources: [FileSystem(shipped)]});
	// The shipped files first, a server for what they don't have:
	var assets = new Assets({sources: [FileSystem(shipped), HttpServer("https://example.com/game/")], httpClient: httpClient, cacheFileSystem: downloads});
	// A server first, patching what shipped by its manifests:
	var assets = new Assets({sources: [HttpServer("https://example.com/game/", Manifest), FileSystem(shipped)], httpClient: httpClient, cacheFileSystem: downloads});
	// In a page, the files beside the page:
	var assets = new Assets({sources: [HttpServer("")], httpClient: new FetchApiHttpAdapter(), cacheFileSystem: new BrowserFileSystemAdapter({name: system.getCacheDirectory()})});

	assets.load("levels/1.json", bytes -> start(bytes));
	// each frame, with the platform's other polls:
	httpClient.poll();
	downloads.poll();
	shipped.poll();
	``` */
class Assets {
	/** The largest file read whole from a file system. */
	static inline final MAX_BYTES = 1 << 30;

	final sources:Array<Source> = [];
	final requests:Array<Request> = [];
	final cacheFileSystem:Null<IFileSystem>;

	/** Creates the assets over their sources.

		@param options  The sources, and the HTTP client and file system that an `HttpServer` source needs.
		@throws String  When a source is an `HttpServer` and `httpClient` or `cacheFileSystem` is null. */
	public function new(options:AssetsOptions) {
		cacheFileSystem = options.cacheFileSystem;
		for (i in 0...options.sources.length)
			sources.push(switch options.sources[i] {
				case FileSystem(fileSystem): Files(fileSystem);
				case HttpServer(url, cacheMode): Server(server(options, i, url, cacheMode == null ? Revalidate : cacheMode));
			});
	}

	// A server source; in Manifest mode with the file systems after it, whose manifests may show a file is already here.
	static function server(options:AssetsOptions, i:Int, url:String, mode:AssetCacheMode):ServerSource {
		if (options.httpClient == null || options.cacheFileSystem == null)
			throw 'an HttpServer source needs httpClient and cacheFileSystem';
		var shipped:Array<ShippedTree> = [];
		if (mode == Manifest)
			for (later in options.sources.slice(i + 1))
				switch later {
					case FileSystem(fileSystem):
						shipped.push(new ShippedTree(fileSystem, options.manifestName));
					case _:
				}
		return new ServerSource(url, mode, mode == Manifest ? options.manifestName : null, shipped, options.httpClient, options.cacheFileSystem);
	}

	/** Loads a whole file.

		@param path  The file's path.
		@param loaded  Receives the file's bytes.
		@param failed  Optional. Receives why the file can't be loaded, because no source has it or the last source asked failed.
		@return  The abort: nothing is called after it. */
	public function load(path:String, loaded:Bytes->Void, ?failed:String->Void):Void->Void {
		var request = start(path, failed);
		function from(i:Int):Void {
			if (i == sources.length) {
				request.fail();
				return;
			}
			switch sources[i] {
				case Files(fileSystem):
					request.cancel = fileSystem.read(path, MAX_BYTES, bytes -> request.answer(() -> loaded(bytes)), () -> request.next(() -> from(i + 1)),
						message -> request.next(() -> from(i + 1), message));
				case Server(server):
					server.load(path, request, bytes -> request.answer(() -> loaded(bytes)), () -> from(i + 1), message -> {
						request.failure = message;
						from(i + 1);
					});
			}
		} from(0);
		return request.abort;
	}

	/** Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` takes.

		A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise it plays as it
		downloads, and the copy is kept.

		@param path  The file's path.
		@param located  Receives the source, and a release function to call once when the source is no longer read.
		@param failed  Optional. Receives why the file can't be found.
		@return  The abort: nothing is called after it. */
	public function locate(path:String, located:(source:StreamSource, release:Void->Void) -> Void, ?failed:String->Void):Void->Void {
		var request = start(path, failed);
		function from(i:Int):Void {
			if (i == sources.length) {
				request.fail();
				return;
			}
			switch sources[i] {
				case Files(fileSystem):
					fileSystem.locate(path, (location, release) -> {
						if (request.aborted)
							release();
						else
							request.answer(() -> located(Local(location), release));
					}, () -> request.next(() -> from(i + 1)),
						message -> request.next(() -> from(i + 1), message));
				case Server(server):
					server.locate(path, request, (source, release) -> request.answer(() -> located(source, release)), () -> from(i + 1), message -> {
						request.failure = message;
						from(i + 1);
					});
			}
		} from(0);
		return request.abort;
	}

	/** Empties `cacheFileSystem`, so each server's files are downloaded again.

		@param cleared  Optional. Called once the cache is empty.
		@param failed  Optional. Receives why the cache can't be emptied. When omitted, the failure is logged. */
	public function clearCache(?cleared:Void->Void, ?failed:String->Void):Void {
		for (source in sources)
			switch source {
				case Server(server):
					server.forget();
				case _:
			}
		if (cacheFileSystem == null) {
			if (cleared != null)
				cleared();
			return;
		}
		cacheFileSystem.deleteFiles(() -> if (cleared != null) cleared(), message -> {
			if (failed != null)
				failed(message);
			else
				Log.warn('the cache can\'t be emptied: $message', "assets");
		});
	}

	/** Aborts every load and locate in flight.

		Call it before disposing the HTTP client and file systems it was given. */
	public function dispose():Void {
		for (request in requests.copy())
			request.abort();
	}

	function start(path:String, failed:Null<String->Void>):Request {
		var request = new Request(path, failed, requests);
		requests.push(request);
		return request;
	}
}

/** Represents one of the sources, in the form Assets asks it. */
private enum Source {
	Files(fileSystem:IFileSystem);
	Server(server:ServerSource);
}

/** Represents a load or locate in flight.

	It holds the abort of the source being asked, and the last failure, which is reported when no source has the file. */
private class Request {
	/** Gets the path asked for. */
	public final path:String;

	/** Gets a value indicating whether it was aborted. Once aborted, nothing more is called. */
	public var aborted(default, null) = false;

	/** Gets or sets the abort of the step in flight. */
	public var cancel:Null<Void->Void> = null;

	/** Gets or sets the last failure, reported when no source has the file. */
	public var failure:Null<String> = null;

	final failed:Null<String->Void>;
	final requests:Array<Request>;

	/** Creates a request, which stays in requests while it is in flight. */
	public function new(path:String, failed:Null<String->Void>, requests:Array<Request>) {
		this.path = path;
		this.failed = failed;
		this.requests = requests;
	}

	/** Ends the request and calls f with the answer. Does nothing once aborted. */
	public function answer(f:Void->Void):Void {
		if (aborted)
			return;
		end();
		f();
	}

	/** Moves on to the next source by calling f, keeping the optional message as the last failure. Does nothing once aborted. */
	public function next(f:Void->Void, ?message:String):Void {
		if (aborted)
			return;
		if (message != null)
			failure = message;
		cancel = null;
		f();
	}

	/** Ends the request with its last failure, or with no source having the file when there was none. */
	public function fail():Void {
		if (aborted)
			return;
		end();
		var message = failure != null ? '$path: $failure' : '$path: no source has it';
		if (failed != null)
			failed(message);
		else
			Log.warn(message, "assets");
	}

	/** Aborts the request and the step in flight. Nothing more is called. */
	public function abort():Void {
		if (aborted)
			return;
		end();
		aborted = true;
		if (cancel != null)
			cancel();
	}

	function end():Void {
		requests.remove(this);
	}
}

/** Represents what a kept copy of a server's file is known by.

	It holds the copy's hash, the time until which it is fresh without asking, and its HTTP validators. */
private typedef Record = {
	hash:String,
	freshUntil:Float,
	?etag:String,
	?lastModified:String
}

/** Represents one directory's manifest.

	It holds the hash of each file in the directory, and of each subdirectory's manifest, by name. */
private typedef Manifest = {
	files:Map<String, String>,
	dirs:Map<String, String>
}

/** Specifies what a server source does for a path.

	It uses its kept copy, reads a shipped file in place, or downloads the file, asking about the copy when there is one. */
private enum Decision {
	UseCopy(record:Record, expected:Null<String>);
	UseShipped(fileSystem:IFileSystem, expected:String);
	Download(record:Null<Record>, expected:Null<String>);
}

/** Represents an `HttpServer` source.

	Its files are downloaded through the HTTP client. Each file is kept with a record in the cache file system, under a directory of the
	source's own. */
private class ServerSource {
	/** Seconds a response marked immutable stays fresh. */
	static inline final YEAR = 365 * 24 * 3600;

	final url:String;
	final mode:AssetCacheMode;
	final manifestPath:Null<String>;
	final shipped:Array<ShippedTree>;
	final http:IHttp;
	final cache:IFileSystem;
	final directory:String;
	// Off: this run's files, by path.
	var held = new Map<String, Bytes>();
	// Each directory's manifest this run, by directory ("" the root, then "levels/"): null for none; waiting while it's fetched.
	var manifests = new Map<String, Null<Manifest>>();
	var manifestsWaiting = new Map<String, Array<Null<Manifest>->Void>>();

	/** Creates the source for a server's URL. */
	public function new(url:String, mode:AssetCacheMode, manifestPath:Null<String>, shipped:Array<ShippedTree>, http:IHttp, cache:IFileSystem) {
		this.shipped = shipped;
		this.url = url == "" || StringTools.endsWith(url, "/") ? url : url + "/";
		this.mode = mode;
		this.manifestPath = manifestPath;
		this.http = http;
		this.cache = cache;
		directory = "server-" + nameOf(this.url);
	}

	/** Forgets what it holds in memory, when the cache is emptied. */
	public function forget():Void {
		held = new Map();
		manifests = new Map();
	}

	/** Loads a file whole, from the kept copy or a download, as the manifests and the cache mode decide. */
	public function load(path:String, request:Request, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
		if (!FilePath.isValid(path)) {
			refuse(request, failed);
			return;
		}
		if (mode == Off) {
			var bytes = held.get(path);
			if (bytes != null)
				later(request, () -> loaded(bytes));
			else
				download(path, request, null, null, true, (bytes, _) -> {
					held.set(path, bytes);
					loaded(bytes);
				}, missing, failed);
			return;
		}
		decide(path, request, decision -> switch decision {
			case UseCopy(record, expected): readCopy(path, request, record, expected, loaded, missing, failed);
			case UseShipped(fileSystem, expected):
				request.cancel = fileSystem.read(path, 1 << 30, bytes -> if (!request.aborted) loaded(bytes),
					() -> if (!request.aborted) download(path, request, null, expected, false, (bytes, _) -> loaded(bytes), missing, failed),
					_ -> if (!request.aborted) download(path, request, null, expected, false, (bytes, _) -> loaded(bytes), missing, failed));
			case Download(record, expected): download(path, request, record, expected, false, (bytes, _) -> loaded(bytes), missing, failed);
		});
	}

	/** Locates a file to play as it is read, from the kept copy or from a download as it arrives. */
	public function locate(path:String, request:Request, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
		if (!FilePath.isValid(path)) {
			refuse(request, failed);
			return;
		}
		if (mode == Off) {
			#if js
			later(request, () -> located(Remote(url + path), () -> {}));
			#else
			load(path, request, bytes -> located(Downloading(GrowingSource.of(bytes)), () -> {}), missing, failed);
			#end
			return;
		}
		decide(path, request, decision -> switch decision {
			case UseCopy(record,
				expected): locateCopy(path, request, located,
					() -> download(path, request, null, expected, false, (_, _) -> locateCopy(path, request, located, missing, failed), missing, failed),
					failed);
			case UseShipped(fileSystem, expected):
				fileSystem.locate(path, (location, release) -> {
					if (request.aborted)
						release();
					else
						located(Local(location), release);
				},
					() -> if (!request.aborted) download(path, request, null, expected, false, (_, _) -> locateCopy(path, request, located, missing, failed),
						missing, failed),
					message -> if (!request.aborted) failed(message));
			case Download(record, expected):
				download(path, request, record, expected, false, (_, growing) -> {
					// Natively a download of known length plays as it arrives; otherwise once it's kept.
					if (growing == null)
						locateCopy(path, request, located, missing, failed);
				}, missing, failed,
					#if js null #else growing -> located(Downloading(growing), () -> {}) #end);
		});
	}

	// Whether to use the kept copy or download: by the manifest when it lists the path; always asking about a copy its directory's
	// manifest leaves out, as changed or gone since it was kept; then by the cache mode.
	function decide(path:String, request:Request, decided:Decision->Void):Void {
		listedHash(path, request, (listed, leftOut) -> readRecord(path, request, record -> {
			if (listed != null) {
				if (record != null && record.hash == listed)
					decided(UseCopy(record, listed));
				else
					// Not kept, or kept at another hash: a file system after this source with the same file is read in place.
					shippedWith(path, listed, 0, request, fileSystem -> decided(fileSystem != null ? UseShipped(fileSystem, listed) : Download(null, listed)));
			} else if (record == null)
				decided(Download(null, null));
			else if (!leftOut && (mode == Trust || Date.now().getTime() / 1000 < record.freshUntil))
				decided(UseCopy(record, null));
			else
				decided(Download(record, null));
		}));
	}

	// The first file system after this source whose manifests give path the hash, from the i-th on; null for none.
	function shippedWith(path:String, hash:String, i:Int, request:Request, found:Null<IFileSystem>->Void):Void {
		if (i == shipped.length) {
			found(null);
			return;
		}
		var tree = shipped[i];
		tree.hashOf(path, listed -> {
			if (request.aborted)
				return;
			if (listed == hash)
				found(tree.fileSystem);
			else
				shippedWith(path, hash, i + 1, request, found);
		});
	}

	// The manifests' hash of path, walking down from the root's manifest one directory at a time, and whether its directory's manifest
	// leaves it out; null and false when there's no manifest for its directory.
	function listedHash(path:String, request:Request, found:(Null<String>, Bool) -> Void):Void {
		if (manifestPath == null) {
			found(null, false);
			return;
		}
		var names = path.split("/");
		function walk(depth:Int, level:String, hash:Null<String>) {
			manifestOf(level, hash, manifest -> {
				if (request.aborted)
					return;
				if (manifest == null)
					found(null, false);
				else if (depth == names.length - 1)
					found(manifest.files.get(names[depth]), !manifest.files.exists(names[depth]));
				else {
					var next = manifest.dirs.get(names[depth]);
					if (next == null)
						found(null, false);
					else
						walk(depth + 1, level + names[depth] + "/", next);
				}
			});
		}
		walk(0, "", null);
	}

	// A directory's manifest, once a run, kept as any file is. The root's is asked about each run (its copy's validators sent, its copy
	// used offline); a subdirectory's copy is used while its parent lists the same hash, and otherwise downloaded past HTTP caches. Its
	// loads belong to no one request, so aborting one leaves them running.
	function manifestOf(level:String, hash:Null<String>, got:Null<Manifest>->Void):Void {
		if (manifests.exists(level)) {
			got(manifests.get(level));
			return;
		}
		var waiting = manifestsWaiting.get(level);
		if (waiting != null) {
			waiting.push(got);
			return;
		}
		manifestsWaiting.set(level, [got]);
		function finish(bytes:Null<Bytes>) {
			var manifest = bytes == null ? null : parseManifest(bytes);
			manifests.set(level, manifest);
			var waiting = manifestsWaiting.get(level);
			manifestsWaiting.remove(level);
			for (f in waiting)
				f(manifest);
		}
		var path = level + manifestPath, own = new Request(path, null, []);
		readRecord(path, own, record -> {
			if (hash != null && record != null && record.hash == hash)
				readCopy(path, own, record, hash, bytes -> finish(bytes), () -> finish(null), _ -> finish(null));
			else
				download(path, own, hash == null ? record : null, hash, false, (bytes, _) -> finish(bytes), () -> {
					if (hash == null)
						Log.warn('no manifest at $url$path: its files are treated as Revalidate treats them', "assets");
					finish(null);
				}, _ -> finish(null));
		});
	}

	function readRecord(path:String, request:Request, read:Null<Record>->Void):Void {
		request.cancel = cache.read('$directory/records/$path', 1 << 16, bytes -> {
			if (request.aborted)
				return;
			var record:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
			read(record != null && Std.isOfType(record.hash, String) && Std.isOfType(record.freshUntil, Float) ? record : null);
		}, () -> if (!request.aborted) read(null), _ -> if (!request.aborted) read(null));
	}

	function readCopy(path:String, request:Request, record:Record, expected:Null<String>, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
		// A record without its copy downloads the file again, to the manifest's hash when one lists it.
		request.cancel = cache.read('$directory/files/$path', 1 << 30, bytes -> if (!request.aborted) loaded(bytes),
			() -> if (!request.aborted) download(path, request, null, expected, false, (bytes, _) -> loaded(bytes), missing, failed),
			_ -> if (!request.aborted) download(path, request, null, expected, false, (bytes, _) -> loaded(bytes), missing, failed));
	}

	function locateCopy(path:String, request:Request, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
		cache.locate('$directory/files/$path', (location, release) -> {
			if (request.aborted)
				release();
			else
				located(Local(location), release);
		}, () -> if (!request.aborted) missing(),
			message -> if (!request.aborted) failed(message));
	}

	/** Downloads a file and keeps it, asking the server about the record's copy when there is one.

		A 304 answer uses the copy. A 4xx answer removes the copy, and the file is missing from this source. No answer, because the
		machine is offline or the server answered 5xx, uses the copy when there is one. Natively, growing receives a download of known
		length to play as it arrives. got receives the bytes once they are kept, and the source they grew in, if any. */
	function download(path:String, request:Request, record:Null<Record>, expected:Null<String>, noCache:Bool, got:(Bytes, Null<GrowingSource>) -> Void,
			missing:Void->Void, failed:String->Void, ?growing:GrowingSource->Void):Void {
		var headers = new Map<String, String>();
		if (record != null) {
			if (record.etag != null)
				headers["If-None-Match"] = record.etag;
			if (record.lastModified != null)
				headers["If-Modified-Since"] = record.lastModified;
		}
		var status = 0, responseHeaders:Map<String, String> = null, buffer = new BytesBuffer(), source:GrowingSource = null;
		function fallBack(message:String) {
			if (record != null)
				readCopy(path, request, record, null, bytes -> got(bytes, null), missing, failed);
			else
				failed(message);
		}
		// A file a manifest lists is downloaded past HTTP caches, so a stale copy on the way can't come back.
		request.cancel = http.get(url + path, noCache || expected != null, headers, (code, received) -> {
			status = code;
			responseHeaders = received;
			if (growing != null && code >= 200 && code < 300 && expected == null) {
				var length = Std.parseInt(received.get("content-length"));
				if (length != null && length >= 0) {
					source = new GrowingSource(length);
					growing(source);
				}
			}
		}, part -> {
			if (source != null)
				source.append(part);
			buffer.add(part);
		}, () -> {
			if (request.aborted)
				return;
			if (status == 304 && record != null) {
				keepRecord(path, renewed(record, responseHeaders));
				readCopy(path, request, record, null, bytes -> got(bytes, null), missing, failed);
			} else if (status >= 200 && status < 300) {
				var bytes = buffer.getBytes();
				var hash = hashOf(bytes);
				if (expected != null && hash != expected) {
					failed('the download doesn\'t match the manifest');
					return;
				}
				if (!noCache)
					keep(path, bytes, recordOf(responseHeaders, hash));
				got(bytes, source);
			} else if (status >= 400 && status < 500) {
				if (record != null)
					forgetCopy(path);
				missing();
			} else
				fallBack('the server answered $status');
		}, message -> {
			if (source != null)
				source.fail(message);
			if (!request.aborted)
				fallBack(message);
		});
	}

	// Keeps a downloaded file and then its record, so a record is never there without its copy.
	function keep(path:String, bytes:Bytes, record:Record):Void
		cache.write('$directory/files/$path', bytes, () -> keepRecord(path, record), message -> Log.warn('$path can\'t be kept: $message', "assets"));

	function keepRecord(path:String, record:Record):Void
		cache.write('$directory/records/$path', Bytes.ofString(Json.stringify(record)), () -> {},
			message -> Log.warn('$path\'s record can\'t be kept: $message', "assets"));

	function forgetCopy(path:String):Void {
		cache.deleteFile('$directory/records/$path', () -> {}, _ -> {});
		cache.deleteFile('$directory/files/$path', () -> {}, _ -> {});
	}

	// Answers at the cache's next poll, never during the call: a read of a path no file has.
	// A path the file systems refuse is refused by a server too, at a later poll, so a name fails alike in a page and natively.
	function refuse(request:Request, failed:String->Void):Void
		later(request, () -> failed(FilePath.INVALID));

	function later(request:Request, f:Void->Void):Void
		cache.read('$directory/later', 0, _ -> if (!request.aborted) f(), () -> if (!request.aborted) f(), _ -> if (!request.aborted) f());

	static function recordOf(headers:Null<Map<String, String>>, hash:String):Record {
		var record:Record = {hash: hash, freshUntil: Date.now().getTime() / 1000 + freshSeconds(headers == null ? null : headers.get("cache-control"))};
		if (headers != null) {
			if (headers.exists("etag"))
				record.etag = headers.get("etag");
			if (headers.exists("last-modified"))
				record.lastModified = headers.get("last-modified");
		}
		return record;
	}

	static function renewed(record:Record, headers:Null<Map<String, String>>):Record {
		var fresh = recordOf(headers, record.hash);
		if (fresh.etag == null)
			fresh.etag = record.etag;
		if (fresh.lastModified == null)
			fresh.lastModified = record.lastModified;
		return fresh;
	}

	/** Returns how long a response stays fresh by its Cache-Control, in seconds.

		It is the max-age, or a year for immutable without a max-age. It is 0 for no-store, no-cache, or no Cache-Control. */
	static function freshSeconds(control:Null<String>):Float {
		if (control == null)
			return 0;
		var seconds = 0., immutable = false;
		for (part in control.toLowerCase().split(",")) {
			var directive = StringTools.trim(part);
			if (directive == "no-store" || directive == "no-cache")
				return 0;
			if (directive == "immutable")
				immutable = true;
			else if (StringTools.startsWith(directive, "max-age=")) {
				var value = Std.parseFloat(directive.substr(8));
				if (Math.isFinite(value) && value > 0)
					seconds = value;
			}
		}
		return seconds > 0 ? seconds : immutable ? YEAR : 0;
	}

	/** Returns the name of a URL's cache directory, as 16 hex digits.

		The digits are two 32-bit string hashes, FNV-1a and djb2, and are the same on every target. */
	public static function nameOf(url:String):String {
		var fnv = 0x811c9dc5, djb = 5381;
		for (i in 0...url.length) {
			var c = StringTools.fastCodeAt(url, i);
			fnv = ((fnv ^ c) << 24) + (fnv ^ c) * 403 | 0;
			djb = (djb << 5) + djb + c | 0;
		}
		return StringTools.hex(fnv, 8) + StringTools.hex(djb, 8);
	}

	/** Returns the hash of bytes in the form manifests write it, "sha256:" followed by 64 hex digits. */
	public static function hashOf(bytes:Bytes):String
		return "sha256:" + Sha256.make(bytes).toHex();

	/** Returns one directory's manifest, or null for anything that isn't one.

		A manifest is `{"manifest": 1, "files": {"name": "sha256:<hex>"}, "dirs": {"name": "sha256:<hex>"}}`. A subdirectory's hash is the
		hash of its own manifest. */
	public static function parseManifest(bytes:Bytes):Null<Manifest> {
		var value:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (value == null || value.manifest != 1)
			return null;
		return {files: hashes(value.files), dirs: hashes(value.dirs)};
	}

	static function hashes(value:Dynamic):Map<String, String> {
		var out = new Map<String, String>();
		if (value == null || Type.typeof(value) != TObject)
			return out;
		var entries:DynamicAccess<Dynamic> = value;
		for (name => hash in entries)
			if (name.indexOf("/") < 0 && Std.isOfType(hash, String) && ~/^sha256:[0-9a-f]{64}$/.match(hash))
				out.set(name, hash);
		return out;
	}
}

/** Represents a file system's manifests, as `AssetManifests` writes them beside a program's files.

	Each directory's manifest is read once a run, when first needed. It tells whether a file there is the one a server's manifest
	lists. */
private class ShippedTree {
	/** Gets the file system. */
	public final fileSystem:IFileSystem;

	final name:String;
	var manifests = new Map<String, Null<Manifest>>();
	var waiting = new Map<String, Array<Null<Manifest>->Void>>();

	/** Creates the tree over a file system whose manifests are named name. */
	public function new(fileSystem:IFileSystem, name:String) {
		this.fileSystem = fileSystem;
		this.name = name;
	}

	/** Finds the hash its manifests list for path, and passes it to found, or null when they list none. */
	public function hashOf(path:String, found:Null<String>->Void):Void {
		var names = path.split("/");
		function walk(depth:Int, level:String) {
			manifestOf(level, manifest -> {
				if (manifest == null)
					found(null);
				else if (depth == names.length - 1)
					found(manifest.files.get(names[depth]));
				else if (!manifest.dirs.exists(names[depth]))
					found(null);
				else
					walk(depth + 1, level + names[depth] + "/");
			});
		}
		walk(0, "");
	}

	function manifestOf(level:String, got:Null<Manifest>->Void):Void {
		if (manifests.exists(level)) {
			got(manifests.get(level));
			return;
		}
		var queue = waiting.get(level);
		if (queue != null) {
			queue.push(got);
			return;
		}
		waiting.set(level, [got]);
		function finish(manifest:Null<Manifest>) {
			manifests.set(level, manifest);
			var queue = waiting.get(level);
			waiting.remove(level);
			for (f in queue)
				f(manifest);
		}
		fileSystem.read(level + name, 1 << 26, bytes -> finish(ServerSource.parseManifest(bytes)), () -> finish(null), _ -> finish(null));
	}
}
