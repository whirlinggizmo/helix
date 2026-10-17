import haxe.io.Bytes;
import helix.assets.AssetManifest;
import helix.assets.AssetService;
import helix.assets.FetchService;
import helix.assets.IAssets;
import helix.assets.IHttp;
import helix.assets.IStore;
import helix.assets.StorageService;

/** A host in memory: files by path, each with its headers, answering as a server does (304 to a matching If-None-Match), or not at all while
	offline. It counts the requests for each path and keeps the headers each was sent with. */
private class Host implements IHttp {
	public var files:Map<String, {body:Bytes, headers:Map<String, String>}> = [];
	public var requests:Map<String, Int> = [];
	public var sent:Map<String, Map<String, String>> = [];
	public var offline = false;
	public var status:Null<Int> = null;

	var pending:Array<Void->Void> = [];

	public function new() {}

	/** Serves body at path with an ETag of its hash, and Cache-Control when given. */
	public function put(path:String, body:String, ?control:String):Void {
		var bytes = Bytes.ofString(body),
			headers:Map<String, String> = ["etag" => '"' + AssetManifest.hash(bytes).substr(7, 16) + '"'];
		if (control != null)
			headers["cache-control"] = control;
		files[path] = {body: bytes, headers: headers};
	}

	public function count(path:String):Int
		return requests.exists(path) ? requests[path] : 0;

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(Int, Map<String, String>) -> Void, body:Bytes->Void,
			end:Null<String>->Void):Void->Void {
		var path = url.substr("http://host/".length);
		requests[path] = count(path) + 1;
		sent[path] = headers;
		pending.push(() -> {
			if (offline) {
				end("offline");
				return;
			}
			var file = files[path];
			if (status != null)
				head(status, []);
			else if (file == null)
				head(404, []);
			else if (headers["If-None-Match"] == file.headers["etag"])
				head(304, file.headers);
			else {
				head(200, file.headers);
				body(file.body);
			}
			end(null);
		});
		return () -> {};
	}

	public function poll():Void {
		var now = pending;
		pending = [];
		for (f in now)
			f();
	}

	public function shutdown():Void {}
}

/** A store in memory, kept across services as a browser's IndexedDB is across visits. */
private class Memory implements IStore {
	public var files:Map<String, Bytes> = [];

	var pending:Array<Void->Void> = [];

	public function new() {}

	public function read(key:String, maxBytes:Int, done:StorageResult->Void):Void
		pending.push(() -> done(files.exists(key) ? Stored(files[key]) : Missing));

	public function write(key:String, bytes:Bytes, done:StorageWriteResult->Void):Void
		pending.push(() -> {
			files[key] = bytes;
			done(Written);
		});

	public function remove(key:String, done:StorageWriteResult->Void):Void
		pending.push(() -> {
			files.remove(key);
			done(Written);
		});

	public function clear(done:StorageWriteResult->Void):Void
		pending.push(() -> {
			files.clear();
			done(Written);
		});

	public function lease(key:String, done:StorageSourceResult->Void):Void
		pending.push(() -> done(files.exists(key) ? Local({location: "memory:" + key, release: () -> {}}) : Missing));

	public function poll():Void {
		var now = pending;
		pending = [];
		for (f in now)
			f();
	}

	public function shutdown():Void {}
}

/** The asset cache's rules (AssetService): revalidation by the host's headers, and the manifest tree. Each "visit" is a new service over the
	same store, as a page loaded again. */
class AssetCacheTests {
	static var checks = 0;
	static var host:Host;
	static var store:Memory;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A new visit: a service over the host and the kept store, with the manifest given.
	static function visit(?manifest:String, ?mode:AssetCacheMode):AssetService {
		var assets = new AssetService(new FetchService(host), new StorageService(store), new StorageService(new Memory(), true), "http://host/");
		if (manifest != null)
			assets.setManifest(manifest);
		if (mode != null)
			assets.setCacheMode(mode);
		return assets;
	}

	// Loads path on assets to the end: its bytes as text, or "failed: <why>".
	static function load(assets:AssetService, path:String):String {
		var outcome:Null<String> = null;
		assets.ensure(path, result -> outcome = switch result {
			case Loaded(bytes): bytes.toString();
			case Failed(message): "failed: " + message;
			case Cancelled: "cancelled";
		});
		for (_ in 0...200) {
			if (outcome != null)
				break;
			assets.poll();
		}
		check(outcome != null, 'A load of $path ended');
		return outcome;
	}

