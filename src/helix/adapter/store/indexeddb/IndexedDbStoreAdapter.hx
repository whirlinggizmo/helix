package helix.adapter.store.indexeddb;

import haxe.io.Bytes;
import helix.asset.IStore;
import helix.asset.StorageResult;
import helix.asset.StorageSourceResult;
import helix.asset.StorageWriteResult;

/** IStore in a browser: Blobs in an IndexedDB database, a lease a Blob URL (released by revoking it). Operations asked before the database
	opens wait for it. */
@:noCompletion
class IndexedDbStoreAdapter implements IStore {
	var db:Dynamic;
	var error:Null<String>;
	var ready = false;
	var waiting:Array<Void->Void> = [];

	/** Opens the IndexedDB database name, creating it if needed; operations fail if it can't open. */
	public function new(name:String) {
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

	// Runs operation in a transaction of mode once the database is open, then decode with its value; failed for a failure. Never answers during
	// the call.
	function transact<T>(mode:String, operation:Dynamic->Dynamic, decode:Dynamic->(T->Void)->Void, failed:String->T, done:T->Void):Void {
		function begin():Void {
			if (error != null) {
				var message = error;
				js.Browser.window.setTimeout(() -> done(failed(message)), 0);
				return;
			}
			try {
				var tx:Dynamic = db.transaction(["files"], mode),
					task:Dynamic = operation(tx.objectStore("files")),
					value:Dynamic = null;
				task.onsuccess = _ -> value = task.result;
				tx.oncomplete = _ -> decode(value, done);
				tx.onerror = _ -> done(failed(Std.string(tx.error)));
				tx.onabort = _ -> done(failed("Storage transaction aborted"));
			} catch (e:Dynamic) {
				var message = Std.string(e);
				js.Browser.window.setTimeout(() -> done(failed(message)), 0);
			}
		}
		if (ready)
			begin();
		else
			waiting.push(begin);
	}

	public function read(key:String, maxBytes:Int, done:StorageResult->Void):Void
		transact("readonly", store -> store.get(key), (value, finish:StorageResult->Void) -> {
			if (value == null)
				finish(Missing);
			else if (value.size > maxBytes)
				finish(Failed("Stored file exceeds byte limit"));
			else
				value.arrayBuffer().then(data -> {
					finish(Stored(Bytes.ofData(data)));
					return null;
				}, e -> {
					finish(Failed(Std.string(e)));
					return null;
				});
		}, message -> Failed(message), done);

	public function write(key:String, bytes:Bytes, done:StorageWriteResult->Void):Void {
		var blob = new js.html.Blob([new js.lib.Uint8Array(bytes.getData(), 0, bytes.length)]);
		transact("readwrite", store -> store.put(blob, key), (_, finish) -> finish(Written), message -> Failed(message), done);
	}

	public function remove(key:String, done:StorageWriteResult->Void):Void
		transact("readwrite", store -> store.delete(key), (_, finish) -> finish(Written), message -> Failed(message), done);

	public function clear(done:StorageWriteResult->Void):Void
		transact("readwrite", store -> store.clear(), (_, finish) -> finish(Written), message -> Failed(message), done);

	public function lease(key:String, done:StorageSourceResult->Void):Void
		transact("readonly", store -> store.get(key), (value, finish:StorageSourceResult->Void) -> {
			if (value == null)
				finish(Missing);
			else {
				var url = js.html.URL.createObjectURL(value);
				finish(Local({location: url, release: () -> js.html.URL.revokeObjectURL(url)}));
			}
		}, message -> StorageSourceResult.Failed(message), done);

	/** Nothing to deliver: IndexedDB's callbacks already run on the host thread. */
	public function poll():Void {}

	public function shutdown():Void
		if (db != null)
			db.close();
}
