import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.tools.AssetManifests;
import sys.FileSystem;
import sys.io.File;

/** Checks AssetManifests on the interpreter over a tree it makes: a manifest in each directory, a subdirectory known by its manifest's
	hash, nothing rewritten when nothing changed, only the changed path rewritten after a change, and Assets reading the shipped tree in
	place of downloading what the server's identical tree lists. */
class ManifestTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var top = "build/tests/manifests";
		var root = '$top/assets';
		remove(top);
		for (dir in [root, '$root/levels', '$root/music'])
			FileSystem.createDirectory(dir);
		File.saveContent('$root/levels/1.json', "level one");
		File.saveContent('$root/music/song.ogg', "a song");
		File.saveContent('$root/title.png', "title");
		File.saveContent('$root/.hidden', "left out");

		check(AssetManifests.writeTree(root, "manifest.json") == 3, "a manifest in each directory");
		var top_ = File.getContent('$root/manifest.json');
		var levels = File.getBytes('$root/levels/manifest.json');
		check(top_.indexOf('"title.png"') >= 0 && top_.indexOf('.hidden') < 0, "files listed, hidden ones left out");
		check(top_.indexOf("sha256:" + haxe.crypto.Sha256.make(levels).toHex()) >= 0, "a subdirectory known by its manifest's hash");
		check(AssetManifests.writeTree(root, "manifest.json") == 0, "nothing changed: nothing written");
		var music = File.getContent('$root/music/manifest.json');
		File.saveContent('$root/levels/1.json', "level one, patched");
		check(AssetManifests.writeTree(root, "manifest.json") == 2, "a file changed: its directory and the root rewritten");
		check(File.getContent('$root/music/manifest.json') == music, "a sibling directory's untouched");
		check(FileSystem.exists('$top/.assets.manifests')
			&& !FileSystem.exists('$root/.assets.manifests'), "its record beside the tree, not in it");

		// The tree as shipped, and the same tree on a server: nothing downloaded but manifests.
		var shipped = new FakeFileSystem(),
			http = new FakeHttp(),
			cache = new FakeFileSystem();
		var base = "https://cdn.example/";
		for (path in [
			"manifest.json",
			"title.png",
			"levels/manifest.json",
			"levels/1.json",
			"music/manifest.json",
			"music/song.ogg"
		]) {
			var bytes = File.getBytes('$root/$path');
			shipped.files.set(path, bytes);
			http.routes.set(base + path, {status: 200, body: bytes});
		}
		var assets = new Assets({sources: [HttpServer(base, Manifest), FileSystem(shipped)], httpClient: http, cacheFileSystem: cache});
		var got = [];
		for (path in ["title.png", "levels/1.json", "music/song.ogg"])
			assets.load(path, bytes -> got.push(bytes.toString()));
		for (_ in 0...40) {
			http.poll();
			cache.poll();
			shipped.poll();
		}
		var fetched = [for (r in http.requests) r.url];
		check(got.length == 3 && got.indexOf("level one, patched") >= 0, "every file loaded");
		check(fetched.filter(url -> !StringTools.endsWith(url, "manifest.json")).length == 0, "the shipped files read in place: only manifests fetched");
		remove(top);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function remove(path:String):Void {
		if (!FileSystem.exists(path))
			return;
		if (FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path))
				remove('$path/$entry');
			FileSystem.deleteDirectory(path);
		} else
			FileSystem.deleteFile(path);
	}
}
