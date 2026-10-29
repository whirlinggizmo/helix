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

/** Provides writing the manifests `Assets` reads: in each directory of a tree, a file listing the hash of each file in it and of each
	subdirectory's own manifest, so an unchanged directory is known from its parent alone.

	Called once in the program, it runs while the program builds, over the directory its files ship in and its server serves. A manifest is rewritten only
	when what it lists changed, and a file is hashed again only when its size or time changed since the last run, kept in a hidden file
	beside the directory (`.assets.manifests` for `assets`). Hidden files and names `IFileSystem` refuses are left out.

	```haxe
	AssetManifests.write("assets");
	``` */
class AssetManifests {
	/** Writes the manifests of a directory and every directory under it, while the program builds; a directory that isn't one fails the
		build.

		@param directory  The tree's root, relative to where the build runs.
		@param name  Optional. Each manifest's file name, as `AssetsOptions.manifestName`; "manifest.json" by default. */
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
		@return  How many manifests were written; 0 when nothing changed.
		@throws String  For a directory that isn't one. */
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
