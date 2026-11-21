import haxe.io.Path;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Assets.*;
import helix.raylib.internal.Runtime;
import helix.services.time.Time;
import sys.FileSystem;
import sys.io.File;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Mutex;
import sys.thread.Thread;

/** Checks the asset hosts natively, over directories of the test's own and a server of its own on this machine: the default host read;
	a directory before another overriding its files, and the later one read for a file the first has none of; a file's length from the
	first directory with it; an ensure and a save in flight as the hosts are set, each answered; a URL's files fetched and stored under
	`assets` in the cache directory; a directory after a URL as its shipped files, an unchanged file read in place and only a changed
	one downloaded; a directory before the URL overriding it, and a cached file used without a download; a URL alone, its file fetched;
	the cache listed by directory with each file's host, the server's manifests among them, whatever the hosts in use; the cache
	emptied, the ensured assets still ensured, a saved file and the cache directory's other files untouched, and a deleted file fetched
	again.

	Built without `-D helix-raylib-portable-sys`, as the test writes its files with Haxe's own calls. Run from the repository's root. */
@:access(helix.raylib.internal.Runtime)
class AssetHostsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// Polls until done, for at most ten seconds.
	static function wait(done:Void->Bool, what:String):Void {
		var until = Sys.time() + 10;
		while (!done()) {
			if (Sys.time() > until)
				throw 'no answer in ten seconds: $what';
			Runtime.pollAnswers();
			Sys.sleep(.001);
		}
	}

	// Ensures files, and returns each one's text in order, joined by `|`.
	static function ensure(names:Array<String>):String {
		var ensured = false;
		EnsureAssetsAsync(names, () -> ensured = true, error -> throw error);
		wait(() -> ensured, 'ensuring $names');
		return [for (name in names) Runtime.files.get(name).toString()].join("|");
	}

	// The cache's files under a directory, each "<file name> <host>", joined by `,`.
	static function cached(path:String):String {
		var list:Null<String> = null;
		ListAssetCacheAsync(path, assets -> list = [for (asset in assets) asset.fileName + " " + asset.host].join(","), error -> throw error);
		check(list == null, "the cache listed later, not during the call");
		wait(() -> list != null, 'listing the cache under "$path"');
		return list;
	}

	static function write(root:String, files:Map<String, String>):Void
		for (path => text in files) {
			var file = Path.join([root, path]);
			FileSystem.createDirectory(Path.directory(file));
			File.saveContent(file, text);
		}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var root = Path.join([Sys.getCwd(), "build/tests/AssetHostsTests-files"]);
		if (FileSystem.exists(root))
			helix.platform.tools.Files.removeDirectory(root);
		write(root, [
			"web/a.txt" => "default a",
			"web/only.txt" => "only in the default",
			"mods/a.txt" => "modded a, longer",
			"shipped/a.txt" => "a v1",
			"shipped/levels/b.txt" => "b v1",
			"served/a.txt" => "a v1",
			"served/levels/b.txt" => "b v2",
			"served/levels/c.txt" => "c",
			"cache/stream.tmp" => "another's file",
			"program/placeholder" => ""
		]);
		helix.services.tools.AssetManifests.writeTree(Path.join([root, "shipped"]), "manifest.json");
		helix.services.tools.AssetManifests.writeTree(Path.join([root, "served"]), "manifest.json");
		var server = new Server(Path.join([root, "served"]));
		Runtime.system = new HostsSystem(root);
		Runtime.time = new Time(Runtime.system);

		// The default host, ../web beside the program's directory.
		check(ensure(["a.txt", "only.txt"]) == "default a|only in the default", "the default host's files read");
		check(GetApplicationDirectory() == Path.join([root, "web"]) + "/", 'the application directory, the first host\'s: ${GetApplicationDirectory()}');

		// A directory before another overrides its files, as a mod does. An ensure in flight is answered by the hosts it was made over.
		ReleaseAsset("a.txt");
		var inFlight = false;
		EnsureAssetAsync("a.txt", () -> inFlight = true, error -> throw error);
		SetAssetHosts(["../mods", "../web"]);
		check(!IsAssetEnsured("only.txt") && !Runtime.files.exists("only.txt"), "the ensured assets released as the hosts are set");
		wait(() -> inFlight, "an ensure in flight as the hosts are set");
		check(Runtime.files.get("a.txt").toString() == "default a", "an ensure in flight as the hosts are set: read from the hosts before");
		ReleaseAsset("a.txt");
		check(ensure(["a.txt", "only.txt"]) == "modded a, longer|only in the default", "the first directory's file, and the second's where the first has none");
		var lengths:Array<Int> = [];
		GetFileLengthAsync("a.txt", length -> lengths.push(length));
		GetFileLengthAsync("only.txt", length -> lengths.push(length));
		GetFileLengthAsync("nowhere.txt", length -> lengths.push(length));
		wait(() -> lengths.length == 3, "the files' lengths");
		lengths.sort(Reflect.compare);
		check(lengths.join(",") == "0,16,19", 'a file\'s length from the first directory with it, 0 for a file in none: $lengths');
		check(cached("") == "", "directories alone: the cache empty");

		// A directory after a URL is the URL's shipped files: an unchanged file read in place, a changed or new one downloaded. A save in
		// flight as the hosts are set is written.
		var saved = false;
		SaveFileTextAsync("progress.txt", "level 3", () -> saved = true, error -> throw error);
		SetAssetHosts([server.url, "../shipped"]);
		wait(() -> saved, "a save in flight as the hosts are set");
		check(ensure(["a.txt", "levels/b.txt", "levels/c.txt"]) == "a v1|b v2|c", "a URL's files read, the changed one the server's");
		var asked = server.served();
		check(asked.indexOf("a.txt") < 0 && asked.indexOf("levels/b.txt") >= 0 && asked.indexOf("levels/c.txt") >= 0,
			'the shipped file at the server\'s hash read in place, the changed and the new one downloaded: $asked');
		var listing = 'levels/b.txt ${server.url},levels/c.txt ${server.url},levels/manifest.json ${server.url}';
		wait(() -> FileSystem.exists(Path.join([root, "cache/assets"])), "the cache's directory");
		check(cached("levels") == listing, 'the cache listed under a directory, each file with its host, a manifest too: ${cached("levels")}');
		check(FileSystem.readDirectory(Path.join([root, "cache"]))
			.join(",")
			.split(",")
			.filter(n -> n != "assets" && n != "stream.tmp")
			.length == 0,
			'the fetched files stored under assets in the cache directory: ${FileSystem.readDirectory(Path.join([root, "cache"]))}');

		// A directory before the URL overrides it, and a cached file at the server's hash is used without a download.
		var before = server.served().length;
		SetAssetHosts(["../mods", server.url, "../shipped"]);
		check(ensure(["a.txt", "levels/b.txt"]) == "modded a, longer|b v2", "a directory before a URL overrides its file");
		check(server.served().slice(before).indexOf("levels/b.txt") < 0, 'a cached file used without a download: ${server.served().slice(before)}');

		// The cache is every URL host's, whatever the hosts in use.
		SetAssetHosts(["../web"]);
		check(cached("levels/") == listing && cached("nowhere") == "", 'the cache listed with no URL host in use: ${cached("levels/")}');

		// A URL alone: its file fetched and stored.
		SetAssetHosts([server.url]);
		check(ensure(["a.txt"]) == "a v1" && server.served().indexOf("a.txt") >= 0, "a URL alone: its file fetched");
		wait(() -> cached("").indexOf("a.txt") >= 0, "the fetched file in the cache");
		check(cached("") == 'a.txt ${server.url},$listing,manifest.json ${server.url}', 'the whole cache listed: ${cached("")}');

		// Emptied: the ensured assets stay, a saved file and the cache directory's other files too, and a deleted file is fetched again.
		var cleared = false;
		ClearAssetCacheAsync(() -> cleared = true, error -> throw error);
		check(!cleared, "the cache emptied later, not during the call");
		wait(() -> cleared, "emptying the cache");
		check(cached("") == "", 'the cache empty: ${cached("")}');
		check(IsAssetEnsured("a.txt") && Runtime.files.get("a.txt").toString() == "a v1", "an ensured asset still ensured");
		check(File.getContent(Path.join([root, "cache/stream.tmp"])) == "another's file", "the cache directory's other files untouched");
		var progress:Null<String> = null;
		LoadFileTextAsync("progress.txt", text -> progress = text, error -> throw error);
		wait(() -> progress != null, "loading the saved file");
		check(progress == "level 3", 'the saved file untouched: $progress');
		before = server.served().length;
		ReleaseAsset("a.txt");
		check(ensure(["a.txt"]) == "a v1" && server.served().slice(before).indexOf("a.txt") >= 0, "a deleted file fetched again");
		wait(() -> cached("") != "", "the file fetched again in the cache");
		check(cached("") == 'a.txt ${server.url}', 'and listed with its host again: ${cached("")}');

		server.close();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
		Sys.exit(0);
	}
}

