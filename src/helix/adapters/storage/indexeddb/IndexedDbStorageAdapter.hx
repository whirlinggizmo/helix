package helix.adapters.storage.indexeddb;

import helix.assets.IStorage;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.assets.AssetPath;
import helix.core.WorkQueue;
import haxe.io.Bytes;

/** IndexedDB stores encoded Blobs. Audio receives a leased local Blob URL. */
class IndexedDbStorageAdapter implements IStorage {
	var queue = new WorkQueue();
	var db:Dynamic;
	var error:Null<String>;
	var ready = false;
	var live = true;
	var requests:Array<IRequest> = [];

	public function new(name:String) {
		try {
			var open = js.Browser.window.indexedDB.open(name, 1);
			open.onupgradeneeded = _ -> {
				db = open.result;
				db.createObjectStore("files");
			};
			open.onsuccess = _ -> {
				db = open.result;
				ready = true;
			};
			open.onerror = _ -> {
				error = Std.string(open.error);
				ready = true;
			};
		} catch (e:Dynamic) {
			error = Std.string(e);
			ready = true;
		}
	}

	function job<T>(key:String, mode:String, operation:Dynamic->Dynamic, decode:Dynamic->(T->Void)->Void, complete:T->Void, failed:String->T, cancelled:T,
			?discard:T->Void):IRequest {
		var request:Request = null;
		function finish(result:T) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			} else if (discard != null)
				discard(result);
		}
		request = new Request(() -> {
			requests.remove(request);
			queue.add(() -> complete(cancelled));
		});
		requests.push(request);
		var begin:Void->Void = null;
		begin = () -> {
			if (request.isSettled())
				return;
			if (!ready) {
				queue.add(begin);
				return;
			}
			if (!live || !AssetPath.valid(key)) {
				finish(failed("Invalid storage path or closed service"));
				return;
			}
			if (error != null) {
				finish(failed(error));
				return;
			}
			try {
				var tx:Dynamic = db.transaction(["files"], mode),
					task:Dynamic = operation(tx.objectStore("files")),
					value:Dynamic = null;
				task.onsuccess = _ -> value = task.result;
				tx.oncomplete = _ -> decode(value, finish);
				tx.onerror = _ -> finish(failed(Std.string(tx.error)));
				tx.onabort = _ -> finish(failed("Storage transaction aborted"));
			} catch (e:Dynamic) {
				finish(failed(Std.string(e)));
			}
		};
		queue.add(begin);
		return request;
	}

	public function read(key:String, complete:StorageResult->Void):IRequest
		return job(key, "readonly", store -> store.get(key), (value, finish:StorageResult->Void) -> {
			if (value == null)
				finish(Missing);
			else if (value.size > 8 * 1024 * 1024)
				finish(Failed("Stored file exceeds byte limit"));
			else
				value.arrayBuffer().then(data -> {
					finish(Stored(Bytes.ofData(data)));
					return null;
				}, e -> {
					finish(Failed(Std.string(e)));
					return null;
				});
		}, complete, message -> Failed(message), Cancelled);

	public function write(key:String, bytes:Bytes, complete:StorageWriteResult->Void):IRequest {
		var blob = new js.html.Blob([new js.lib.Uint8Array(bytes.getData(), 0, bytes.length)]);
		return job(key, "readwrite", store -> {
			if (bytes.length > 8 * 1024 * 1024)
				throw "Stored file exceeds byte limit";
			return store.put(blob, key);
		}, (_, finish) -> finish(Written), complete, message -> Failed(message),
			Cancelled);
	}

	public function remove(key:String, complete:StorageWriteResult->Void):IRequest
		return job(key, "readwrite", store -> store.delete(key), (_, finish) -> finish(Written), complete, message -> Failed(message), Cancelled);

	public function source(key:String, complete:StorageSourceResult->Void):IRequest
		return job(key, "readonly", store -> store.get(key), (value, finish:StorageSourceResult->Void) -> {
			if (value == null)
				finish(Missing);
			else {
				var url = js.html.URL.createObjectURL(value);
				finish(Local({location: url, release: () -> js.html.URL.revokeObjectURL(url)}));
			}
		}, complete,
			message -> StorageSourceResult.Failed(message), StorageSourceResult.Cancelled, result -> switch result {
				case Local(value): value.release();
				case _:
			});

	public function poll():Void
		queue.poll();

	public function shutdown():Void {
		live = false;
		for (request in requests.copy())
			request.cancel();
		queue.poll();
		if (db != null)
			db.close();
	}
}
