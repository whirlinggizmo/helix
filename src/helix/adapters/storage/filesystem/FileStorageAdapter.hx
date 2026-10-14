package helix.adapters.storage.filesystem;

import haxe.io.Bytes;
import haxe.io.Path;
import helix.adapters.internal.Mailbox;
import helix.assets.IStore;
import helix.assets.Storage.StorageResult;
import helix.assets.Storage.StorageSourceResult;
import helix.assets.Storage.StorageWriteResult;
import sys.thread.Thread;

/** IStore natively: files under a root directory, a key as a relative path, each operation on a worker thread; a write goes to a sibling
	temporary file renamed over the old one, so a reader never sees half a file. A lease is the file's path, with nothing to release. */
class FileStorageAdapter implements IStore {
	var root:String;
	var mailbox = new Mailbox();
	var serial = 0;

	/** Files under root. */
	public function new(root:String)
		this.root = root;

	/** Where a program's cache goes on this desktop, for company and product: under $XDG_CACHE_HOME (or ~/.cache) on Linux, ~/Library/Caches on
		macOS, and %LOCALAPPDATA%\<company>\<product>\cache on Windows (that folder is the program's own, not only its cache). null when the
		user's directories aren't known. */
	public static function getCacheDirectory(company:String, product:String):Null<String> {
		var system = Sys.systemName();
		if (system == "Windows") {
			var local = Sys.getEnv("LOCALAPPDATA");
			return local == null || local == "" ? null : Path.join([local, company, product, "cache"]);
		}
		var home = Sys.getEnv("HOME");
		if (system == "Mac")
			return home == null || home == "" ? null : Path.join([home, "Library/Caches", company, product]);
		var xdg = Sys.getEnv("XDG_CACHE_HOME");
		var base = xdg != null && StringTools.startsWith(xdg, "/") ? xdg : home == null || home == "" ? null : Path.join([home, ".cache"]);
		return base == null ? null : Path.join([base, company, product]);
	}

	// Runs work on a worker thread and hands its result to done on the host thread.
	function run<T>(work:Void->T, done:T->Void):Void
		Thread.create(() -> {
			var result = work();
			mailbox.post(() -> done(result));
		});

	public function read(key:String, maxBytes:Int, done:StorageResult->Void):Void {
		var file = Path.join([root, key]);
		run(() -> try {
			if (!sys.FileSystem.exists(file))
				StorageResult.Missing;
			else if (sys.FileSystem.stat(file).size > maxBytes)
				StorageResult.Failed("Stored file exceeds byte limit");
			else
				StorageResult.Stored(sys.io.File.getBytes(file));
		} catch (error:Dynamic)
			StorageResult.Failed(Std.string(error)), done);
	}

	/** Creates dir and its parents. Writes run on several threads, and two may create the same directory at once: one that exists by the time
		creating it fails is fine. */
	static function makeDirectory(dir:String):Void
		try
			sys.FileSystem.createDirectory(dir)
		catch (error:Dynamic)
			if (!sys.FileSystem.exists(dir) || !sys.FileSystem.isDirectory(dir))
				throw error;

	public function write(key:String, bytes:Bytes, done:StorageWriteResult->Void):Void {
		var file = Path.join([root, key]), temp = file + ".part-" + (++serial);
		run(() -> try {
			makeDirectory(Path.directory(file));
			try {
				sys.io.File.saveBytes(temp, bytes);
				sys.FileSystem.rename(temp, file);
			} catch (error:Dynamic) {
				if (sys.FileSystem.exists(temp))
					sys.FileSystem.deleteFile(temp);
				throw error;
			}
			Written;
		} catch (error:Dynamic)
			StorageWriteResult.Failed(Std.string(error)), done);
	}

	public function remove(key:String, done:StorageWriteResult->Void):Void {
		var file = Path.join([root, key]);
		run(() -> try {
			if (sys.FileSystem.exists(file))
				sys.FileSystem.deleteFile(file);
			Written;
		} catch (error:Dynamic)
			StorageWriteResult.Failed(Std.string(error)), done);
	}

	public function clear(done:StorageWriteResult->Void):Void
		run(() -> try {
			if (sys.FileSystem.exists(root))
				removeContents(root);
			Written;
		} catch (error:Dynamic)
			StorageWriteResult.Failed(Std.string(error)), done);

	/** Deletes what dir holds, leaving dir itself. */
	static function removeContents(dir:String):Void
		for (entry in sys.FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (sys.FileSystem.isDirectory(path)) {
				removeContents(path);
				sys.FileSystem.deleteDirectory(path);
			} else
				sys.FileSystem.deleteFile(path);
		}

	public function lease(key:String, done:StorageSourceResult->Void):Void {
		var file = Path.join([root, key]);
		run(() -> try {
			if (!sys.FileSystem.exists(file))
				StorageSourceResult.Missing;
			else
				StorageSourceResult.Local({location: file, release: () -> {}});
		} catch (error:Dynamic)
			StorageSourceResult.Failed(Std.string(error)), done);
	}

	public function poll():Void
		mailbox.deliver();

	/** Nothing to close: a worker still running finishes on its own, and its answer is dropped. */
	public function shutdown():Void {}
}
