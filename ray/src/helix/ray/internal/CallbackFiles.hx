package helix.ray.internal;

import haxe.io.Bytes;
import helix.platform.IFileSystem;

/** Holds the files raylib's `SetLoadFileDataCallback` gives, as a file system read first, before the program's own files: what the
	callback answers is the file, and a file it doesn't answer (null) is missing here, so the next source is read. It answers at the
	next poll, as every file system does, and can't be written. */
@:noCompletion
class CallbackFiles implements IFileSystem {
	/** The program's callback, or null for none. */
	public static var load:Null<String->Null<Bytes>> = null;

	final waiting:Array<Void->Void> = [];

	/** Creates the file system. */
	public function new() {}

	public var root(get, never):String;

	function get_root():String
		return "raylib's load callback";

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return false;

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		var aborted = false;
		waiting.push(() -> {
			if (aborted)
				return;
			var bytes = load == null ? null : load(path);
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
		waiting.push(() -> failed('$path: raylib\'s load callback can\'t be written'));

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed('$path: raylib\'s load callback can\'t be written'));

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed('raylib\'s load callback can\'t be written'));

	// Its files are in memory, not where a stream could read them, so each is missing here and a stream reads the program's own.
	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(missing);

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void
		waiting.resize(0);
}
