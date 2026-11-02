import haxe.crypto.Sha256;
import haxe.io.Bytes;
import helix.platform.GrowingSource;
import helix.services.assets.Assets;

/** Checks Assets over fake file systems and HTTP: sources asked in order; a server's file kept with its record, used fresh, asked about
	stale (a 304 using the copy), trusted, used offline, removed when gone; Off fetching once a run and keeping nothing; the manifests'
	tree deciding without asking; a file a manifest leaves out always asked about; located files; natively a server's stream downloaded
	in two parts, its last 64 KiB first; aborts and dispose. */
@:access(helix.services.assets.Assets)
class AssetsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var http:FakeHttp;
	static var cache:FakeFileSystem;
	static var shipped:FakeFileSystem;

	static function pump():Void
		for (_ in 0...30) {
			http.poll();
			cache.poll();
			shipped.poll();
		}

	static function text(s:String):Bytes
		return Bytes.ofString(s);

	static function hash(bytes:Bytes):String
		return "sha256:" + Sha256.make(bytes).toHex();

	static function load(assets:Assets, path:String):{bytes:Null<String>, failure:Null<String>} {
		var result = {bytes: null, failure: null};
		assets.load(path, bytes -> result.bytes = bytes.toString(), message -> result.failure = message);
		pump();
		return result;
	}

	static function main():Void {
		http = new FakeHttp();
		cache = new FakeFileSystem();
		shipped = new FakeFileSystem();
		var base = "https://example.com/game/";
		shipped.files.set("jump.wav", text("shipped jump"));
		http.routes.set(base + "music.ogg", {status: 200, headers: ["etag" => '"m1"', "cache-control" => "max-age=0"], body: text("music v1")});

		check(try {
			new Assets({sources: [HttpServer(base)]});
			false;
		} catch (_:String) true, "a server source with no HTTP client or cache: refused");

		var assets = new Assets({
			sources: [FileSystem(shipped), HttpServer(base)],
			httpClient: http,
			cacheFileSystem: cache,
			manifestName: ""
		});
		var called = false;
		assets.load("jump.wav", _ -> called = true);
		check(!called, "never answered during the call");
		pump();
		check(called && http.requests.length == 0, "the first source that has it answers");

		check(load(assets, "music.ogg").bytes == "music v1" && http.requests.length == 1, "missing from the first: the server's");
		check(cache.files.exists('${dir(base)}/files/music.ogg')
			&& cache.files.exists('${dir(base)}/records/music.ogg'), "kept, with its record");

		http.routes.set(base + "music.ogg", {status: 0, respond: headers -> headers.get("If-None-Match") == '"m1"' ? {status: 304} : null});
		check(load(assets, "music.ogg").bytes == "music v1"
			&& http.requests.length == 2, "stale: asked about with its ETag; 304, the copy");

		http.routes.set(base + "fresh.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("fresh")});
		load(assets, "fresh.txt");
		var before = http.requests.length;
		check(load(assets, "fresh.txt").bytes == "fresh" && http.requests.length == before, "fresh: the copy, no request");

		http.offline = true;
		check(load(assets, "music.ogg").bytes == "music v1", "offline: the copy");
		var lost = load(assets, "nowhere.txt");
		check(lost.bytes == null && lost.failure != null, "offline with no copy: failed");
		http.offline = false;

		var trusted = new Assets({
			sources: [HttpServer(base, Trust)],
			httpClient: http,
			cacheFileSystem: cache,
			manifestName: ""
		});
		before = http.requests.length;
		check(load(trusted, "music.ogg").bytes == "music v1" && http.requests.length == before, "Trust: a stale copy used without asking");

		http.routes.remove(base + "music.ogg");
		var gone = load(assets, "music.ogg");
		check(gone.bytes == null && gone.failure.indexOf("no source has it") >= 0, "gone: no source has it");
		check(!cache.files.exists('${dir(base)}/files/music.ogg'), "and the copy is removed");

		var other = "https://other.example/";
		http.routes.set(other + "dev.txt", {status: 200, body: text("dev")});
		var off = new Assets({
			sources: [HttpServer(other, Off)],
			httpClient: http,
			cacheFileSystem: cache,
			manifestName: ""
		});
		load(off, "dev.txt");
		before = http.requests.length;
		check(load(off, "dev.txt").bytes == "dev" && http.requests.length == before, "Off: fetched once a run");
		check(!cache.files.exists('${dir(other)}/files/dev.txt'), "Off: nothing kept");
		http.routes.set(other + "my file.txt", {status: 200, body: text("spaced")});
		before = http.requests.length;
		var spaced = null;
		off.load("my file.txt", _ -> throw "a server was asked for a path the file systems refuse", m -> spaced = m);
		check(spaced == null, "a refused path: not answered during the call");
		pump();
		check(spaced != null && spaced.indexOf("Invalid file path") >= 0 && http.requests.length == before,
			"a path the file systems refuse: a server isn't asked for it either, and it fails as they do");

		var site = "https://site.example/";
		var level = text("level one"),
			levels = text('{"manifest": 1, "files": {"1.json": "${hash(level)}"}}');
		var root = text('{"manifest": 1, "files": {}, "dirs": {"levels": "${hash(levels)}"}}');
		http.routes.set(site + "manifest.json", {status: 200, headers: ["etag" => '"r1"'], body: root});
		http.routes.set(site + "levels/manifest.json", {status: 200, body: levels});
		http.routes.set(site + "levels/1.json", {status: 200, body: level});
		var listed = new Assets({sources: [HttpServer(site, Manifest)], httpClient: http, cacheFileSystem: cache});
		check(load(listed, "levels/1.json").bytes == "level one", "a file the manifests list: downloaded");
		var nextRun = new Assets({sources: [HttpServer(site, Manifest)], httpClient: http, cacheFileSystem: cache});
		before = http.requests.length;
		check(load(nextRun, "levels/1.json").bytes == "level one", "the next run: the copy");
		var asked = [for (r in http.requests.slice(before)) r.url];
		check(asked.length == 1 && asked[0] == site + "manifest.json", "only the root's manifest asked about: the rest known from its hashes");
		check(http.requests[http.requests.length - 1].headers.get("If-None-Match") == '"r1"', "the root asked about with its copy's ETag");

		http.routes.set(site + "levels/2.json", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("two")});
		load(nextRun, "levels/2.json");
		var third = new Assets({sources: [HttpServer(site, Manifest)], httpClient: http, cacheFileSystem: cache});
		before = http.requests.length;
		load(third, "levels/2.json");
		check([for (r in http.requests.slice(before)) r.url].indexOf(site + "levels/2.json") >= 0,
			"a file its directory's manifest leaves out is asked about, however fresh");

		http.routes.set(site + "levels/1.json", {status: 200, body: text("tampered")});
		cache.files.remove('${dir(site)}/files/levels/1.json');
		var fourth = new Assets({sources: [HttpServer(site, Manifest)], httpClient: http, cacheFileSystem: cache});
		var bad = load(fourth, "levels/1.json");
		check(bad.bytes == null && bad.failure != null, "a download that doesn't match its manifest fails");

		var plain = "https://plain.example/";
		http.routes.set(plain + "a.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("a")});
		var unlisted = new Assets({sources: [HttpServer(plain)], httpClient: http, cacheFileSystem: cache});
		before = http.requests.length;
		check(load(unlisted, "a.txt").bytes == "a"
			&& load(unlisted, "a.txt").bytes == "a"
			&& [for (r in http.requests.slice(before)) r.url].join(",") == plain + "a.txt",
			"Revalidate looks for no manifest");
		var warned = [];
		helix.log.Log.listen((_, message) -> warned.push(message));
		var expecting = new Assets({sources: [HttpServer(plain, Manifest)], httpClient: http, cacheFileSystem: cache});
		check(load(expecting, "a.txt").bytes == "a" && warned.join("").indexOf("no manifest") >= 0,
			"Manifest on a server without one: warned, and its files as Revalidate treats them");

		// Shipped files under the server's manifests: the same file read in place, a patched one downloaded.
		var cdn = "https://cdn.example/";
		var same = text("same"), oldB = text("old b"), newB = text("new b");
		var ship = new FakeFileSystem();
		ship.files.set("pack/a.png", same);
		ship.files.set("pack/b.png", oldB);
		var shipPack = text('{"manifest": 1, "files": {"a.png": "${hash(same)}", "b.png": "${hash(oldB)}"}}');
		ship.files.set("pack/manifest.json", shipPack);
		ship.files.set("manifest.json", text('{"manifest": 1, "dirs": {"pack": "${hash(shipPack)}"}}'));
		var cdnPack = text('{"manifest": 1, "files": {"a.png": "${hash(same)}", "b.png": "${hash(newB)}"}}');
		http.routes.set(cdn + "manifest.json", {status: 200, body: text('{"manifest": 1, "dirs": {"pack": "${hash(cdnPack)}"}}')});
		http.routes.set(cdn + "pack/manifest.json", {status: 200, body: cdnPack});
		http.routes.set(cdn + "pack/a.png", {status: 200, body: same});
		http.routes.set(cdn + "pack/b.png", {status: 200, body: newB});
		var patched = new Assets({sources: [HttpServer(cdn, Manifest), FileSystem(ship)], httpClient: http, cacheFileSystem: cache});
		before = http.requests.length;
		var aRead = {bytes: null, failure: null};
		patched.load("pack/a.png", bytes -> aRead.bytes = bytes.toString(), m -> aRead.failure = m);
		for (_ in 0...30) {
			http.poll();
			cache.poll();
			ship.poll();
		}
		check(aRead.bytes == "same" && [for (r in http.requests.slice(before)) r.url].indexOf(cdn + "pack/a.png") < 0,
			"a shipped file with the server's hash: read in place, not downloaded");
		var bRead = {bytes: null, failure: null};
		patched.load("pack/b.png", bytes -> bRead.bytes = bytes.toString(), m -> bRead.failure = m);
		for (_ in 0...30) {
			http.poll();
			cache.poll();
			ship.poll();
		}
		check(bRead.bytes == "new b", "a shipped file the server has patched: downloaded");
		http.offline = true;
		ship.files.set("pack/c.png", text("only shipped"));
		var offline = new Assets({sources: [HttpServer("https://unreached.example/", Manifest), FileSystem(ship)], httpClient: http, cacheFileSystem: cache});
		var cRead = {bytes: null, failure: null};
		offline.load("pack/c.png", bytes -> cRead.bytes = bytes.toString(), m -> cRead.failure = m);
		for (_ in 0...30) {
			http.poll();
			cache.poll();
			ship.poll();
		}
		check(cRead.bytes == "only shipped", "offline with no copy: the shipped file");
		http.offline = false;

		var source = null;
		assets.locate("jump.wav", (s, release) -> source = s);
		pump();
		check(local(source) == "fake:jump.wav", "a file system's file located where it is");
		source = null;
		assets.locate("fresh.txt", (s, release) -> {
			source = s;
			release();
		});
		pump();
		check(local(source) != null
			&& local(source).indexOf("fresh.txt") >= 0
			&& cache.held == 0, "a server's kept copy located, and released");

		http.routes.set(base + "song.ogg", {status: 200, body: text("streamed song")});
		source = null;
		assets.locate("song.ogg", (s, _) -> source = s);
		pump();
		check(source != null && cache.files.exists('${dir(base)}/files/song.ogg'), "a server's file located as it downloads, and kept");

		#if !js
		ranged(base);
		#end

		var answered = false;
		var abort = assets.load("jump.wav", _ -> answered = true);
		abort();
		pump();
		check(!answered, "aborted: nothing called");
		assets.load("fresh.txt", _ -> answered = true, _ -> answered = true);
		assets.dispose();
		pump();
		check(!answered, "disposed: nothing called");

		watching(base);
		var emptied = false;
		assets.clearCache(() -> emptied = true);
		pump();
		check(emptied && !cache.files.exists('${dir(base)}/files/fresh.txt'), "clearCache empties the cache");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A file changed while the program runs: watched without reading, brought in again past every cache when told, by path or by the URL
	// it's served at, its new copy kept; a failure keeping the old and calling no watch; a stopped watch called no more.
	static function watching(base:String):Void {
		var files = new FakeFileSystem();
		files.files.set("shaders/glow.shader", text("glow v1"));
		var local = new Assets({sources: [FileSystem(files)]});
		var seen:Array<String> = [];
		var stop = local.watch("shaders/glow.shader", bytes -> seen.push(bytes.toString()));
		files.poll();
		check(seen.length == 0 && files.held == 0, "a watch reads nothing");
		files.files.set("shaders/glow.shader", text("glow v2"));
		local.notifyChanged("shaders/glow.shader");
		check(seen.length == 0, "nothing called during notifyChanged");
		for (_ in 0...5)
			files.poll();
		check(seen.join(",") == "glow v2", "a file system's file read again, the watch given its bytes");
		local.notifyChanged("shaders/other.shader");
		for (_ in 0...5)
			files.poll();
		check(seen.length == 1, "another path's change reaches no watch");
		stop();
		local.notifyChanged("shaders/glow.shader");
		for (_ in 0...5)
			files.poll();
		check(seen.length == 1, "a stopped watch is called no more");

		http.routes.set(base + "shaders/lit.shader", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("lit v1")});
		var served = new Assets({
			sources: [HttpServer(base)],
			httpClient: http,
			cacheFileSystem: cache,
			manifestName: ""
		});
		check(load(served, "shaders/lit.shader").bytes == "lit v1", "kept fresh for an hour");
		var got:Array<String> = [];
		served.watch("shaders/lit.shader", bytes -> got.push(bytes.toString()));
		http.routes.set(base + "shaders/lit.shader", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("lit v2")});
		var before = http.requests.length;
		served.notifyChanged("shaders/lit.shader");
		pump();
		check(got.join(",") == "lit v2"
			&& http.requests.length == before + 1
			&& http.requests[before].noCache
			&& http.requests[before].headers.get("If-None-Match") == null,
			"a server's file asked again past the HTTP caches and the fresh copy");
		before = http.requests.length;
		check(load(served, "shaders/lit.shader").bytes == "lit v2"
			&& http.requests.length == before, "the new copy kept in the old's place");
		http.offline = true;
		served.notifyChanged("shaders/lit.shader");
		pump();
		http.offline = false;
		check(got.length == 1
			&& load(served, "shaders/lit.shader").bytes == "lit v2", "a failed fetch keeps the old copy and calls no watch");
		http.routes.set(base + "shaders/lit.shader", {status: 200, body: text("lit v3")});
		served.notifyUrlChanged(base + "shaders/lit.shader?v=3");
		pump();
		check(got.join(",") == "lit v2,lit v3", "an absolute URL the server serves maps to its path");
		served.notifyUrlChanged("https://elsewhere.example/shaders/lit.shader");
		pump();
		check(got.length == 2, "a URL no source serves is skipped");

		var page = "assets/";
		http.routes.set(page + "shaders/quad.shader", {status: 200, body: text("quad v2")});
		var inPage = new Assets({
			sources: [HttpServer(page)],
			httpClient: http,
			cacheFileSystem: cache,
			manifestName: ""
		});
		var quads:Array<String> = [];
		inPage.watch("shaders/quad.shader", bytes -> quads.push(bytes.toString()));
		inPage.notifyUrlChanged("/assets/shaders/quad.shader");
		pump();
		inPage.notifyUrlChanged("http://localhost:8080/assets/shaders/quad.shader");
		pump();
		check(quads.join(",") == "quad v2,quad v2", "a source relative to the page: the URL from the server's root, or absolute, maps to its path");
		inPage.notifyUrlChanged("/other/shaders/quad.shader");
		pump();
		check(quads.length == 2, "a URL outside the source's skipped");
	}

	#if !js
	// A stream not kept yet, natively: its last 64 KiB downloaded first, then the rest, no byte twice, kept whole; a server that ignores
	// the range sends it whole; a small file comes whole in the first answer; a file changed between the two fails the download.
	static function ranged(base:String):Void {
		var assets = new Assets({sources: [HttpServer(base)], httpClient: http, cacheFileSystem: cache});
		var body = Bytes.alloc(100000);
		for (i in 0...body.length)
			body.set(i, i * 7 & 255);
		http.routes.set(base + "long.ogg", {status: 200, headers: ["last-modified" => "Fri, 30 Oct 2026 10:00:00 GMT"], body: body});
		var source:GrowingSource = null, released:Void->Void = null;
		var before = http.requests.length, sent = http.bytesSent;
		assets.locate("long.ogg", (s, release) -> {
			source = growing(s);
			released = release;
		});
		for (_ in 0...3)
			cache.poll();
		http.poll();
		check(source != null && source.total == body.length && source.received == 0, "located once its end has arrived, the whole file's size");
		var tail = assets.tailOf(source);
		check(tail != null
			&& tail.length == 65536
			&& tail.compare(body.sub(body.length - 65536, 65536)) == 0, "its last 64 KiB held for its length");
		http.poll();
		check(source.done && source.bytes.compare(body) == 0, "the rest appended, and its end after it: one download");
		var asked = http.requests.slice(before);
		check(asked.length == 2
			&& asked[0].headers.get("Range") == "bytes=-65536"
			&& asked[1].headers.get("Range") == 'bytes=0-${body.length - 65537}'
			&& asked[1].headers.get("If-Range") == "Fri, 30 Oct 2026 10:00:00 GMT",
			"two ranges asked for, the second while the file is unchanged");
		check(http.bytesSent - sent == body.length, "no byte downloaded twice");
		pump();
		check(cache.files.get('${dir(base)}/files/long.ogg').compare(body) == 0 && cache.files.exists('${dir(base)}/records/long.ogg'),
			"kept whole, with its record");
		released();
		check(assets.tailOf(source) == null, "released: its end let go");

		http.routes.set(base + "whole.ogg", {status: 200, body: body, ignoresRange: true});
		before = http.requests.length;
		source = null;
		assets.locate("whole.ogg", (s, _) -> source = growing(s));
		pump();
		check(http.requests.length == before + 1 && source.done && source.bytes.compare(body) == 0 && assets.tailOf(source) == null,
			"a server ignoring the range: the whole file at once, as one download");
		check(cache.files.get('${dir(base)}/files/whole.ogg').compare(body) == 0, "and kept");

		http.routes.set(base + "short.ogg", {status: 200, body: text("short")});
		before = http.requests.length;
		source = null;
		assets.locate("short.ogg", (s, _) -> source = growing(s));
		pump();
		check(http.requests.length == before + 1 && source.done && source.bytes.toString() == "short", "a file under 64 KiB: whole in the first answer");

		var version = 1;
		http.routes.set(base + "moving.ogg", {
			status: 0,
			respond: _ -> {
				var r:FakeHttp.FakeResponse = {status: 200, headers: ["etag" => '"v$version"'], body: body};
				version++;
				r;
			}
		});
		source = null;
		assets.locate("moving.ogg", (s, _) -> source = growing(s));
		pump();
		check(source != null && source.failure != null && !cache.files.exists('${dir(base)}/files/moving.ogg'),
			"a file changed between its two parts: the download fails, nothing kept");

		var missing = null;
		assets.locate("absent.ogg", (_, _) -> {}, m -> missing = m);
		pump();
		check(missing != null && missing.indexOf("no source has it") >= 0, "a file the server doesn't have: missing");
	}

	static function growing(source:helix.platform.StreamSource):Null<GrowingSource>
		return switch source {
			case Downloading(s): s;
			case _: null;
		}
	#end

	static function local(source:Null<helix.platform.StreamSource>):Null<String>
		return switch source {
			case Local(location): location;
			case _: null;
		}

	// The cache directory's name for a URL, as Assets makes it: FNV-1a and djb2, 32 bits each.
	static function nameOf(url:String):String {
		var fnv = 0x811c9dc5, djb = 5381;
		for (i in 0...url.length) {
			var c = StringTools.fastCodeAt(url, i);
			fnv = ((fnv ^ c) << 24) + (fnv ^ c) * 403 | 0;
			djb = (djb << 5) + djb + c | 0;
		}
		return StringTools.hex(fnv, 8) + StringTools.hex(djb, 8);
	}

	static function dir(url:String):String
		return "server-" + nameOf(url);
}