// The platform's system over directories under a root of the test's own.
private class HostsSystem extends FakeSystem {
	final root:String;

	public function new(root:String) {
		super();
		this.root = root;
	}

	override public function getProgramDirectory():String
		return Path.join([root, "program"]) + "/";

	override public function getDataDirectory():String
		return Path.join([root, "data"]);

	override public function getCacheDirectory():String
		return Path.join([root, "cache"]);
}

// Serves a directory over HTTP on this machine, at a port the OS picks, on a thread of its own, and records the paths it served.
private class Server {
	public final url:String;

	final directory:String;
	final socket = new Socket();
	final lock = new Mutex();
	final paths:Array<String> = [];

	public function new(directory:String) {
		this.directory = directory;
		socket.bind(new Host("127.0.0.1"), 0);
		socket.listen(8);
		url = 'http://127.0.0.1:${socket.host().port}/';
		Thread.create(() -> while (true) {
			var client = try socket.accept() catch (_:Dynamic) return;
			answer(client);
		});
	}

	public function served():Array<String> {
		lock.acquire();
		var copy = paths.copy();
		lock.release();
		return copy;
	}

	public function close():Void
		socket.close();

	function answer(client:Socket):Void {
		try {
			var request = StringTools.trim(client.input.readLine()).split(" ");
			while (StringTools.trim(client.input.readLine()) != "") {}
			var path = request[1].substr(1);
			var file = Path.join([directory, path]);
			if (request[0] == "GET" && path.indexOf("..") < 0 && FileSystem.exists(file) && !FileSystem.isDirectory(file)) {
				var bytes = File.getBytes(file);
				lock.acquire();
				paths.push(path);
				lock.release();
				client.output.writeString('HTTP/1.1 200 OK\r\nContent-Length: ${bytes.length}\r\nConnection: close\r\n\r\n');
				client.output.write(bytes);
			} else
				client.output.writeString("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
		} catch (_:Dynamic) {}
		client.close();
	}
}
