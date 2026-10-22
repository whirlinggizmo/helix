package helix.tool.shared;

import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** File work the commands share: absolute paths, directories copied and removed whole, a path as a message shows it, and a directory zipped. */
class Files {
	/** path made absolute against base (unless it already is), normalized, with forward slashes and no trailing one. */
	public static function resolve(base:String, path:String):String {
		var full = Path.isAbsolute(path) ? path : Path.join([base, path]);
		return Path.removeTrailingSlashes(Path.normalize(FileSystem.absolutePath(full)));
	}

	/** Whether path is a file (not a directory). */
	public static function isFile(path:String):Bool
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);

	/** Whether path is a directory. */
	public static function isDirectory(path:String):Bool
		return FileSystem.exists(path) && FileSystem.isDirectory(path);

	/** The directory at path made, with its parents. */
	public static function makeDirectory(path:String):Void
		FileSystem.createDirectory(path);

	/** text written to path as UTF-8 with the newlines it has (LF on every system), its directory made first. */
	public static function writeText(path:String, text:String):Void {
		makeDirectory(Path.directory(path));
		File.saveContent(path, text);
	}

	/** The directory at path removed with everything in it; nothing when it isn't there. */
	public static function removeDirectory(path:String):Void {
		if (!isDirectory(path))
			return;
		for (name in FileSystem.readDirectory(path)) {
			var child = Path.join([path, name]);
			if (isDirectory(child))
				removeDirectory(child);
			else
				FileSystem.deleteFile(child);
		}
		FileSystem.deleteDirectory(path);
	}

	/** The directory from copied to to, with everything in it; returns how many files. */
	public static function copyDirectory(from:String, to:String):Int {
		makeDirectory(to);
		var count = 0;
		for (name in FileSystem.readDirectory(from)) {
			var source = Path.join([from, name]),
				target = Path.join([to, name]);
			if (isDirectory(source))
				count += copyDirectory(source, target);
			else {
				File.copy(source, target);
				count++;
			}
		}
		return count;
	}

	/** The bytes in the file at path, or in every file under the directory at path; 0 when nothing is there. */
	public static function size(path:String):Float {
		if (isFile(path))
			return FileSystem.stat(path).size;
		var total = 0.0;
		if (isDirectory(path))
			for (name in FileSystem.readDirectory(path))
				total += size(Path.join([path, name]));
		return total;
	}

	/** Every file under directory, as paths relative to it with forward slashes, sorted. */
	public static function listFiles(directory:String, prefix = ""):Array<String> {
		var out = [];
		var names = FileSystem.readDirectory(directory);
		names.sort(Reflect.compare);
		for (name in names) {
			var path = Path.join([directory, name]);
			if (isDirectory(path))
				out = out.concat(listFiles(path, prefix + name + "/"));
			else
				out.push(prefix + name);
		}
		out.sort(Reflect.compare);
		return out;
	}

	/** path as the directory base sees it (relative, forward slashes) for a message; the path itself when it's elsewhere. */
	public static function relative(path:String, base:String):String {
		var full = resolve(base, path), root = resolve(base, ".");
		if (full == root)
			return ".";
		return StringTools.startsWith(full, root + "/") ? full.substr(root.length + 1) : path;
	}

	/** Whether ancestor is directory or holds it (both absolute, as resolve gives them). */
	public static function contains(ancestor:String, directory:String):Bool
		return directory == ancestor || StringTools.startsWith(directory, ancestor == "/" ? "/" : ancestor + "/");

	/** The files of directory (not skip, when it's among them) written to the zip at target, deflated, each at its path within directory. */
	public static function zipDirectory(directory:String, target:String, ?skip:String):Void {
		var entries = new List<haxe.zip.Entry>();
		for (name in listFiles(directory)) {
			var path = Path.join([directory, name]);
			if (skip != null && resolve(directory, name) == skip)
				continue;
			var data = File.getBytes(path);
			var entry:haxe.zip.Entry = {
				fileName: name,
				fileSize: data.length,
				fileTime: FileSystem.stat(path).mtime,
				compressed: false,
				dataSize: data.length,
				data: data,
				crc32: haxe.crypto.Crc32.make(data)
			};
			haxe.zip.Tools.compress(entry, 9);
			entries.add(entry);
		}
		// Written whole, so a failure leaves no partial zip.
		var out = new haxe.io.BytesOutput();
		new haxe.zip.Writer(out).write(entries);
		makeDirectory(Path.directory(target));
		File.saveBytes(target, out.getBytes());
	}

	/** The bytes of path. */
	public static function read(path:String):Bytes
		return File.getBytes(path);
}
