package helix.asset;

import haxe.io.Bytes;
import helix.core.Jobs;

/** How a read ended: the stored bytes, Missing, a failure message, or cancellation. */
enum StorageResult {
	Stored(bytes:Bytes);
	Missing;
	Failed(message:String);
	Cancelled;
}

/** How a write or remove ended: Written, a failure message, or cancellation. */
enum StorageWriteResult {
	Written;
	Failed(message:String);
	Cancelled;
}

/** A lease on a stored file for streaming: location is a file path or URL the audio adapter opens, and release, called once, ends the lease. */
typedef Lease = {final location:String; final release:Void->Void;}

/** How leasing a stored file ended: the lease, Missing, a failure message, or cancellation. */
enum StorageSourceResult {
	Local(value:Lease);
	Missing;
	Failed(message:String);
	Cancelled;
}

/** Files by key (an asset path) over a platform's IStore, the same on every platform: keys checked, files at most 8 MiB, a read-only store
	refusing writes, at most two operations at once (or as many as it's made with), each completing exactly once on the host thread. The app's cache, and the packaged assets
	read-only: the runner's cache is what the Storage static forwards to. */
@:build(helix.macro.Facade.record())
@:noCompletion
class StorageService {
	/** The largest file it stores or reads, in bytes. */
	public static inline var MAX_BYTES = 8 * 1024 * 1024;

	var store:IStore;
	var readOnly:Bool;
	var jobs:Jobs;

	/** Files in store; readOnly refuses write, remove and clear (packaged assets); at most maxActive operations at once (1: each in turn,
		so they complete in the order asked). */
	public function new(store:IStore, readOnly = false, maxActive = 2) {
		this.store = store;
		this.readOnly = readOnly;
		jobs = new Jobs(maxActive);
	}

	/** Reads the whole file under key. Failed for an invalid key, a file over 8 MiB, a closed store, or an I/O error. */
	public function read(key:String, complete:StorageResult->Void):IRequest
		return jobs.add((job:Job<StorageResult>) -> {
			if (!AssetPath.isValid(key))
				job.finish(Failed("Invalid storage key"));
			else
				store.read(key, MAX_BYTES, result -> job.finish(result));
		}, complete, StorageResult.Cancelled, StorageResult.Failed("Closed storage"));

	/** Stores a copy of bytes under key, replacing what is there. Failed for an invalid key, more than 8 MiB, a read-only store, a closed store,
		or an I/O error. */
	public function write(key:String, bytes:Bytes, complete:StorageWriteResult->Void):IRequest {
		var copy = bytes.sub(0, bytes.length);
		return jobs.add((job:Job<StorageWriteResult>) -> {
			if (!AssetPath.isValid(key))
				job.finish(Failed("Invalid storage key"));
			else if (readOnly)
				job.finish(Failed("Read-only storage"));
			else if (copy.length > MAX_BYTES)
				job.finish(Failed("Stored file exceeds byte limit"));
			else
				store.write(key, copy, result -> job.finish(result));
		}, complete, StorageWriteResult.Cancelled,
			StorageWriteResult.Failed("Closed storage"));
	}

	/** Deletes the file under key; Written also when there was none. Failed for an invalid key, a read-only store, a closed store, or an I/O error. */
	public function remove(key:String, complete:StorageWriteResult->Void):IRequest
		return jobs.add((job:Job<StorageWriteResult>) -> {
			if (!AssetPath.isValid(key))
				job.finish(Failed("Invalid storage key"));
			else if (readOnly)
				job.finish(Failed("Read-only storage"));
			else
				store.remove(key, result -> job.finish(result));
		}, complete, StorageWriteResult.Cancelled,
			StorageWriteResult.Failed("Closed storage"));

	/** Leases the file under key for streaming without reading it; the caller releases a Local lease, and one that arrives after cancellation is
		released for it. Failed for an invalid key, a closed store, or an I/O error. */
	public function source(key:String, complete:StorageSourceResult->Void):IRequest
		return jobs.add((job:Job<StorageSourceResult>) -> {
			if (!AssetPath.isValid(key)) {
				job.finish(Failed("Invalid storage key"));
				return;
			}
			store.lease(key, result -> if (job.settled) switch result {
				case Local(lease): lease.release();
				case _:
			} else job.finish(result));
		}, complete, StorageSourceResult.Cancelled,
			StorageSourceResult.Failed("Closed storage"));

	/** Removes every stored file; Failed for a read-only store. */
	public function clear(complete:StorageWriteResult->Void):IRequest
		return jobs.add((job:Job<StorageWriteResult>) -> {
			if (readOnly)
				job.finish(Failed("Read-only storage"));
			else
				store.clear(result -> job.finish(result));
		}, complete, StorageWriteResult.Cancelled,
			StorageWriteResult.Failed("Closed storage"));

	/** Delivers what arrived, starts queued operations and runs completions. Call once per frame. */
	public function poll():Void {
		store.poll();
		jobs.poll();
	}

	/** Cancels every pending operation (each completes Cancelled), refuses later ones and closes the store. */
	public function shutdown():Void {
		jobs.shutdown();
		store.shutdown();
	}
}
