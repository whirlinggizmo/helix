package tools.game;

import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** File work the commands share: absolute paths, folders copied and removed whole, a path as a message shows it, and a folder zipped. */
class Files {
	/** path made absolute against base (unless it already is), normalized, with forward slashes and no trailing one. */
	public static function resolve(base:String, path:String):String {
		var full = Path.isAbsolute(path) ? path : Path.join([base, path]);
		return Path.removeTrailingSlashes(Path.normalize(FileSystem.absolutePath(full)));
	}

	/** Whether path is a file (not a folder). */
	public static function isFile(path:String):Bool
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);

	/** Whether path is a folder. */
	public static function isFolder(path:String):Bool
		return FileSystem.exists(path) && FileSystem.isDirectory(path);

	/** The folder at path made, with its parents. */
	public static function makeFolder(path:String):Void
		FileSystem.createDirectory(path);

	/** text written to path as UTF-8 with the newlines it has (LF on every system), its folder made first. */
	public static function writeText(path:String, text:String):Void {
		makeFolder(Path.directory(path));
		File.saveContent(path, text);
	}

	/** The folder at path removed with everything in it; nothing when it isn't there. */
	public static function removeFolder(path:String):Void {
		if (!isFolder(path))
			return;
		for (name in FileSystem.readDirectory(path)) {
			var child = Path.join([path, name]);
			if (isFolder(child))
				removeFolder(child);
			else
				FileSystem.deleteFile(child);
		}
		FileSystem.deleteDirectory(path);
	}

	/** The folder from copied to to, with everything in it; returns how many files. */
	public static function copyFolder(from:String, to:String):Int {
		makeFolder(to);
		var count = 0;
		for (name in FileSystem.readDirectory(from)) {
			var source = Path.join([from, name]),
				target = Path.join([to, name]);
			if (isFolder(source))
				count += copyFolder(source, target);
			else {
				File.copy(source, target);
				count++;
			}
		}
		return count;
	}

	/** The bytes in the file at path, or in every file under the folder at path; 0 when nothing is there. */
	public static function size(path:String):Float {
		if (isFile(path))
			return FileSystem.stat(path).size;
		var total = 0.0;
		if (isFolder(path))
			for (name in FileSystem.readDirectory(path))
				total += size(Path.join([path, name]));
		return total;
	}

	/** Every file under folder, as paths relative to it with forward slashes, sorted. */
	public static function listFiles(folder:String, prefix = ""):Array<String> {
		var out = [];
		var names = FileSystem.readDirectory(folder);
		names.sort(Reflect.compare);
		for (name in names) {
			var path = Path.join([folder, name]);
			if (isFolder(path))
				out = out.concat(listFiles(path, prefix + name + "/"));
			else
				out.push(prefix + name);
		}
		out.sort(Reflect.compare);
		return out;
	}

	/** path as the folder base sees it (relative, forward slashes) for a message; the path itself when it's elsewhere. */
	public static function relative(path:String, base:String):String {
		var full = resolve(base, path), root = resolve(base, ".");
		if (full == root)
			return ".";
		return StringTools.startsWith(full, root + "/") ? full.substr(root.length + 1) : path;
	}

	/** Whether ancestor is folder or holds it (both absolute, as resolve gives them). */
	public static function contains(ancestor:String, folder:String):Bool
		return folder == ancestor || StringTools.startsWith(folder, ancestor == "/" ? "/" : ancestor + "/");

	/** The files of folder (not skip, when it's among them) written to the zip at target, deflated, each at its path within folder. */
	public static function zipFolder(folder:String, target:String, ?skip:String):Void {
		var entries = new List<haxe.zip.Entry>();
		for (name in listFiles(folder)) {
			var path = Path.join([folder, name]);
			if (skip != null && resolve(folder, name) == skip)
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
		makeFolder(Path.directory(target));
		File.saveBytes(target, out.getBytes());
	}

	/** The bytes of path. */
	public static function read(path:String):Bytes
		return File.getBytes(path);
}
