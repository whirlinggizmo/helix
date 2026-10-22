package helix.tool.shared;

import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** Asset manifests, as helix.asset.AssetManifest reads them and tools/gen_manifest.py writes them: a manifest.json in a directory and in
	every directory under it, listing each file's SHA-256 and each subdirectory's manifest's, so a client knows an unchanged directory from its parent
	alone; deterministic (sorted, compact), written only where one changed; manifest.json files themselves aren't listed, nor names an asset
	path can't hold (helix.asset.AssetPath: A-Z, a-z, 0-9, '_', '.', '-'). */
class AssetManifests {
	static inline final NAME = "manifest.json";
	static final VALID = ~/^[A-Za-z0-9_.-]+$/;

	/** data's hash as manifests write it. */
	public static function digest(data:Bytes):String
		return "sha256:" + Sha256.hex(data);

	/** The manifests from root down to changed (a directory under root, or root) written again, deepest first: changed's whole, and on the
		way up each directory's own files hashed again, its other subdirectories' manifests kept as they are (written only where one is missing). So
		a write after a pack hashes what the pack touched, not every asset (hashing is slow in Haxe's interpreter). */
	public static function rewrite(root:String, changed:String):Void {
		var top = Files.resolve(Sys.getCwd(), root),
			bottom = Files.resolve(Sys.getCwd(), changed);
		if (!Files.contains(top, bottom))
			throw new CommandError('manifests: $changed is not under $root');
		var path = [bottom];
		while (path[path.length - 1] != top)
			path.push(Path.directory(path[path.length - 1]));
		var below = write(bottom);
		for (i in 1...path.length)
			below = writeOne(path[i], path[i - 1], below);
	}

	/** directory's manifest written, and its subdirectories' first; returns its bytes. */
	public static function write(directory:String):Bytes
		return writeOne(directory, null, null);

	// directory's manifest; the subdirectory through (with its manifest's bytes) given, the others' kept (written when missing), or with through
	// null every subdirectory's written first.
	static function writeOne(directory:String, through:Null<String>, throughBytes:Null<Bytes>):Bytes {
		var files = new Array<String>(), dirs = new Array<String>();
		var names = FileSystem.readDirectory(directory);
		names.sort(Reflect.compare);
		var fileDigests = new Map<String, String>(),
			dirDigests = new Map<String, String>();
		for (name in names) {
			if (!VALID.match(name) || name == "." || name == "..")
				continue;
			var entry = Path.join([directory, name]);
			if (FileSystem.isDirectory(entry)) {
				var kept = Path.join([entry, NAME]);
				var bytes:Bytes;
				if (through != null && Files.resolve(directory, name) == through)
					bytes = throughBytes;
				else if (through != null && Files.isFile(kept))
					bytes = File.getBytes(kept);
				else
					bytes = write(entry);
				dirs.push(name);
				dirDigests.set(name, digest(bytes));
			} else if (name != NAME) {
				files.push(name);
				fileDigests.set(name, digest(File.getBytes(entry)));
			}
		}
		// Python's json.dumps(sort_keys=True, separators=(',', ':')): keys in code point order.
		var text = '{"dirs":{'
			+ [for (d in dirs) '${quote(d)}:${quote(dirDigests[d])}'].join(",") + '},"files":{' +
				[for (f in files) '${quote(f)}:${quote(fileDigests[f])}'].join(",") + '},"manifest":1}';
		var data = Bytes.ofString(text);
		var target = Path.join([directory, NAME]);
		if (!Files.isFile(target) || File.getBytes(target).compare(data) != 0)
			File.saveBytes(target, data);
		return data;
	}

	// A valid name or digest as a JSON string: neither needs escaping.
	static function quote(text:String):String
		return '"' + text + '"';
}
