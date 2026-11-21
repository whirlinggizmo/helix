package helix.services.assets;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.log.Log;
import helix.platform.GrowingSource;
import helix.platform.IHttp;
import helix.platform.StreamSource;

/** Downloads files from an HTTP server, under a URL, and stores copies in its cache, as the cache decides. It is never written to.

	A read of a download answers once its copy is written to the cache, so `Assets.listCache` lists it from then on. A copy the cache
	can't write is logged, and the read still answers with the bytes.

	The URL is the directory the paths are under, and the source's root. In a page it may be relative to the page, and "" is the page's
	own directory. A path is read by URL rules: a relative path is resolved against the URL, a URL under the source's URL is under the
	root, and so is a path from the server's root under the URL's path (`/assets/a.png` for a source at `https://example.com/assets/`). */
@:allow(helix.services.assets)
class ServerSource extends AssetSource {
	/** The bytes from a file's end a stream's download asks for first. */
	static inline final TAIL = 65536;

	/** Seconds a response marked immutable stays fresh. */
	static inline final YEAR = 365 * 24 * 3600;

	final url:String;
	// The URL, made absolute against the page's location when it is relative and the page has one.
	final base:String;
	// The base's scheme and host ("https://example.com"), or null when it is relative.
	final origin:Null<String>;
	// The names of the base's path from the server's root, joined by `/`.
	final under:String;
	final http:IHttp;
	final cache:AssetCache;
	// The directory of the cache's file system this server's copies are under.
	final directory:String;
	// The last bytes of each stream downloading in two parts, until its source is released.
	final tails = new Map<GrowingSource, Bytes>();

	/** Creates the source.

		@param url  The directory the paths are under.
		@param http  The HTTP client that downloads the files.
		@param cache  Decides whether a kept copy is current, and keeps copies: a `RevalidateCache`, `TrustCache`, `MemoryCache` or
			`ManifestCache`. */
	public function new(url:String, http:IHttp, cache:AssetCache) {
		super();
		this.url = url == "" || StringTools.endsWith(url, "/") ? url : url + "/";
		this.http = http;
		this.cache = cache;
		directory = "server-" + hashOf(this.url);
		#if js
		var page:Null<String> = js.Syntax.code("(typeof location == 'undefined' ? null : location.href)");
		base = page != null && this.url.indexOf("://") < 0 ? new js.html.URL(this.url == "" ? "./" : this.url, page).href : this.url;
		#else
		base = this.url;
		#end
		var parts = split(base);
		origin = parts.origin;
		under = AssetSource.follow(parts.origin == null && !StringTools.startsWith(base, "/") ? base : parts.path.substr(1));
	}

	function nameOf(path:String):Null<String> {
		if (path.indexOf("://") < 0 && !StringTools.startsWith(path, "/"))
			return AssetSource.follow(path);
		for (mark in ["?", "#"]) {
			var cut = path.indexOf(mark);
			if (cut >= 0)
				path = path.substr(0, cut);
		}
		var parts = split(path);
		if (parts.origin != null && origin != null && parts.origin.toLowerCase() != origin.toLowerCase())
			return null;
		var names = AssetSource.follow(parts.path.substr(1));
		if (names == null)
			return null;
		if (under == "" || names == under)
			return under == "" ? names : "";
		return StringTools.startsWith(names, under + "/") ? names.substr(under.length + 1) : null;
	}

	function locationOf(name:String):String
		return base + name;

	// A URL's scheme and host, and its path from the server's root ("/" at least); for a path that isn't a URL, no origin and the path.
	static function split(url:String):{origin:Null<String>, path:String} {
		var scheme = url.indexOf("://");
		if (scheme < 0)
			return {origin: null, path: url};
		var start = url.indexOf("/", scheme + 3);
		return start < 0 ? {origin: url, path: "/"} : {origin: url.substr(0, start), path: url.substr(start)};
	}

