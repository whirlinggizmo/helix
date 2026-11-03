import haxe.Json;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import helix.platform.GrowingSource;
import helix.services.assets.AssetSource;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.ManifestCache;
import helix.services.assets.MemoryCache;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.assets.TrustCache;

/** Checks Assets over fake file systems and HTTP: sources asked in order; a server's file kept with its record (its byte count, a label
	only under a manifest), used fresh, asked about stale (a 304 using the copy), trusted, used offline, removed when gone (404 and 410);
	MemoryCache fetching once a run and writing nothing; a replacement deleting the old record, writing the bytes, then the record, so
	no failed write leaves a record beside bytes it doesn't describe; a copy whose size differs from its record, bytes without a record,
	a record without bytes and a record of an older shape all downloaded again; the manifests' tree deciding without asking, a listed
	download hashed before it is kept, a file a manifest leaves out always asked about, the copies of names a newer manifest drops
	deleted when it arrives; shipped files read in place; `deleteCopy`; located files; natively a server's stream downloaded in two
	parts, its last 64 KiB first; aborts and dispose. */
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
	static final made:Array<Assets> = [];

	static function pump():Void
		for (_ in 0...30) {
			http.poll();
			cache.poll();
			shipped.poll();
			for (assets in made)
				assets.poll();
		}

	static function make(sources:Array<AssetSource>):Assets {
		var assets = new Assets(sources);
		made.push(assets);
		return assets;
	}

	static function server(url:String, cache:helix.services.assets.AssetCache):ServerSource
		return new ServerSource(url, http, cache);

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

	// The URLs asked for since the request at before.
	static function askedSince(before:Int):Array<String>
		return [for (r in http.requests.slice(before)) r.url];

	// A kept copy's record, parsed; null when there's none.
	static function record(url:String, path:String):Dynamic {
		var bytes = cache.files.get('${dir(url)}/records/$path');
		return bytes == null ? null : Json.parse(bytes.toString());
	}

	static function kept(url:String, path:String):Bool
		return cache.files.exists('${dir(url)}/files/$path');

	static function main():Void {
		http = new FakeHttp();
		cache = new FakeFileSystem();
		shipped = new FakeFileSystem();
		var base = "https://example.com/game/";
		shipped.files.set("jump.wav", text("shipped jump"));
		http.routes.set(base + "music.ogg", {status: 200, headers: ["etag" => '"m1"', "cache-control" => "max-age=0"], body: text("music v1")});

		var assets = make([new FileSystemSource(shipped), server(base, new RevalidateCache(cache))]);
		var called = false;
		assets.load("jump.wav", _ -> called = true);
		check(!called, "never answered during the call");
		pump();
		check(called && http.requests.length == 0, "the first source that has it answers");

		check(load(assets, "music.ogg").bytes == "music v1" && http.requests.length == 1, "missing from the first: the server's");
		check(kept(base, "music.ogg") && record(base, "music.ogg") != null, "kept, with its record");
		var r = record(base, "music.ogg");
		check(r.size == 8 && r.label == null && r.etag == '"m1"', "the record: its byte count and validators, no label outside a manifest");

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

		var trusted = make([server(base, new TrustCache(cache))]);
		before = http.requests.length;
		check(load(trusted, "music.ogg").bytes == "music v1" && http.requests.length == before, "Trust: a stale copy used without asking");

		http.routes.remove(base + "music.ogg");
		var gone = load(assets, "music.ogg");
		check(gone.bytes == null && gone.failure.indexOf("no source has it") >= 0, "gone (404): no source has it");
		check(!kept(base, "music.ogg") && record(base, "music.ogg") == null, "and the copy and its record are removed");
		http.routes.set(base + "old.txt", {status: 200, body: text("old")});
		load(assets, "old.txt");
		http.routes.set(base + "old.txt", {status: 410});
		check(load(assets, "old.txt").bytes == null && !kept(base, "old.txt") && record(base, "old.txt") == null, "410: both removed too");

		memory();
		pairs(base);
		manifests();
		dropping();
		deleting(base);

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
		cache.files.set('${dir(base)}/files/fresh.txt', text("fresh, but longer"));
		before = http.requests.length;
		source = null;
		assets.locate("fresh.txt", (s, release) -> source = s);
		pump();
		check(askedSince(before).join(",") == base + "fresh.txt"
			&& local(source) != null
			&& cache.files.get('${dir(base)}/files/fresh.txt').toString() == "fresh",
			"a located copy whose size isn't its record's: downloaded again");

		http.routes.set(base + "song.ogg", {status: 200, body: text("streamed song")});
		source = null;
		assets.locate("song.ogg", (s, _) -> source = s);
		pump();
		check(source != null && kept(base, "song.ogg"), "a server's file located as it downloads, and kept");

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
		check(!emptied, "clearCache answers later");
		pump();
		check(emptied && !kept(base, "fresh.txt"), "clearCache empties the cache");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// MemoryCache: fetched once a run, past the HTTP caches, nothing written; a new run fetches again; a refused path answered at a poll.
	static function memory():Void {
		var other = "https://other.example/";
		http.routes.set(other + "dev.txt", {status: 200, body: text("dev")});
		var writes = cache.writes;
		var off = make([server(other, new MemoryCache())]);
		var before = http.requests.length;
		load(off, "dev.txt");
		check(http.requests.length == before + 1 && http.requests[before].noCache, "MemoryCache: downloaded past the HTTP caches");
		before = http.requests.length;
		var got = null;
		off.load("dev.txt", bytes -> got = bytes.toString());
		check(got == null, "MemoryCache: a held file not answered during the call");
		pump();
		check(got == "dev" && http.requests.length == before, "MemoryCache: fetched once a run");
		check(cache.writes == writes, "MemoryCache: nothing written");
		before = http.requests.length;
		check(load(make([server(other, new MemoryCache())]), "dev.txt").bytes == "dev" && http.requests.length == before + 1,
			"MemoryCache: the next run downloads again");
		http.routes.set(other + "my file.txt", {status: 200, body: text("spaced")});
		before = http.requests.length;
		var spaced = null;
		off.load("my file.txt", _ -> throw "a server was asked for a path the file systems refuse", m -> spaced = m);
		check(spaced == null, "a refused path: not answered during the call");
		pump();
		check(spaced != null && spaced.indexOf("Invalid file path") >= 0 && http.requests.length == before,
			"a path the file systems refuse: a server isn't asked for it either, and it fails as they do");
	}

	// The bytes and their record: the write order, a failed write at each step, a rollback, sizes, and missing halves.
	static function pairs(base:String):Void {
		var url = "https://pairs.example/";
		var assets = make([server(url, new RevalidateCache(cache))]);
		var d = dir(url);
		http.routes.set(url + "a.txt", {status: 200, headers: ["etag" => '"a1"'], body: text("a one")});
		var ops = cache.ops.length;
		load(assets, "a.txt");
		check(cache.ops.slice(ops).join(",") == 'write $d/files/a.txt,write $d/records/a.txt', "a first download: the bytes, then the record");
		http.routes.set(url + "a.txt", {status: 200, headers: ["etag" => '"a2"'], body: text("a two!")});
		ops = cache.ops.length;
		check(load(assets, "a.txt").bytes == "a two!", "a changed file: the new bytes");
		check(cache.ops.slice(ops).join(",") == 'delete $d/records/a.txt,write $d/files/a.txt,write $d/records/a.txt',
			"a replacement: the old record deleted, the bytes written, the record last");

		// The record's write fails: no record is left beside the new bytes, and the next load downloads.
		http.routes.set(url + "a.txt", {status: 200, headers: ["etag" => '"a3"'], body: text("a three")});
		cache.failWrite = path -> path == '$d/records/a.txt';
		load(assets, "a.txt");
		cache.failWrite = null;
		check(record(url, "a.txt") == null
			&& cache.files.get('$d/files/a.txt').toString() == "a three", "the record's write failed: no record");
		// The server rolls back to a2: the copy has no record, so it is downloaded, never taken for a2.
		http.routes.set(url + "a.txt", {
			status: 0,
			respond: headers -> headers.get("If-None-Match") == '"a2"' ? {status: 304} : {status: 200, headers: ["etag" => '"a2"'], body: text("a two!")}
		});
		var before = http.requests.length;
		check(load(assets, "a.txt").bytes == "a two!" && http.requests[before].headers.get("If-None-Match") == null,
			"rolled back: downloaded whole, the newer bytes never served as a2");

		// The bytes' write fails: the old record was deleted first, so the old bytes are downloaded again, not used under a new label.
		http.routes.set(url + "b.txt", {status: 200, headers: ["etag" => '"b1"'], body: text("b one")});
		load(assets, "b.txt");
		http.routes.set(url + "b.txt", {status: 200, headers: ["etag" => '"b2"'], body: text("b two")});
		cache.failWrite = path -> path == '$d/files/b.txt';
		check(load(assets, "b.txt").bytes == "b two", "a copy that can't be kept: the download still answers");
		cache.failWrite = null;
		check(record(url, "b.txt") == null
			&& cache.files.get('$d/files/b.txt').toString() == "b one", "the bytes' write failed: the old bytes, no record");
		before = http.requests.length;
		check(load(assets, "b.txt").bytes == "b two" && askedSince(before).length == 1, "bytes without a record: downloaded again");

		// A size that doesn't match, bytes without a record, a record without bytes, a record of an older shape.
		http.routes.set(url + "c.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("c")});
		load(assets, "c.txt");
		cache.files.set('$d/files/c.txt', text("c, truncated or foreign"));
		before = http.requests.length;
		check(load(assets, "c.txt").bytes == "c" && askedSince(before).length == 1, "a copy whose size isn't its record's: downloaded again");
		cache.files.remove('$d/records/c.txt');
		before = http.requests.length;
		check(load(assets, "c.txt").bytes == "c" && askedSince(before).length == 1, "bytes without a record: downloaded");
		cache.files.remove('$d/files/c.txt');
		before = http.requests.length;
		check(load(assets, "c.txt").bytes == "c" && askedSince(before).length == 1, "a record without bytes: downloaded");
		cache.files.set('$d/records/c.txt', text('{"hash": "${hash(text("c"))}", "freshUntil": 1e12, "etag": "\\"c0\\""}'));
		before = http.requests.length;
		check(load(assets, "c.txt").bytes == "c"
			&& askedSince(before).length == 1
			&& http.requests[before].headers.get("If-None-Match") == null,
			"a record of the older shape reads as none: downloaded whole");
		check(record(url, "c.txt").size == 1, "and kept in the new shape");
	}

	// The manifests: a run asking only for the root's, a listed download hashed before it is kept under its label, an unlisted one with
	// no label, a file a manifest leaves out asked about, shipped files read in place.
	static function manifests():Void {
		var site = "https://site.example/";
		var level = text("level one"),
			levels = text('{"manifest": 1, "files": {"1.json": "${hash(level)}"}}');
		var root = text('{"manifest": 1, "files": {}, "dirs": {"levels": "${hash(levels)}"}}');
		http.routes.set(site + "manifest.json", {status: 200, headers: ["etag" => '"r1"'], body: root});
		http.routes.set(site + "levels/manifest.json", {status: 200, body: levels});
		http.routes.set(site + "levels/1.json", {status: 200, body: level});
		var listed = make([server(site, new ManifestCache(cache))]);
		check(load(listed, "levels/1.json").bytes == "level one", "a file the manifests list: downloaded");
		check(record(site, "levels/1.json").label == hash(level), "kept under the hash its manifest lists");
		var nextRun = make([server(site, new ManifestCache(cache))]);
		var before = http.requests.length;
		check(load(nextRun, "levels/1.json").bytes == "level one", "the next run: the copy");
		var asked = askedSince(before);
		check(asked.length == 1 && asked[0] == site + "manifest.json", "only the root's manifest asked about: the rest known from its hashes");
		check(http.requests[http.requests.length - 1].headers.get("If-None-Match") == '"r1"', "the root asked about with its copy's ETag");

		http.routes.set(site + "levels/2.json", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("two")});
		load(nextRun, "levels/2.json");
		check(record(site, "levels/2.json").label == null, "a file no manifest lists: kept with no label");
		var third = make([server(site, new ManifestCache(cache))]);
		before = http.requests.length;
		load(third, "levels/2.json");
		check(askedSince(before).indexOf(site + "levels/2.json") >= 0, "a file its directory's manifest leaves out is asked about, however fresh");

		http.routes.set(site + "levels/1.json", {status: 200, body: text("tampered")});
		cache.files.remove('${dir(site)}/files/levels/1.json');
		var fourth = make([server(site, new ManifestCache(cache))]);
		var bad = load(fourth, "levels/1.json");
		check(bad.bytes == null && bad.failure != null, "a download that doesn't match its manifest fails");
		check(!kept(site, "levels/1.json") && record(site, "levels/1.json") == null, "and nothing of it is kept");

		var plain = "https://plain.example/";
		http.routes.set(plain + "a.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("a")});
		var unlisted = make([server(plain, new RevalidateCache(cache))]);
		before = http.requests.length;
		check(load(unlisted, "a.txt").bytes == "a"
			&& load(unlisted, "a.txt").bytes == "a"
			&& askedSince(before).join(",") == plain + "a.txt",
			"RevalidateCache looks for no manifest");
		var warned = [];
		helix.log.Log.listen((_, message) -> warned.push(message));
		var expecting = make([server(plain, new ManifestCache(cache))]);
		check(load(expecting, "a.txt").bytes == "a" && warned.join("").indexOf("no manifest") >= 0,
			"ManifestCache on a server without one: warned, and its files as RevalidateCache treats them");

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
		var patched = make([
			server(cdn, new ManifestCache(cache, {shipped: [ship]})),
			new FileSystemSource(ship)
		]);
		before = http.requests.length;
		function shippedLoad(assets:Assets, path:String):Null<String> {
			var got = null;
			assets.load(path, bytes -> got = bytes.toString());
			for (_ in 0...30) {
				http.poll();
				cache.poll();
				ship.poll();
				assets.poll();
			}
			return got;
		}
		check(shippedLoad(patched, "pack/a.png") == "same" && askedSince(before).indexOf(cdn + "pack/a.png") < 0,
			"a shipped file with the server's hash: read in place, not downloaded");
		check(!kept(cdn, "pack/a.png"), "and not copied");
		check(shippedLoad(patched, "pack/b.png") == "new b", "a shipped file the server has patched: downloaded");
		var unshipped = make([server(cdn, new ManifestCache(cache)), new FileSystemSource(ship)]);
		cache.files.remove('${dir(cdn)}/records/pack/a.png');
		before = http.requests.length;
		check(shippedLoad(unshipped, "pack/a.png") == "same" && askedSince(before).indexOf(cdn + "pack/a.png") >= 0,
			"a shipped tree not given to the cache: downloaded, as nothing says the shipped file is the same");
		http.offline = true;
		ship.files.set("pack/c.png", text("only shipped"));
		var offline = make([
			server("https://unreached.example/", new ManifestCache(cache, {shipped: [ship]})),
			new FileSystemSource(ship)
		]);
		check(shippedLoad(offline, "pack/c.png") == "only shipped", "offline with no copy: the shipped file");
		http.offline = false;
	}

	// A directory's manifest that stops listing names: their copies, and a dropped subdirectory's, deleted when it arrives.
	static function dropping():Void {
		var url = "https://drops.example/";
		var a = text("a"), b = text("b"), x = text("x"), y = text("y");
		var old = text('{"manifest": 1, "files": {"x.txt": "${hash(x)}"}, "dirs": {"deep": "${hash(text('{"manifest": 1, "files": {"y.txt": "${hash(y)}"}}'))}"}}');
		var deep = text('{"manifest": 1, "files": {"y.txt": "${hash(y)}"}}');
		var pack1 = text('{"manifest": 1, "files": {"a.txt": "${hash(a)}", "b.txt": "${hash(b)}"}, "dirs": {"old": "${hash(old)}"}}');
		var pack2 = text('{"manifest": 1, "files": {"a.txt": "${hash(a)}"}}');
		http.routes.set(url + "manifest.json", {status: 200, body: text('{"manifest": 1, "dirs": {"pack": "${hash(pack1)}"}}')});
		http.routes.set(url + "pack/manifest.json", {status: 200, body: pack1});
		http.routes.set(url + "pack/old/manifest.json", {status: 200, body: old});
		http.routes.set(url + "pack/old/deep/manifest.json", {status: 200, body: deep});
		http.routes.set(url + "pack/a.txt", {status: 200, body: a});
		http.routes.set(url + "pack/b.txt", {status: 200, body: b});
		http.routes.set(url + "pack/old/x.txt", {status: 200, body: x});
		http.routes.set(url + "pack/old/deep/y.txt", {status: 200, body: y});
		var first = make([server(url, new ManifestCache(cache))]);
		for (path in ["pack/a.txt", "pack/b.txt", "pack/old/x.txt", "pack/old/deep/y.txt"])
			load(first, path);
		check(kept(url, "pack/b.txt") && kept(url, "pack/old/x.txt") && kept(url, "pack/old/deep/y.txt"), "every listed file kept");
		http.routes.set(url + "manifest.json", {status: 200, body: text('{"manifest": 1, "dirs": {"pack": "${hash(pack2)}"}}')});
		http.routes.set(url + "pack/manifest.json", {status: 200, body: pack2});
		var next = make([server(url, new ManifestCache(cache))]);
		check(load(next, "pack/a.txt").bytes == "a", "the next run, its manifest changed: a kept name still read");
		check(kept(url, "pack/a.txt"), "a name it still lists: kept");
		check(!kept(url, "pack/b.txt") && record(url, "pack/b.txt") == null, "a name it dropped: its copy and record deleted as it arrived");
		check(!kept(url, "pack/old/x.txt") && !kept(url, "pack/old/deep/y.txt") && record(url, "pack/old/deep/y.txt") == null,
			"a subdirectory it dropped: every copy under it deleted");
	}

	// deleteCopy: every server's copy and record deleted, a file system's file left alone, answered later; the next load downloads.
	static function deleting(base:String):Void {
		var one = "https://one.example/", two = "https://two.example/";
		var files = new FakeFileSystem();
		files.files.set("d.txt", text("local d"));
		http.routes.set(one + "d.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("one d")});
		http.routes.set(two + "d.txt", {status: 200, headers: ["cache-control" => "max-age=3600"], body: text("two d")});
		var first = make([server(one, new RevalidateCache(cache))]);
		var second = make([server(two, new TrustCache(cache))]);
		load(first, "d.txt");
		load(second, "d.txt");
		var both = make([
			server(one, new RevalidateCache(cache)),
			server(two, new TrustCache(cache)),
			new FileSystemSource(files)
		]);
		var deleted = false;
		both.deleteCopy("d.txt", () -> deleted = true);
		check(!deleted, "deleteCopy: not answered during the call");
		for (_ in 0...10) {
			pump();
			files.poll();
		}
		check(deleted && !kept(one, "d.txt") && record(one, "d.txt") == null && !kept(two, "d.txt") && record(two, "d.txt") == null,
			"deleteCopy: every server's copy and record deleted");
		check(files.files.get("d.txt").toString() == "local d", "a file system's file left alone");
		var before = http.requests.length;
		check(load(first, "d.txt").bytes == "one d" && askedSince(before).length == 1, "the next load downloads it");
		var refused = null;
		both.deleteCopy("bad name.txt", () -> refused = "deleted", m -> refused = m);
		pump();
		check(refused != null && refused.indexOf("Invalid file path") >= 0, "a path the file systems refuse: refused");
	}

	// A file changed while the program runs: watched without reading, brought in again past every cache when told, by path or by the URL
	// it's served at, its new copy kept; a failure keeping the old and calling no watch; a stopped watch called no more.
	static function watching(base:String):Void {
		var files = new FakeFileSystem();
		files.files.set("shaders/glow.shader", text("glow v1"));
		var local = make([new FileSystemSource(files)]);
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
		var served = make([server(base, new RevalidateCache(cache))]);
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
		var inPage = make([server(page, new RevalidateCache(cache))]);
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
		var assets = make([server(base, new RevalidateCache(cache))]);
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
		check(cache.files.get('${dir(base)}/files/long.ogg').compare(body) == 0
			&& record(base, "long.ogg").size == body.length, "kept whole, with its record");
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
		check(source != null && source.failure != null && !kept(base, "moving.ogg"), "a file changed between its two parts: the download fails, nothing kept");

		var memory = make([server("https://memory.example/", new MemoryCache())]);
		http.routes.set("https://memory.example/m.ogg", {status: 200, body: body});
		source = null;
		memory.locate("m.ogg", (s, _) -> source = growing(s));
		pump();
		check(source != null && source.done && source.bytes.compare(body) == 0, "MemoryCache: a stream played as it downloads");

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
