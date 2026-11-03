package helix.services.tools;

import haxe.macro.Expr;
#if sys
import haxe.DynamicAccess;
import haxe.Json;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

/** Provides a build-time macro that writes the manifests `Assets` reads.

	Each directory of a tree gets a manifest listing the hash of each file in it and of each subdirectory's own manifest. An unchanged
	directory is then known from its parent's manifest alone.

	Call `write` once in the program, over the directory its files ship in and its server serves. It runs while the program builds. A
	manifest is rewritten only when what it lists changed. A file is hashed again only when its size or modification time changed since
	the last run. Those are kept in a hidden file beside the directory, such as `.assets.manifests` for `assets`. Hidden files, and names
	`IFileSystem` refuses, are skipped.

	```haxe
	AssetManifests.write("assets");
	``` */
class AssetManifests {
	/** Writes the manifests of a directory and every directory under it, while the program builds.

		The build fails when the path isn't a directory.

		@param directory  The tree's root, relative to where the build runs.
		@param name  Optional. Each manifest's file name, which matches `ManifestCacheOptions.manifestName`. Defaults to "manifest.json". */
	public static macro function write(directory:String, name:String = "manifest.json"):Expr {
		try
			writeTree(directory, name)
		catch (e:String)
			haxe.macro.Context.error(e, haxe.macro.Context.currentPos());
		return macro null;
	}

	#if sys
	static final NAME = ~/^[A-Za-z0-9_.-]+$/;

	/** Writes the manifests of a tree, as `write` does, for a build tool or a test that runs on Haxe's interpreter.

		@param directory  The tree's root.
		@param name  Each manifest's file name.
		@return  The number of manifests written, or 0 when nothing changed.
		@throws String  When the path isn't a directory. */
	@:noCompletion
	public static function writeTree(directory:String, name:String):Int {
		if (!FileSystem.isDirectory(directory))
			throw '$directory isn\'t a directory';
		var root = Path.removeTrailingSlashes(directory);
		var recordPath = Path.join([Path.directory(root), "." + Path.withoutDirectory(root) + ".manifests"]);
		var known:DynamicAccess<Dynamic> = try Json.parse(File.getContent(recordPath)) catch (_:Dynamic) {};
		var seen:DynamicAccess<Dynamic> = {};
		var written = 0;
		function walk(relative:String):String {
			var here = relative == "" ? root : '$root/$relative';
			var files = new Map<String, String>(),
				dirs = new Map<String, String>();
			var entries = FileSystem.readDirectory(here);
			entries.sort(Reflect.compare);
			for (entry in entries) {
				if (entry == name || StringTools.startsWith(entry, ".") || !NAME.match(entry))
					continue;
				var path = relative == "" ? entry : '$relative/$entry';
				var full = '$root/$path';
				if (FileSystem.isDirectory(full)) {
					dirs.set(entry, walk(path));
					continue;
				}
				var stat = FileSystem.stat(full);
				var size = stat.size, time = stat.mtime.getTime();
				var last:Dynamic = known.get(path);
				var hash:String = last != null && last.size == size && last.time == time ? last.hash : hashOf(File.getBytes(full));
				seen.set(path, {size: size, time: time, hash: hash});
				files.set(entry, hash);
			}
			var bytes = Bytes.ofString(encode(files, dirs));
			var manifest = '$here/$name';
			if (!FileSystem.exists(manifest) || File.getBytes(manifest).compare(bytes) != 0) {
				File.saveBytes(manifest, bytes);
				written++;
			}
			return hashOf(bytes);
		}
		walk("");
		File.saveContent(recordPath, Json.stringify(seen));
		return written;
	}

	static function hashOf(bytes:Bytes):String
		return "sha256:" + Sha256.make(bytes).toHex();

	// The manifest's text: its names sorted, so the same tree always writes the same bytes and the same hash.
	static function encode(files:Map<String, String>, dirs:Map<String, String>):String {
		function entries(map:Map<String, String>):String {
			var names = [for (name in map.keys()) name];
			names.sort(Reflect.compare);
			return [for (name in names) Json.stringify(name) + ": " + Json.stringify(map.get(name))].join(",\n    ");
		}
		return '{\n  "manifest": 1,\n  "files": {\n    ${entries(files)}\n  },\n  "dirs": {\n    ${entries(dirs)}\n  }\n}\n';
	}
	#end
}