	static function stream(assets:AssetService, path:String):String {
		var outcome:Null<String> = null;
		assets.streamSource(path, result -> outcome = switch result {
			case Located(Stored(lease)): "cached";
			case Located(Remote(url)): "remote";
			case Failed(message): "failed: " + message;
			case Cancelled: "cancelled";
		});
		for (_ in 0...200) {
			if (outcome != null)
				break;
			assets.poll();
		}
		return outcome;
	}

	// The manifests of dirs over the host's files, as tools/gen_manifest.py writes them: the deepest first, so a parent lists its children's.
	static function manifests(dirs:Array<String>):Void {
		dirs.sort((a, b) -> b.split("/").length - a.split("/").length);
		for (dir in dirs) {
			var prefix = dir == "" ? "" : dir + "/",
				files:Dynamic = {},
				subdirs:Dynamic = {};
			for (path => file in host.files) {
				if (!StringTools.startsWith(path, prefix))
					continue;
				var rest = path.substr(prefix.length);
				if (rest == "manifest.json")
					continue;
				var parts = rest.split("/");
				if (parts.length == 1)
					Reflect.setField(files, rest, AssetManifest.hash(file.body));
				else if (parts.length == 2 && parts[1] == "manifest.json")
					Reflect.setField(subdirs, parts[0], AssetManifest.hash(file.body));
			}
			host.put(prefix + "manifest.json", haxe.Json.stringify({manifest: 1, files: files, dirs: subdirs}));
		}
	}

