package helix.platform.adapters.filesystem.browser;

import haxe.io.Bytes;
import helix.platform.IFileSystem;
import helix.platform.adapters.shared.FilePath;

/** Provides `IFileSystem` in a page: Blobs in an IndexedDB database, a located file a Blob's URL, released by revoking it.

	Operations asked before the database opens wait for it. */
class BrowserFileSystemAdapter implements IFileSystem {
	var name:String;
	var db:Dynamic;
	var error:Null<String>;
	var ready = false;
	var waiting:Array<Void->Void> = [];

	/** Opens an IndexedDB database, creating it if needed; operations fail if it can't open.

		@param name  The database's name. */
	public function new(name:String) {
		this.name = name;
		function opened():Void {
			ready = true;
			for (w in waiting)
				w();
			waiting = [];
		}
		try {
			var open = js.Browser.window.indexedDB.open(name, 1);
			open.onupgradeneeded = _ -> {
				db = open.result;
				db.createObjectStore("files");
			};
			open.onsuccess = _ -> {
				db = open.result;
				opened();
			};
			open.onerror = _ -> {
				error = Std.string(open.error);
				opened();
			};
		} catch (e:Dynamic) {
			error = Std.string(e);
			ready = true;
		}
	}

	public var root(get, never):String;

	function get_root():String
		return name;

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return true;

	// Runs operation in a transaction of mode once the database is open, then answers with its value; failed for a failure, or an invalid
	// path when one is given. Never answers during the call, nor after the abort it returns.
	function transact(path:Null<String>, mode:String, operation:Dynamic->Dynamic, answer:Dynamic->Void, failed:String->Void):Void->Void {
		var aborted = false;
		function fail(message:String):Void
			if (!aborted)
				failed(message);
		function begin():Void {
			if (aborted)
				return;
			if (error != null || path != null && !FilePath.isValid(path)) {
				var message = error != null ? error : FilePath.INVALID;
				js.Browser.window.setTimeout(() -> fail(message), 0);
				return;
			}
			try {
				var tx:Dynamic = db.transaction(["files"], mode),
					task:Dynamic = operation(tx.objectStore("files")),
					value:Dynamic = null;
				task.onsuccess = _ -> value = task.result;
				tx.oncomplete = _ -> if (!aborted) answer(value);
				tx.onerror = _ -> fail(Std.string(tx.error));
				tx.onabort = _ -> fail("Transaction aborted");
			} catch (e:Dynamic) {
				var message = Std.string(e);
				js.Browser.window.setTimeout(() -> fail(message), 0);
			}
		}
		if (ready)
			begin();
		else
			waiting.push(begin);
		return () -> aborted = true;
	}

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		var aborted = false;
		var abort = transact(path, "readonly", files -> files.get(path), value -> {
			if (value == null)
				missing();
			else if (value.size > maxBytes)
				failed("File exceeds byte limit");
			else
				value.arrayBuffer().then(data -> {
					if (!aborted)
						loaded(Bytes.ofData(data));
					return null;
				}, e -> {
					if (!aborted)
						failed(Std.string(e));
					return null;
				});
		}, failed);
		return () -> {
			aborted = true;
			abort();
		};
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void {
		var blob = new js.html.Blob([new js.lib.Uint8Array(bytes.getData(), 0, bytes.length)]);
		transact(path, "readwrite", files -> files.put(blob, path), _ -> written(), failed);
	}

	public function remove(path:String, removed:Void->Void, failed:String->Void):Void
		transact(path, "readwrite", files -> files.delete(path), _ -> removed(), failed);

	public function clear(cleared:Void->Void, failed:String->Void):Void
		transact(null, "readwrite", files -> files.clear(), _ -> cleared(), failed);

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		transact(path, "readonly", files -> files.get(path), value -> {
			if (value == null)
				missing();
			else {
				var url = js.html.URL.createObjectURL(value);
				located(url, () -> js.html.URL.revokeObjectURL(url));
			}
		}, failed);

	/** Does nothing: IndexedDB's callbacks already run on the main thread. */
	public function poll():Void {}

	public function dispose():Void
		if (db != null)
			db.close();
}
