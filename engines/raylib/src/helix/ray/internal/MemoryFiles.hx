package helix.ray.internal;

import haxe.io.Bytes;
import helix.platform.IFileSystem;

/** Holds the files `LoadMusicStreamFromMemory` plays and the files dropped on the window, as a file system read first, so `Assets` and
	`Audio.stream` find them by path as any file.

	A file located for a stream is a Blob's URL in a page, which the media element reads; natively it is written to the program's cache
	directory (`ISystem.getCacheDirectory`) and read from there, as a native stream reads a file. Releasing it lets go of the URL or
	deletes the file, and forgets a stream's bytes; a dropped file's are kept until `remove`. It answers at the next poll, as every file system does, and can't be written. */
@:noCompletion
class MemoryFiles implements IFileSystem {
	final files = new Map<String, Bytes>();
	final waiting:Array<Void->Void> = [];
	var count = 0;
	#if !js
	var cache:Null<helix.platform.adapters.filesystem.native.NativeFileSystemAdapter> = null;
	#end

	/** Creates the file system, holding nothing. */
	public function new() {}

	/** Holds a file's bytes under a new path, until a stream located from it is released.

		@param bytes  The file.
		@param extension  Its extension with its dot, such as ".ogg", ending the path.
		@return  The path. */
	public function add(bytes:Bytes, extension:String):String {
		var safe = ~/[^A-Za-z0-9]/g.replace(extension, "");
		var path = 'helix-ray-memory/${++count}${safe == "" ? "" : "." + safe.toLowerCase()}';
		files.set(path, bytes);
		return path;
	}

	/** Holds a dropped file's bytes under a path of its own, until removed.

		@param name  The file's name, its characters a path can't hold made `_`.
		@param bytes  The file.
		@return  The path, `helix-ray-dropped/<n>/<name>`. */
	public function addDropped(name:String, bytes:Bytes):String {
		var safe = ~/[^A-Za-z0-9_.-]/g.replace(name, "_");
		if (safe == "" || ~/^\.+$/.match(safe))
			safe = "file";
		var path = '$DROPPED${++count}/${safe.substr(-200)}';
		files.set(path, bytes);
		return path;
	}

	/** Forgets a file it holds.

		@param path  The file's path. */
	public function remove(path:String):Void
		files.remove(path);

	/** The directory the dropped files are under. */
	public static inline final DROPPED = "helix-ray-dropped/";

	public var root(get, never):String;

	function get_root():String
		return "the files given LoadMusicStreamFromMemory and the files dropped";

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return false;

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		var aborted = false;
		waiting.push(() -> {
			if (aborted)
				return;
			var bytes = files.get(path);
			if (bytes == null)
				missing();
			else if (bytes.length > maxBytes)
				failed('$path: larger than $maxBytes bytes');
			else
				loaded(bytes);
		});
		return () -> aborted = true;
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed('$path: the files in memory can\'t be written'));

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed('$path: the files in memory can\'t be written'));

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed('the files in memory can\'t be written'));

	public function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> {
			var bytes = files.get(path);
			bytes == null ? missing() : found(bytes.length, 0);
		});

	public function list(directory:String, listed:Array<String>->Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> {
			var prefix = directory == "" ? "" : directory + "/", names = [];
			for (path in files.keys())
				if (StringTools.startsWith(path, prefix)) {
					var rest = path.substr(prefix.length),
						slash = rest.indexOf("/");
					var name = slash < 0 ? rest : rest.substr(0, slash + 1);
					if (names.indexOf(name) < 0)
						names.push(name);
				}
			names.sort(Reflect.compare);
			names.length == 0
			&& directory != "" ? missing() : listed(names);
		});

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
		waiting.push(() -> {
			var bytes = files.get(path);
			if (bytes == null) {
				missing();
				return;
			}
			#if js
			var blob = new js.html.Blob([bytes.getData()], {type: typeOf(path)});
			var url = js.html.URL.createObjectURL(blob);
			located(url, () -> {
				js.html.URL.revokeObjectURL(url);
				forget(path);
			});
			#else
			if (cache == null) {
				cache = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: Runtime.system.getCacheDirectory()});
				Runtime.polled.push(cache);
			}
			var kept = cache;
			kept.write(path, bytes, () -> kept.locate(path, (location, release) -> located(location, () -> {
				release();
				kept.deleteFile(path, () -> {}, _ -> {});
				forget(path);
			}), missing, failed), failed);
			#end
		});
	}

	// Forgets a stream's bytes once it is released; a dropped file stays until removed.
	function forget(path:String):Void
		if (!StringTools.startsWith(path, DROPPED))
			files.remove(path);

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void
		waiting.resize(0);

	#if js
	// A file's media type by its extension, for the media element.
	static function typeOf(path:String):String {
		return switch haxe.io.Path.extension(path) {
			case "ogg": "audio/ogg";
			case "mp3": "audio/mpeg";
			case "wav": "audio/wav";
			case "flac": "audio/flac";
			case _: "";
		}
	}
	#end
}
