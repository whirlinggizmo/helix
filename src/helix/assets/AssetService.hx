package helix.assets;

import helix.core.WorkQueue;
import helix.assets.IAssets;
import helix.assets.Storage;
import helix.assets.Fetch;
import helix.assets.AssetManifest;

/** How obtain treats a cached copy: Revalidate uses a fresh one and asks about a stale one; Ask always asks; Force downloads past it. */
private enum Obtain {
	Revalidate;
	Ask;
	Force;
}

/** One load's state: its request, the step it waits on (cancelled with it), how it ends and how it reports progress. */
private class Attempt {
	/** The load's request. */
	public final request:Request;

	/** The step the load waits on, cancelled with the request. */
	public var child:Null<IRequest> = null;

	/** Ends the load. */
	public final finish:AssetResult->Void;

	/** Reports a phase of it. */
	public final report:(String, Int, Null<Int>) -> Void;

	/** A load of request, ending with finish and reporting through report. */
	public function new(request:Request, finish:AssetResult->Void, report:(String, Int, Null<Int>) -> Void) {
		this.request = request;
		this.finish = finish;
		this.report = report;
	}

	/** Whether the load has ended (or was cancelled). */
	public function settled():Bool
		return request.isSettled();
}

/** Asset identity/cache policy stays shared. No target conditionals. */
class AssetService implements IAssets {
	var fetcher:Fetch;
	var cache:Storage;
	var packaged:Storage;
	var base:Null<String>;
	var queue = new WorkQueue();
	var live = true;
	var requests:Array<IRequest> = [];
	var subscribers:Map<String, Array<IReloadable>> = [];
	var manifest:Null<String>;
	// Each directory's manifest this run, by its path ("" the root's; null when there's none), and the loads waiting for one.
	var manifests:Map<String, Null<AssetManifest>> = [];
	var waiting:Map<String, Array<Null<AssetManifest>->Void>> = [];
	var cacheMode = AssetCacheMode.Revalidate;
	// With the cache Off, this run's downloads, by key: nothing persists, but a file loads once a run.
	var session:Map<String, haxe.io.Bytes> = [];

	/** Loads through fetcher when base (the URL put before each path) is set, or else from the read-only packaged store, keeping each asset in cache under a key of base and path. It polls and shuts down all three. */
	public function new(fetcher:Fetch, cache:Storage, packaged:Storage, base:Null<String>) {
		this.fetcher = fetcher;
		this.cache = cache;
		this.packaged = packaged;
		this.base = base;
	}

	public function load(path:String, complete:AssetResult->Void):Void
		ensure(path, complete);

