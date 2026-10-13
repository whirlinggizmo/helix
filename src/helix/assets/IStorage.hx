package helix.assets;

import haxe.io.Bytes;

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
typedef LocalAudio = {var location:String; var release:Void->Void;}

/** How leasing a stored file ended: the lease, Missing, a failure message, or cancellation. */
enum StorageSourceResult {
	Local(value:LocalAudio);
	Missing;
	Failed(message:String);
	Cancelled;
}

/** App cache; local audio leases avoid a second network transfer. */
interface IStorage {
	/** Reads the whole file stored under key (an AssetPath). Failed for an invalid key, a file over 8 MiB, a closed store, or an I/O error. */
	function read(path:String, complete:StorageResult->Void):IRequest;

	/** Stores a copy of bytes under key, replacing what is there. Failed for an invalid key, more than 8 MiB, read-only storage, a closed store, or an I/O error. */
	function write(path:String, bytes:Bytes, complete:StorageWriteResult->Void):IRequest;

	/** Deletes the file under key; Written also when there was none. Failed for an invalid key, read-only storage, a closed store, or an I/O error. */
	function remove(path:String, complete:StorageWriteResult->Void):IRequest;

	/** Leases the file under key for streaming without reading it; the caller releases a Local lease, and one that arrives after cancellation is released for it. Failed for an invalid key, a closed store, or an I/O error. */
	function source(path:String, complete:StorageSourceResult->Void):IRequest;

	/** Starts queued operations and runs completions on the host thread. Call once per frame. */
	function poll():Void;

	/** Cancels every pending operation (each completes Cancelled), refuses later ones and closes the store. */
	function shutdown():Void;
}