	function read(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
		cache.decide(this, path, request, decision -> switch decision {
			case Held(bytes): loaded(bytes);
			case UseCopy(record): readCopy(path, request, record, loaded, missing, failed);
			case UseShipped(fileSystem, label):
				request.cancel = fileSystem.read(path, AssetSource.MAX_BYTES, bytes -> if (!request.aborted) loaded(bytes),
					() -> if (!request.aborted) download(path, request, null, label, true, false, (bytes, _) -> loaded(bytes), missing, failed, null,
						OnceKeptOrLogged),
					_ -> if (!request.aborted) download(path, request, null, label, true, false, (bytes, _) -> loaded(bytes), missing, failed, null,
						OnceKeptOrLogged));
			case Download(record, label,
				replacing): download(path, request, record, label, replacing, false, (bytes, _) -> loaded(bytes), missing, failed, null, OnceKeptOrLogged);
		});
	}

	function refetch(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
		download(path, request, null, null, true, true, (bytes, _) -> loaded(bytes), missing, failed, null, OnceKeptOrLogged);
	}

	function locate(path:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
		// After a download: the kept copy located, or natively the bytes held in memory.
		function downloaded(bytes:Bytes, growing:Null<GrowingSource>)
			if (growing == null) {
				if (cache.keepsFiles)
					locateKept(path, request, bytes.length, located, missing, failed);
				else
					#if js
					located(Remote(url + path), () -> {});
					#else
					located(Downloading(GrowingSource.of(bytes)), () -> {});
					#end
			}
		cache.decide(this, path, request, decision -> switch decision {
			case Held(bytes):
				#if js
				located(Remote(url + path), () -> {});
				#else
				located(Downloading(GrowingSource.of(bytes)), () -> {});
				#end
			case UseCopy(record):
				cache.locateCopy(this, path, request, record, (location, release) -> located(Local(location), release),
					() -> download(path, request, null, record.label, false, false, downloaded, missing, failed, null, OnceKept), failed);
			case UseShipped(fileSystem, label):
				fileSystem.locate(path, (location, release) -> {
					if (request.aborted)
						release();
					else
						located(Local(location), release);
				},
					() -> if (!request.aborted) download(path, request, null, label, true, false, downloaded, missing, failed, null, OnceKept),
					message -> if (!request.aborted) failed(message));
			case Download(record, label, replacing):
				#if js
				// In a page a file plays once it's kept, or from its URL when copies are held in memory.
				if (!cache.keepsFiles)
					located(Remote(url + path), () -> {});
				else
					download(path, request, record, label, replacing, false, downloaded, missing, failed, null, OnceKept);
				#else
				// Natively a download of known length plays as it arrives.
				if (record == null && label == null)
					downloadTailFirst(path, request, replacing, downloaded, missing, failed,
						growing -> located(Downloading(growing), () -> tails.remove(growing)));
				else
					download(path, request, record, label, replacing, false, downloaded, missing, failed, growing -> located(Downloading(growing), () -> {}),
						OnceKept);
				#end
		});
	}

	override function tailOf(source:GrowingSource):Null<Bytes>
		return tails.get(source);

	override function clearCache(cleared:Void->Void, failed:String->Void):Void
		cache.clearCopies(this, cleared, failed);

	override function deleteCopy(path:String, deleted:Void->Void, failed:String->Void):Void
		cache.forget(this, path, deleted, failed);

	override function list(path:String, request:AssetRequest, listed:Array<String>->Void, failed:String->Void):Void {
		Log.info('${request.path}: files served from ${base == "" ? "./" : base} aren\'t listed', "assets");
		listed([]);
	}

	override function listCopies(path:String, request:AssetRequest, listed:Array<String>->Void, failed:String->Void):Void
		cache.listCopies(this, path, listed, failed);