	public function ensure(path:String, complete:AssetResult->Void, ?progress:AssetProgress->Void, ?options:EnsureOptions):IRequest {
		var source = options != null && options.source != null ? options.source : path,
			force = options != null && options.forceFetch == true;
		var attempt:Attempt = null, request:Request = null;
		request = new Request(() -> {
			if (attempt.child != null)
				attempt.child.cancel();
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		attempt = new Attempt(request, result -> if (request.finish()) {
			requests.remove(request);
			queue.add(() -> complete(result));
		},
			(phase, received, total) -> if (progress != null && !request.isSettled()) progress({phase: phase, receivedBytes: received, totalBytes: total}));
		requests.push(request);
		queue.add(() -> {
			if (request.isSettled())
				return;
			if (!live || !AssetPath.isValid(path)) {
				attempt.finish(Failed("Invalid asset path or closed service"));
				return;
			}
			attempt.report("locating", 0, null);
			if (base == null) {
				attempt.child = packaged.read(source, result -> {
					if (request.isSettled())
						return;
					switch result {
						// The packaged files are already on this machine: read in place, not copied into the cache, unless they're
						// another path's bytes (options.source), which have to be found under the path asked for.
						case Stored(bytes):
							if (source != path) store(path, bytes, [], AssetManifest.hash(bytes), attempt, attempt.finish); else {
								attempt.report("ready", bytes.length, bytes.length);
								attempt.finish(Loaded(bytes));
							}
						case Missing: attempt.finish(Failed("Missing asset: " + source));
						case Failed(message): attempt.finish(Failed(message));
						case Cancelled: attempt.finish(Cancelled);
					}
				});
				return;
			}
			var url = source.indexOf("://") > 0 ? source : base + source;
			if (force)
				obtain(path, url, null, Force, attempt, attempt.finish);
			else if (source != path)
				obtain(path, url, null, Revalidate, attempt, attempt.finish);
			else
				hashOf(path,
					(expected, unlisted) -> if (!request.isSettled()) obtain(path, url, expected, unlisted ? Ask : Revalidate, attempt, attempt.finish));
		});
		return request;
	}

	// The cache key of path's bytes, and of their record.
	function key(path:String):String
		return haxe.crypto.Sha256.encode((base == null ? "packaged" : base) + "\n" + path);

	function recordKey(path:String):String
		return key(path) + ".meta";

	static function now():Float
		return Date.now().getTime() / 1000;

	/** path's bytes from url, kept in the cache. expected is a manifest's hash for them, or null when none lists them: a copy with that hash is
		used with no request, and anything else is downloaded past HTTP caches and kept only if it has that hash. Unlisted, a fresh copy is used
		with no request, and a stale one is asked about (its ETag and Last-Modified sent): 304 keeps it, 200 replaces it, 4xx deletes it, and no
		answer (offline, a 5xx) uses it. Ask always asks (a manifest's root once a run, and a file its directory's manifest leaves out); Force
		downloads past every cache. */
	function obtain(path:String, url:String, expected:Null<String>, mode:Obtain, attempt:Attempt, done:AssetResult->Void):Void {
		if (mode == Force || cacheMode == Off) {
			if (mode != Force && session.exists(key(path)))
				copy(path, attempt, done, () -> {});
			else
				download(path, url, expected, null, mode, attempt, done);
			return;
		}
		attempt.child = cache.read(recordKey(path), result -> {
			if (attempt.settled())
				return;
			var record = switch result {
				case Stored(bytes): CacheRecords.parse(bytes);
				case Cancelled:
					done(Cancelled);
					return;
				case _: null;
			}
			// A copy brought from elsewhere (ensure's source) is asked about there, not at the path, where the host has nothing.
			var from = url, how = mode;
			if (record != null && record.source != null && expected == null && url == base + path) {
				from = record.source;
				how = Revalidate;
			}
			function fetch()
				download(path, from, expected, expected == null ? record : null, how, attempt, done);
			if (expected != null ? record != null && record.hash == expected : how == Revalidate
				&& (cacheMode == Trust || record != null && now() < record.freshUntil))
				copy(path, attempt, done, fetch);
			else
				fetch();
		});
	}

	// Downloads path from url, conditionally when record is the copy's; the answer decides (obtain).
	function download(path:String, url:String, expected:Null<String>, record:Null<CacheRecord>, mode:Obtain, attempt:Attempt, done:AssetResult->Void):Void {
		var headers:Map<String, String> = [];
		if (record != null && record.etag != null)
			headers["If-None-Match"] = record.etag;
		if (record != null && record.lastModified != null)
			headers["If-Modified-Since"] = record.lastModified;
		// No answer: the copy, unless the download had to go past it.
		function unanswered(message:String)
			if (mode == Force)
				done(Failed(message));
			else
				copy(path, attempt, done, () -> done(Failed(message)));
		attempt.child = fetcher.fetch({url: url, noCache: expected != null || mode != Revalidate || record != null, headers: headers}, result -> {
			if (attempt.settled())
				return;
			switch result {
				case Response(value):
					if (value.status == 304 && record != null) copy(path, attempt, done, () -> download(path, url, expected, null, Force, attempt, done),
						() -> {
							var renewed = CacheRecords.of(value.headers, record.hash, now());
							cache.write(recordKey(path), CacheRecords.encode({
								etag: renewed.etag != null ? renewed.etag : record.etag,
								lastModified: renewed.lastModified != null ? renewed.lastModified : record.lastModified,
								freshUntil: renewed.freshUntil,
								hash: record.hash,
								source: record.source
							}), _ -> {});
						}); else if (value.status >= 200 && value.status < 300) {
						var hash = AssetManifest.hash(value.bytes);
						if (expected != null && hash != expected)
							done(Failed('Asset does not match its manifest (a deploy still arriving?): $path'));
						else
							store(path, value.bytes, value.headers, hash, attempt, done, url == base + path ? null : url);
						} else if (value.status >= 400 && value.status < 500) {
						// The host says it's gone: so is the copy.
						if (cacheMode == Off)
							session.remove(key(path));
						else {
							cache.remove(key(path), _ -> {});
							cache.remove(recordKey(path), _ -> {});
						}
						done(Failed('Asset HTTP ${value.status}: $path'));
					} else unanswered('Asset HTTP ${value.status}: $path');
				case Failed(message): unanswered(message);
				case Cancelled: done(Cancelled);
			}
		}, value -> attempt.report("downloading", value.receivedBytes, value.totalBytes));
	}

	// The cached copy of path (this run's, with the cache Off), or missing() when there's none; kept() once it's read.
	function copy(path:String, attempt:Attempt, done:AssetResult->Void, missing:Void->Void, ?kept:Void->Void):Void {
		if (cacheMode == Off) {
			var bytes = session[key(path)];
			if (bytes == null)
				missing();
			else {
				attempt.report("ready", bytes.length, bytes.length);
				done(Loaded(bytes));
			}
			return;
		}
		attempt.child = cache.read(key(path), result -> {
			if (attempt.settled())
				return;
			switch result {
				case Stored(bytes):
					if (kept != null)
						kept();
					attempt.report("ready", bytes.length, bytes.length);
					done(Loaded(bytes));
				case Missing: missing();
				case Failed(message): done(Failed(message));
				case Cancelled: done(Cancelled);
			}
		});
	}

	// Keeps bytes (of hash) as path's copy, then their record from the response's headers (and source, the URL they came from when not the
	// path's); with the cache Off, for this run alone.
	function store(path:String, bytes:haxe.io.Bytes, headers:Map<String, String>, hash:String, attempt:Attempt, done:AssetResult->Void, ?source:String):Void {
		attempt.report("storing", bytes.length, bytes.length);
		if (cacheMode == Off) {
			session[key(path)] = bytes;
			attempt.report("ready", bytes.length, bytes.length);
			done(Loaded(bytes));
			return;
		}
		attempt.child = cache.write(key(path), bytes, result -> {
			if (attempt.settled())
				return;
			switch result {
				case Written:
					attempt.child = cache.write(recordKey(path), CacheRecords.encode(CacheRecords.of(headers, hash, now(), source)), _ -> {
						if (attempt.settled())
							return;
						attempt.report("ready", bytes.length, bytes.length);
						done(Loaded(bytes));
					});
				case Failed(message): done(Failed(message));
				case Cancelled: done(Cancelled);
			}
		});
	}

	/** The manifest's hash for path, or null when no manifest lists it (none is set, the host has none, or it doesn't name the file); and
		whether its directory's manifest leaves it out, which says the file has changed or gone since it was kept: such a copy is always asked
		about, however fresh. */
	function hashOf(path:String, done:(Null<String>, Bool) -> Void):Void {
		if (manifest == null || base == null) {
			done(null, false);
			return;
		}
		var parts = path.split("/"), name = parts.pop();
		directory(parts, found -> done(found == null ? null : found.files[name], found != null && !found.files.exists(name)));
	}

	/** The manifest of the directory of parts (the root's for none), loaded once a run: the root asked about each run, a directory's fetched only
		when its hash in its parent's differs from the copy's. */
	function directory(parts:Array<String>, done:Null<AssetManifest>->Void):Void {
		var dir = parts.join("/");
		if (manifests.exists(dir)) {
			done(manifests[dir]);
			return;
		}
		if (waiting.exists(dir)) {
			waiting[dir].push(done);
			return;
		}
		waiting[dir] = [done];
		var root = haxe.io.Path.directory(manifest),
			name = haxe.io.Path.withoutDirectory(manifest);
		var file = haxe.io.Path.join([root, dir, name]);
		function settle(found:Null<AssetManifest>) {
			manifests[dir] = found;
			var callers = waiting[dir];
			waiting.remove(dir);
			for (caller in callers)
				caller(found);
		}
		function loaded(result:AssetResult)
			settle(switch result {
				case Loaded(bytes): AssetManifest.parse(bytes);
				case _: null;
			});
		// The manifests' own loads belong to no one request: cancelling one ensure leaves them running.
		var own = new Attempt(new Request(() -> {}), loaded, (_, _, _) -> {});
		if (parts.length == 0)
			obtain(file, base + file, null, Ask, own, loaded);
		else
			directory(parts.slice(0, parts.length - 1), parent -> {
				var expected = parent == null ? null : parent.dirs[parts[parts.length - 1]];
				if (expected == null)
					settle(null);
				else
					obtain(file, base + file, expected, Revalidate, own, loaded);
			});
	}

	public function getManifest():Null<String>
		return manifest;

	public function setManifest(path:Null<String>):Bool {
		if (path != null && !AssetPath.isValid(path))
			return false;
		manifest = path;
		manifests.clear();
		return true;
	}

	public function getHost():Null<String>
		return base;

	public function setHost(host:Null<String>):Bool {
		if (host == "")
			return false;
		base = host == null || StringTools.endsWith(host, "/") ? host : host + "/";
		return true;
	}

	public function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):IRequest {
		var root = StringTools.endsWith(host, "/") ? host : host + "/";
		return fetcher.fetch({url: root + probePath, timeoutSeconds: timeoutSeconds, noCache: true}, result -> complete(switch result {
			case Response(value): value.status >= 200 && value.status < 300;
			case _: false;
		}));
	}

	public function getCacheMode():AssetCacheMode
		return cacheMode;

	public function setCacheMode(mode:AssetCacheMode):Void
		cacheMode = mode;

	public function clearCache(complete:StorageWriteResult->Void):IRequest {
		session.clear();
		manifests.clear();
		return cache.clear(complete);
	}

	public function streamSource(path:String, complete:AssetSourceResult->Void):IRequest {
		var child:IRequest = null, request:Request = null;
		function finish(result:AssetSourceResult) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			} else
				switch result {
					case Located(Stored(value)):
						value.release();
					case _:
				}
		}
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		requests.push(request);
		function local(result:StorageSourceResult) {
			if (request.isSettled()) {
				switch result {
					case Local(value):
						value.release();
					case _:
				}
				return;
			}
			switch result {
				case Local(value):
					finish(Located(Stored(value)));
				case Failed(message):
					finish(Failed(message));
				case Cancelled:
					finish(Cancelled);
				case Missing:
					if (base != null)
						finish(Located(Remote(base + path)));
					else
						child = packaged.source(path, result -> switch result {
							case Local(value): finish(Located(Stored(value)));
							case Missing: finish(Failed("Missing streamed asset: " + path));
							case Failed(message): finish(Failed(message));
							case Cancelled: finish(Cancelled);
						});
			}
		}
		queue.add(() -> {
			if (request.isSettled())
				return;
			if (!live || !AssetPath.isValid(path)) {
				finish(Failed("Invalid asset path or closed service"));
				return;
			}
			if (base == null) {
				child = cache.source(key(path), local);
				return;
			}
			// A downloaded copy is streamed only while it's current (obtain's rules, without asking the host): the manifest's hash, else fresh.
			// Otherwise the host's URL, where the platform's own HTTP cache decides.
			hashOf(path, (expected, unlisted) -> {
				if (request.isSettled())
					return;
				if (cacheMode == Off) {
					finish(Located(Remote(base + path)));
					return;
				}
				child = cache.read(recordKey(path), result -> {
					if (request.isSettled())
						return;
					var record = switch result {
						case Stored(bytes): CacheRecords.parse(bytes);
						case _: null;
					}
					// A copy brought from elsewhere streams from the cache while fresh, else from where it came: the host has nothing at the path.
					if (record != null && record.source != null && expected == null) {
						if (cacheMode == Trust || now() < record.freshUntil)
							child = cache.source(key(path), local);
						else
							finish(Located(Remote(record.source)));
						return;
					}
					if (expected != null ? record != null && record.hash == expected : !unlisted
						&& (cacheMode == Trust || record != null && now() < record.freshUntil))
						child = cache.source(key(path), local);
					else
						finish(Located(Remote(base + path)));
				});
			});
		});
		return request;
	}

	public function subscribe(path:String, target:IReloadable):Void {
		var list = subscribers[path];
		if (list == null)
			subscribers[path] = list = [];
		if (list.indexOf(target) < 0)
			list.push(target);
	}

	public function unsubscribe(path:String, target:IReloadable):Void {
		var list = subscribers[path];
		if (list != null) {
			list.remove(target);
			if (list.length == 0)
				subscribers.remove(path);
		}
	}

	/** A file changed: load it again past every cache, keep the new copy, and tell the path's subscribers. A failure keeps what they have. */
	public function changed(path:String):Void {
		if (!live || !AssetPath.isValid(path) || !subscribers.exists(path))
			return;
		// A reload that fails says so (development): the subscribers keep what they have.
		function done(ok:Bool, message:String)
			if (!ok)
				trace('Asset reload failed: $path: $message');
		function tell(bytes:haxe.io.Bytes) {
			var list = subscribers[path];
			if (list != null)
				for (target in list.copy())
					try
						target.reloaded(path, bytes)
					catch (error:Dynamic) {
						done(false, Std.string(error));
						return;
					}
			done(true, "");
		}
		// The new copy kept as a download is (this run's alone with the cache Off), then the subscribers told.
		function deliver(bytes:haxe.io.Bytes, headers:Map<String, String>)
			if (cacheMode == Off) {
				session[key(path)] = bytes;
				tell(bytes);
			} else
				cache.write(key(path), bytes, result -> switch result {
					case Written:
						cache.write(recordKey(path), CacheRecords.encode(CacheRecords.of(headers, AssetManifest.hash(bytes), now())), _ -> {});
						tell(bytes);
					case Failed(message): done(false, message);
					case Cancelled:
				});
		if (base != null)
			fetcher.fetch({url: base + path, noCache: true}, result -> switch result {
				case Response(value): if (value.status >= 200 && value.status < 300) deliver(value.bytes,
						value.headers); else done(false, 'Asset HTTP ' + value.status);
				case Failed(message): done(false, message);
				case Cancelled:
			});
		else
			packaged.read(path, result -> switch result {
				case Stored(bytes): deliver(bytes, []);
				case Missing: done(false, "Missing asset");
				case Failed(message): done(false, message);
				case Cancelled:
			});
	}

	public function isBusy():Bool
		return requests.length > 0 || !queue.isEmpty();

	/** Polls the fetcher, cache and packaged store, then runs queued work and completions within the work budget. Call once per frame on the host thread. */
	public function poll():Void {
		fetcher.poll();
		cache.poll();
		packaged.poll();
		queue.poll();
	}

	/** Cancels every pending request (each completes Cancelled), shuts down the fetcher, cache and packaged store, and runs queued completions. Later requests fail. */
	public function shutdown():Void {
		live = false;
		for (request in requests.copy())
			request.cancel();
		fetcher.shutdown();
		cache.shutdown();
		packaged.shutdown();
		queue.poll();
	}
}
