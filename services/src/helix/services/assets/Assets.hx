package helix.services.assets;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.log.Log;
import helix.platform.GrowingSource;
import helix.platform.IFileSystem;
import helix.platform.IHttp;
import helix.platform.StreamSource;

/** Provides files by path, from the places its sources name: a file system on this machine, or an HTTP server whose files it keeps
	copies of.

	It asks its sources in order, and the first that has the path answers: a file missing from one is looked for in the next. A game
	whose files never change lists its file system alone; one patched from a server lists the server first and its shipped files after,
	and a shipped file the server's manifest lists at the same hash is read in place, so only what changed is downloaded
	(`AssetManifests` writes the manifests); a page, whose files are on the server that served it, lists `HttpServer("")`. A path is plain names joined by `/`, as `IFileSystem`'s. Each call answers once, on the main
	thread, in the platform's `poll` that finished it, never during the call; the failure's lambda may be left out, and the failure is
	then logged with the path. Its downloads and copies finish in the polls of the HTTP client and file systems it was given, which
	the program polls each frame; Assets has no `poll` of its own.

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
	``` */
class Assets {
	/** The largest file read whole from a file system. */
	static inline final MAX_BYTES = 1 << 30;

	final sources:Array<Source> = [];
	final requests:Array<Request> = [];
	final cacheFileSystem:Null<IFileSystem>;

	/** Creates the assets over their sources.

		@param options  The sources, and the HTTP client and file system an `HttpServer` source needs.
		@throws String  When a source is an `HttpServer` and `httpClient` or `cacheFileSystem` is null. */
	public function new(options:AssetsOptions) {
		cacheFileSystem = options.cacheFileSystem;
		var name = options.manifestName == "" ? null : options.manifestName;
		for (i in 0...options.sources.length)
			sources.push(switch options.sources[i] {
				case FileSystem(fileSystem): Files(fileSystem);
				case HttpServer(url, cacheMode):
					if (options.httpClient == null || options.cacheFileSystem == null)
						throw 'an HttpServer source needs httpClient and cacheFileSystem';
					// The file systems after it, whose manifests may show a file is already here.
					var shipped = [];
					if (name != null)
						for (later in options.sources.slice(i + 1))
							switch later {
								case FileSystem(fileSystem): shipped.push(new ShippedTree(fileSystem, name));
								case _:
							}
					Server(new ServerSource(url, cacheMode == null ? Revalidate : cacheMode, name, shipped, options.httpClient, options.cacheFileSystem));
			});
	}

	/** Loads a whole file.

		@param path  The file's path.
		@param loaded  Receives its bytes.
		@param failed  Optional. Receives why it can't be had: no source has it, or the last one asked failed.
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

	/** Finds a file for playing as it's read, without loading it whole, as `IAudio.openStream` takes it.

		A file system's file is located where it is; a server's file is its kept copy when there is one, and otherwise is played as it
		downloads while the copy is kept.
		@param path  The file's path.
		@param located  Receives the source, and the function that lets it go, called once when it's no longer read.
		@param failed  Optional. Receives why it can't be had.
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

	/** Empties `cacheFileSystem`, so each server's file is downloaded again.

		@param cleared  Optional. Called once it's empty.
		@param failed  Optional. Receives why it can't be emptied. */
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
		cacheFileSystem.clearFiles(() -> if (cleared != null) cleared(), message -> {
			if (failed != null)
				failed(message);
			else
				Log.warn('the cache can\'t be emptied: $message', "assets");
		});
	}

	/** Aborts every load and locate in flight; before the HTTP client and file systems it was given are disposed. */
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

/** One of the sources, as Assets asks it. */
private enum Source {
	Files(fileSystem:IFileSystem);
	Server(server:ServerSource);
}

/** A load or locate in flight: the source being asked, its abort, and the last failure, reported when no source has the file. */
private class Request {
	/** Gets the path asked for. */
	public final path:String;

	/** Gets a value indicating whether it was aborted, so nothing more is called. */
	public var aborted(default, null) = false;

	/** Gets or sets the abort of the step in flight. */
	public var cancel:Null<Void->Void> = null;

	/** Gets or sets the last failure, reported when no source has the file. */
	public var failure:Null<String> = null;

