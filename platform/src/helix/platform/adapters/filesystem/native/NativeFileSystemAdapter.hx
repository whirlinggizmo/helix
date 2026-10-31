package helix.platform.adapters.filesystem.native;

import haxe.io.Bytes;
import haxe.io.Path;
import helix.platform.IFileSystem;
import helix.platform.adapters.shared.AtomicFile;
import helix.platform.FilePath;
import helix.platform.adapters.shared.Mailbox;
import sys.thread.Thread;

/** Provides `IFileSystem` natively: files under a directory on disk, each operation on a worker thread.

	A write is whole or not at all (`AtomicFile`), so a reader never sees half a file. A located file is its path, with nothing to
	release. */
class NativeFileSystemAdapter implements IFileSystem {
	var directory:String;
	var writable:Bool;
	var mailbox = new Mailbox();

	/** Creates a file system over a directory, made when first written.

		@param options  The directory, and whether it is read-only. */
	public function new(options:NativeFileSystemAdapterOptions) {
		directory = options.directory;
		writable = !options.readOnly;
	}

	public var root(get, never):String;

	function get_root():String
		return directory;

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return writable;

	// Runs work on a worker thread; what it returns is called on the main thread at a later poll, unless aborted.
	function run(work:Void->(Void->Void)):Void->Void {
		var aborted = false;
		Thread.create(() -> {
			var answer = work();
			mailbox.post(() -> if (!aborted) answer());
		});
		return () -> aborted = true;
	}

	static inline var READ_ONLY = "Read-only file system";

	// A refusal, answered at a later poll.
	function refuse(failed:String->Void, message = FilePath.INVALID):Void->Void {
		var aborted = false;
		mailbox.post(() -> if (!aborted) failed(message));
		return () -> aborted = true;
	}

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		if (!FilePath.isValid(path))
			return refuse(failed);
		var file = Path.join([directory, path]);
		return run(() -> try {
			if (!sys.FileSystem.exists(file))
				missing;
			else if (sys.FileSystem.stat(file).size > maxBytes)
				() -> failed("File exceeds byte limit");
			else {
				var bytes = sys.io.File.getBytes(file);
				() -> loaded(bytes);
			}
		} catch (error:Dynamic) {
			var message = Std.string(error);
			() -> failed(message);
		});
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void {
		if (!writable || !FilePath.isValid(path)) {
			refuse(failed, writable ? FilePath.INVALID : READ_ONLY);
			return;
		}
		var file = Path.join([directory, path]);
		run(() -> try {
			AtomicFile.write(file, bytes);
			written;
		} catch (error:Dynamic) {
			var message = Std.string(error);
			() -> failed(message);
		});
	}

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void {
		if (!writable || !FilePath.isValid(path)) {
			refuse(failed, writable ? FilePath.INVALID : READ_ONLY);
			return;
		}
		var file = Path.join([directory, path]);
		run(() -> try {
			if (sys.FileSystem.exists(file))
				sys.FileSystem.deleteFile(file);
			deleted;
		} catch (error:Dynamic) {
			var message = Std.string(error);
			() -> failed(message);
		});
	}

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void {
		if (!writable) {
			refuse(failed, READ_ONLY);
			return;
		}
		run(() -> try {
			if (sys.FileSystem.exists(directory))
				removeContents(directory);
			deleted;
		} catch (error:Dynamic) {
			var message = Std.string(error);
			() -> failed(message);
		});
	}

	// Deletes what dir holds, leaving dir itself.
	static function removeContents(dir:String):Void
		for (entry in sys.FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (sys.FileSystem.isDirectory(path)) {
				removeContents(path);
				sys.FileSystem.deleteDirectory(path);
			} else
				sys.FileSystem.deleteFile(path);
		}

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void {
		if (!FilePath.isValid(path)) {
			refuse(failed);
			return;
		}
		var file = Path.join([directory, path]);
		run(() -> try {
			sys.FileSystem.exists(file) ? () -> located(file, () -> {}) : missing;
		} catch (error:Dynamic) {
			var message = Std.string(error);
			() -> failed(message);
		});
	}

	public function poll():Void
		mailbox.deliver();

	/** Does nothing to close: a worker still running finishes on its own, and its answer is dropped. */
	public function dispose():Void {}
}