	// The kept copy, read whole; one that isn't there whole is downloaded again, to its label when it has one.
	function readCopy(path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		cache.readCopy(this, path, request, record, loaded,
			() -> download(path, request, null, record.label, false, false, (bytes, _) -> loaded(bytes), missing, failed, null, OnceKeptOrLogged));

	// A copy just kept, located: one that isn't there whole now is missing, not downloaded again.
	function locateKept(path:String, request:AssetRequest, size:Int, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		cache.locateCopy(this, path, request, {size: size, freshUntil: 0}, (location, release) -> located(Local(location), release), missing, failed);

	/** Downloads a file and keeps it, asking the server about the record's copy when there is one.

		A 304 answer uses the copy. A 4xx answer removes the copy, and the file is missing from this source. No answer, because the
		machine is offline or the server answered 5xx, uses the copy when there is one. A label is the hash the bytes must have, and is
		kept in their record. replacing deletes the old record before the bytes are written. Natively, growing receives a download of known
		length to play as it arrives. got receives the bytes, and the source they grew in, if any, when answer says.
		noCache asks past the HTTP caches. */
	function download(path:String, request:AssetRequest, record:Null<CopyRecord>, label:Null<String>, replacing:Bool, noCache:Bool,
			got:(Bytes, Null<GrowingSource>) -> Void, missing:Void->Void, failed:String->Void, ?growing:GrowingSource->Void, answer = AtOnce):Void {
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
				readCopy(path, request, record, bytes -> got(bytes, null), missing, failed);
			else
				failed(message);
		}
		// A file a manifest lists is downloaded past HTTP caches, so a stale copy on the way can't come back.
		request.cancel = http.get(url + path, noCache || label != null || cache.pastHttpCaches, headers, (code, received) -> {
			status = code;
			responseHeaders = received;
			if (growing != null && code >= 200 && code < 300 && label == null) {
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
				var renewed = renewed(record, responseHeaders);
				cache.renew(this, path, renewed);
				readCopy(path, request, renewed, bytes -> got(bytes, null), missing, failed);
			} else if (status >= 200 && status < 300) {
				var bytes = buffer.getBytes();
				function store():Void
					keep(path, request, bytes, recordOf(responseHeaders, label, bytes.length), replacing, answer, () -> got(bytes, source), failed);
				if (label == null)
					store();
				else
					cache.verify(bytes, label, request, matches -> matches ? store() : failed('the download doesn\'t match the manifest'));
			} else if (status >= 400 && status < 500) {
				if (record != null || replacing)
					cache.forget(this, path, () -> {}, _ -> {});
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

	// Keeps a download and calls kept, when answer says. A copy that can't be kept is logged, or fails when answered OnceKept.
	function keep(path:String, request:AssetRequest, bytes:Bytes, record:CopyRecord, replacing:Bool, answer:Answer, kept:Void->Void, failed:String->Void):Void {
		if (answer == OnceKept)
			cache.keep(this, path, bytes, record, replacing, () -> if (!request.aborted) kept(), message -> if (!request.aborted) failed(message));
		else if (answer == OnceKeptOrLogged)
			cache.keep(this, path, bytes, record, replacing, () -> if (!request.aborted) kept(), message -> {
				Log.warn('$path can\'t be kept: $message', "assets");
				if (!request.aborted)
					kept();
			});
		else {
			cache.keep(this, path, bytes, record, replacing, () -> {}, message -> Log.warn('$path can\'t be kept: $message', "assets"));
			kept();
		}
	}

	/** Downloads a file not kept yet, to play as it arrives: its last 64 KiB first, then the rest, and keeps it whole.

		The rest is appended to the source growing receives, and the last bytes after it, so it reads as one download; meanwhile the
		last bytes are in `tails`, for the stream's length. No byte is downloaded twice. A server that answers the first request with the
		whole file (200, ignoring the range) is read as one download. The rest is asked for only while the file is unchanged (`If-Range`);
		a server that sends it otherwise fails the source. got receives the bytes once they are kept; missing and failed are download's. */
	function downloadTailFirst(path:String, request:AssetRequest, replacing:Bool, got:(Bytes, Null<GrowingSource>) -> Void, missing:Void->Void,
			failed:String->Void, growing:GrowingSource->Void):Void {
		var status = 0, responseHeaders:Map<String, String> = null, buffer = new BytesBuffer(), whole:GrowingSource = null;
		request.cancel = http.get(url + path, cache.pastHttpCaches, ["Range" => 'bytes=-$TAIL'], (code, received) -> {
			status = code;
			responseHeaders = received;
			if (code == 200) {
				var length = Std.parseInt(received.get("content-length"));
				if (length != null && length >= 0) {
					whole = new GrowingSource(length);
					growing(whole);
				}
			}
		}, part -> {
			if (whole != null)
				whole.append(part);
			buffer.add(part);
		}, () -> {
			if (request.aborted)
				return;
			var bytes = buffer.getBytes();
			if (status == 200)
				keep(path, request, bytes, recordOf(responseHeaders, null, bytes.length), replacing, whole == null ? OnceKept : AtOnce,
					() -> got(bytes, whole), failed);
			else if (status == 206) {
				var total = totalOf(responseHeaders.get("content-range"));
				if (total == null || bytes.length > total)
					// A range answer that doesn't state the file's size: the file is downloaded again, whole.
					download(path, request, null, null, replacing, false, got, missing, failed, growing, OnceKept);
				else if (bytes.length == total) {
					var source = GrowingSource.of(bytes);
					growing(source);
					keep(path, request, bytes, recordOf(responseHeaders, null, bytes.length), replacing, AtOnce, () -> got(bytes, source), failed);
				} else
					downloadRest(path, request, bytes, total, responseHeaders, replacing, got, growing);
			} else if (status == 416)
				download(path, request, null, null, replacing, false, got, missing, failed, growing, OnceKept);
			else if (status >= 400 && status < 500) {
				if (replacing)
					cache.forget(this, path, () -> {}, _ -> {});
				missing();
			} else
				failed('the server answered $status');
		}, message -> {
			if (whole != null)
				whole.fail(message);
			if (!request.aborted)
				failed(message);
		});
	}

	// The file's start, up to its tail, appended to a source of the whole file's size; the tail after it; then the whole kept.
	function downloadRest(path:String, request:AssetRequest, tail:Bytes, total:Int, tailHeaders:Map<String, String>, replacing:Bool,
			got:(Bytes, Null<GrowingSource>) -> Void, growing:GrowingSource->Void):Void {
		var source = new GrowingSource(total);
		tails.set(source, tail);
		growing(source);
		var headers = ["Range" => 'bytes=0-${total - tail.length - 1}'];
		var etag = tailHeaders.get("etag"),
			modified = tailHeaders.get("last-modified");
		if (etag != null && !StringTools.startsWith(etag, "W/"))
			headers["If-Range"] = etag;
		else if (modified != null)
			headers["If-Range"] = modified;
		var status = 0;
		request.cancel = http.get(url + path, cache.pastHttpCaches, headers, (code, _) -> {
			status = code;
			if (code != 206)
				source.fail(code == 200 ? 'the file changed on the server as it downloaded' : 'the server answered $code');
		}, part -> if (status == 206) source.append(part), () -> {
			if (status != 206 || request.aborted)
				return;
			if (source.received != total - tail.length) {
				source.fail('the server sent ${source.received} of ${total - tail.length} bytes');
				return;
			}
			source.append(tail);
			var bytes = source.bytes;
			keep(path, request, bytes, recordOf(tailHeaders, null, bytes.length), replacing, AtOnce, () -> got(bytes, source), _ -> {});
		}, message -> source.fail(message));
	}

	/** Returns a file's size from a range answer's `Content-Range` ("bytes 100-199/1000"), or null when it doesn't state it. */
	static function totalOf(range:Null<String>):Null<Int> {
		if (range == null)
			return null;
		var slash = range.lastIndexOf("/");
		return slash < 0 ? null : Std.parseInt(StringTools.trim(range.substr(slash + 1)));
	}

	static function recordOf(headers:Null<Map<String, String>>, label:Null<String>, size:Int):CopyRecord {
		var record:CopyRecord = {size: size, freshUntil: Date.now().getTime() / 1000 + freshSeconds(headers == null ? null : headers.get("cache-control"))};
		if (label != null)
			record.label = label;
		if (headers != null) {
			if (headers.exists("etag"))
				record.etag = headers.get("etag");
			if (headers.exists("last-modified"))
				record.lastModified = headers.get("last-modified");
		}
		return record;
	}

	static function renewed(record:CopyRecord, headers:Null<Map<String, String>>):CopyRecord {
		var fresh = recordOf(headers, record.label, record.size);
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
	static function hashOf(url:String):String {
		var fnv = 0x811c9dc5, djb = 5381;
		for (i in 0...url.length) {
			var c = StringTools.fastCodeAt(url, i);
			fnv = ((fnv ^ c) << 24) + (fnv ^ c) * 403 | 0;
			djb = (djb << 5) + djb + c | 0;
		}
		return StringTools.hex(fnv, 8) + StringTools.hex(djb, 8);
	}
}

/** Specifies when a download answers: at once, its copy written meanwhile; once its copy is written, failing when it can't be, for a
	stream located from the copy; or once its copy is written or logged as not written, for a read. */
private enum abstract Answer(Int) {
	var AtOnce;
	var OnceKept;
	var OnceKeptOrLogged;
}