	static function main():Void {
		// Revalidation: a stale copy is asked about with its ETag; 304 keeps it.
		host = new Host();
		store = new Memory();
		host.put("a.txt", "one");
		check(load(visit(), "a.txt") == "one" && host.count("a.txt") == 1, "A file downloads");
		check(load(visit(), "a.txt") == "one" && host.count("a.txt") == 2 && host.sent["a.txt"]["If-None-Match"] != null,
			"A stale copy is asked about with its ETag");
		host.put("a.txt", "two");
		check(load(visit(), "a.txt") == "two", "A changed file replaces the copy");
		// Fresh by Cache-Control: no request.
		host.put("fresh.txt", "kept", "public, max-age=600");
		load(visit(), "fresh.txt");
		host.put("fresh.txt", "changed", "public, max-age=600");
		check(load(visit(), "fresh.txt") == "kept" && host.count("fresh.txt") == 1, "A fresh copy is used without a request");
		// Offline and 5xx: the copy.
		host.offline = true;
		check(load(visit(), "a.txt") == "two", "Offline, the copy is used");
		host.offline = false;
		host.status = 503;
		check(load(visit(), "a.txt") == "two", "A 5xx uses the copy");
		host.status = null;
		// Gone: the copy goes too.
		host.files.remove("a.txt");
		check(StringTools.startsWith(load(visit(), "a.txt"), "failed"), "A file the host no longer has fails");
		host.offline = true;
		check(StringTools.startsWith(load(visit(), "a.txt"), "failed"), "and its copy is gone, offline too");
		host.offline = false;
		// Streaming: a fresh copy is leased; a stale one isn't, the host's URL is given instead.
		check(stream(visit(), "fresh.txt") == "cached", "A fresh copy streams from the cache");
		host.put("b.txt", "bee");
		load(visit(), "b.txt");
		check(stream(visit(), "b.txt") == "remote", "A stale copy streams from the host");

		// The manifest tree.
		host = new Host();
		store = new Memory();
		host.put("top.txt", "top", "max-age=600");
		host.put("models/car.glb", "car");
		host.put("models/parts/wheel.glb", "wheel");
		host.put("sounds/beep.ogg", "beep");
		manifests(["", "models", "models/parts", "sounds"]);
		check(load(visit("manifest.json"), "models/parts/wheel.glb") == "wheel", "A listed file downloads");
		check(host.count("manifest.json") == 1
			&& host.count("models/manifest.json") == 1
			&& host.count("models/parts/manifest.json") == 1
			&& host.count("sounds/manifest.json") == 0,
			"Only the manifests on its way are fetched");
		var assets = visit("manifest.json");
		check(load(assets, "models/parts/wheel.glb") == "wheel" && load(assets, "models/car.glb") == "car", "Listed files load");
		check(host.count("models/parts/wheel.glb") == 1, "An unchanged listed file isn't asked about");
		check(host.count("manifest.json") == 2 && host.count("models/manifest.json") == 1,
			"The root is asked about once a visit; an unchanged directory's manifest isn't fetched");
		// A change reaches only what changed.
		host.put("models/parts/wheel.glb", "new wheel");
		manifests(["", "models", "models/parts", "sounds"]);
		assets = visit("manifest.json");
		check(load(assets, "models/parts/wheel.glb") == "new wheel"
			&& load(assets, "models/car.glb") == "car", "A changed file is fetched again");
		check(host.count("models/car.glb") == 1 && host.count("models/parts/wheel.glb") == 2, "Only the changed file is fetched");
		check(host.sent["models/parts/wheel.glb"]["If-None-Match"] == null, "A file the manifest says changed is downloaded whole");
		// Offline: the cached root, and every listed copy.
		host.offline = true;
		assets = visit("manifest.json");
		check(load(assets, "models/parts/wheel.glb") == "new wheel"
			&& load(assets, "models/car.glb") == "car", "Offline, the cached tree serves");
		host.offline = false;
		// A download that isn't what the manifest says isn't kept.
		var good = host.files["models/car.glb"];
		host.put("models/car.glb", "car");
		host.files["models/car.glb"] = {body: Bytes.ofString("half-deployed"), headers: good.headers};
		host.put("models/manifest.json",
			host.files["models/manifest.json"].body.toString()
			.split(AssetManifest.hash(Bytes.ofString("car")))
			.join(AssetManifest.hash(Bytes.ofString("new car"))));
		manifests([""]);
		check(StringTools.startsWith(load(visit("manifest.json"), "models/car.glb"), "failed"), "A download not matching its manifest fails");
		host.files["models/car.glb"] = {body: Bytes.ofString("new car"), headers: good.headers};
		check(load(visit("manifest.json"), "models/car.glb") == "new car", "and isn't kept: the next visit fetches the right one");
		// A file no manifest lists, and a host without one: revalidated.
		check(load(visit("manifest.json"), "top.txt") == "top", "An unlisted file loads");
		// A file its directory's manifest drops is asked about however fresh, and its 404 deletes the copy.
		host.put("sounds/gone.ogg", "gone", "max-age=600");
		manifests(["", "sounds"]);
		check(load(visit("manifest.json"), "sounds/gone.ogg") == "gone", "A listed file loads");
		host.files.remove("sounds/gone.ogg");
		manifests(["", "sounds"]);
		check(StringTools.startsWith(load(visit("manifest.json"), "sounds/gone.ogg"), "failed") && host.count("sounds/gone.ogg") == 2,
			"A file its manifest drops is asked about, however fresh, and fails once gone");
		check(stream(visit("manifest.json"), "models/car.glb") == "cached", "A current listed copy streams from the cache");
		host.files.remove("manifest.json");
		check(load(visit("manifest.json"), "models/car.glb") == "new car", "Without a root manifest, files are revalidated");
		// Trust: a copy is used however old; a listed file still follows its manifest.
		host = new Host();
		store = new Memory();
		host.put("old.txt", "old");
		host.put("listed/a.txt", "a");
		manifests(["", "listed"]);
		load(visit(), "old.txt");
		load(visit("manifest.json"), "listed/a.txt");
		host.put("old.txt", "new");
		host.put("listed/a.txt", "new a");
		manifests(["", "listed"]);
		check(load(visit(null, Trust), "old.txt") == "old" && host.count("old.txt") == 1, "Trust uses a stale copy without asking");
		check(load(visit("manifest.json", Trust), "listed/a.txt") == "new a", "Trust still follows a manifest");
		check(stream(visit(null, Trust), "old.txt") == "cached", "Trust streams a stale copy from the cache");
		// Off: earlier copies neither used nor deleted; a file loads once a run; nothing kept.
		var kept = Lambda.count(store.files);
		assets = visit(null, Off);
		check(load(assets, "old.txt") == "new" && load(assets, "old.txt") == "new" && host.count("old.txt") == 2,
			"Off ignores earlier copies, and loads a file once a run");
		host.put("off.txt", "off");
		check(load(assets, "off.txt") == "off" && Lambda.count(store.files) == kept, "Off keeps nothing");
		check(stream(visit(null, Off), "old.txt") == "remote", "Off streams from the host");
		host.offline = true;
		check(load(visit(), "old.txt") == "old", "and leaves earlier copies as they were");
		check(StringTools.startsWith(load(visit(null, Off), "old.txt"), "failed"), "Off has no copy to fall back on");
		host.offline = false;
		var offCleared = false;
		assets.clearCache(_ -> offCleared = true);
		for (_ in 0...50)
			assets.poll();
		check(offCleared && load(assets, "off.txt") == "off" && host.count("off.txt") == 2, "Clearing forgets this run's copies too");
		// Clearing forgets the manifests read, so the root is asked about again.
		assets = visit("manifest.json");
		load(assets, "listed/a.txt");
		var asked = host.count("manifest.json");
		var cleared = false;
		assets.clearCache(_ -> cleared = true);
		for (_ in 0...50)
			assets.poll();
		check(cleared
			&& load(assets, "listed/a.txt") == "new a"
			&& host.count("manifest.json") == asked + 1, "Clearing the cache forgets the manifests too");

		// A copy brought from elsewhere (ensure's source) remembers where: asked about there, streamed from there, as the host has nothing
		// at its path (the force-fetch example, which the manifests' Ask rule broke: its path is one its directory's manifest leaves out).
		host.put("listed/song.txt", "song");
		manifests(["listed", ""]);
		var sourced = visit("manifest.json"), got:Null<String> = null;
		sourced.ensure("listed/bogus.txt", result -> got = switch result {
			case Loaded(bytes): bytes.toString();
			case Failed(message): "failed: " + message;
			case Cancelled: "cancelled";
		}, null, {source: "listed/song.txt", forceFetch: true});
		for (_ in 0...200) {
			if (got != null)
				break;
			sourced.poll();
		}
		check(got == "song" && host.count("listed/bogus.txt") == 0, "A load with a source brings the bytes from there, kept under the path");
		var before = host.count("listed/song.txt");
		check(load(visit("manifest.json"), "listed/bogus.txt") == "song"
			&& host.count("listed/bogus.txt") == 0
			&& host.count("listed/song.txt") == before + 1
			&& host.sent["listed/song.txt"]["If-None-Match"] != null,
			"A plain load of the path later asks about the stale copy at its source, with its ETag");
		var from:Null<String> = null;
		sourced = visit("manifest.json");
		sourced.streamSource("listed/bogus.txt", result -> from = switch result {
			case Located(Remote(url)): url;
			case _: "not remote";
		});
		for (_ in 0...200)
			sourced.poll();
		check(from == "http://host/listed/song.txt", "and a stale sourced copy streams from its source");
		host.put("listed/song.txt", "song", "max-age=600");
		var renewing = visit("manifest.json");
		check(load(renewing, "listed/bogus.txt") == "song", "A stale sourced copy is renewed at its source");
		// Its record's renewal lands at a later poll.
		for (_ in 0...20)
			renewing.poll();
		check(stream(visit("manifest.json"), "listed/bogus.txt") == "cached", "and fresh, it streams from the cache");

		// Manifests that aren't one are trusted nowhere.
		check(AssetManifest.parse(Bytes.ofString('{"manifest":1,"files":{"a":"sha256:00"},"dirs":{}}')) == null, "A bad hash spoils a manifest");
		check(AssetManifest.parse(Bytes.ofString('{"manifest":1,"files":{"a/b":"' + AssetManifest.hash(Bytes.ofString("")) + '"},"dirs":{}}')) == null,
			"A name with a slash spoils a manifest");
		check(AssetManifest.parse(Bytes.ofString('{"manifest":2,"files":{},"dirs":{}}')) == null, "Another version isn't read");
		check(!visit().setManifest("../manifest.json"), "A manifest's path is an asset path");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