	final failed:Null<String->Void>;
	final requests:Array<Request>;

	/** Creates a request, kept in requests while it's in flight. */
	public function new(path:String, failed:Null<String->Void>, requests:Array<Request>) {
		this.path = path;
		this.failed = failed;
		this.requests = requests;
	}

	/** Calls f with the answer, unless aborted, and ends the request. */
	public function answer(f:Void->Void):Void {
		if (aborted)
			return;
		end();
		f();
	}

	/** Moves on to the next source, keeping message as the last failure. */
	public function next(f:Void->Void, ?message:String):Void {
		if (aborted)
			return;
		if (message != null)
			failure = message;
		cancel = null;
		f();
	}

	/** Ends the request with its last failure, or none of the sources having the file. */
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

	/** Stops it: nothing more is called. */
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

/** What a kept copy of a server's file is known by: its hash, until when it's fresh without asking, and its validators. */
private typedef Record = {
	hash:String,
	freshUntil:Float,
	?etag:String,
	?lastModified:String
}

/** One directory's manifest: the hash of each file in it, and of each subdirectory's manifest, by name. */
private typedef Manifest = {
	files:Map<String, String>,
	dirs:Map<String, String>
}

/** What a server source does for a path: use its kept copy, or download it (asking about the copy when there is one). */
private enum Decision {
	UseCopy(record:Record, expected:Null<String>);
	UseShipped(fileSystem:IFileSystem, expected:String);
	Download(record:Null<Record>, expected:Null<String>);
}

/** An `HttpServer` source: its files downloaded through the HTTP client and kept, with a record each, in the cache file system under a
	directory of its own. */
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
		directory = "server-" + Md5.encode(this.url).substr(0, 16);
	}

	/** Forgets what it holds in memory, as the cache is emptied. */
	public function forget():Void {
		held = new Map();
		manifests = new Map();
	}

	/** Loads a file whole: the kept copy or a download, by the manifests and the cache mode. */
	public function load(path:String, request:Request, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
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

	/** Locates a file to play as it's read: the kept copy, or a download as it arrives. */
	public function locate(path:String, request:Request, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
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
				download(path, own, hash == null ? record : null, hash, false, (bytes, _) -> finish(bytes), () -> finish(null), _ -> finish(null));
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

	/** Downloads a file, asking about record's copy when there is one, and keeps it; a 304 uses the copy, a 4xx removes it and the file is
		missing here, and no answer (offline, a 5xx) uses the copy when there is one. growing, natively, receives a download of known length
		to play as it arrives; got receives the bytes once they're kept, and the source it grew in, if any. */
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
		cache.remove('$directory/records/$path', () -> {}, _ -> {});
		cache.remove('$directory/files/$path', () -> {}, _ -> {});
	}

	// Answers at the cache's next poll, never during the call: a read of a path no file has.
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

	/** How long a response stays fresh by its Cache-Control, in seconds: its max-age, a year for immutable without one, none for no-store,
		no-cache or nothing said; as HeliX had it. */
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

	/** Returns bytes' hash as manifests write it: "sha256:" and 64 hex digits. */
	public static function hashOf(bytes:Bytes):String
		return "sha256:" + Sha256.make(bytes).toHex();

	/** One directory's manifest, or null for anything that isn't one: `{"manifest": 1, "files": {"name": "sha256:<hex>"}, "dirs": {"name":
		"sha256:<hex>"}}`, a subdirectory's hash being its own manifest's, as HeliX's manifests are. */
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

/** A file system's manifests, as `AssetManifests` writes them beside a program's files: read once a run, a directory at a time, to say
	whether a file there is the one a server's manifest lists. */
private class ShippedTree {
	/** Gets the file system. */
	public final fileSystem:IFileSystem;

	final name:String;
	var manifests = new Map<String, Null<Manifest>>();
	var waiting = new Map<String, Array<Null<Manifest>->Void>>();

	/** Creates the tree over a file system, its manifests named name. */
	public function new(fileSystem:IFileSystem, name:String) {
		this.fileSystem = fileSystem;
		this.name = name;
	}

	/** Gives the hash its manifests list for path, or null when they don't. */
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
