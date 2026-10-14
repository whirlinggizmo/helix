package helix.assets;

import haxe.io.Bytes;
import helix.assets.Storage.StorageResult;
import helix.assets.Storage.StorageSourceResult;
import helix.assets.Storage.StorageWriteResult;

/** Files kept by key on a platform (a directory, IndexedDB). Keys are valid asset paths (the shared Storage checks them); limits, read-only
	refusal, queuing and cancellation are the shared Storage's. Each answer arrives on the host thread, never during the call that asked, and
	is never Cancelled. */
interface IStore {
	/** The file under key: Stored, Missing, or Failed (an I/O error, or a file over maxBytes). */
	public function read(key:String, maxBytes:Int, done:StorageResult->Void):Void;

	/** Stores bytes under key, replacing what is there: Written or Failed. */
	public function write(key:String, bytes:Bytes, done:StorageWriteResult->Void):Void;

	/** Deletes the file under key (Written also when there was none), or Failed. */
	public function remove(key:String, done:StorageWriteResult->Void):Void;

	/** Removes every file: Written or Failed. */
	public function clear(done:StorageWriteResult->Void):Void;

	/** Leases the file under key for streaming without reading it (a file path natively, a Blob URL in a browser): Local, Missing or Failed. The
		lease's release, called once, ends it. */
	public function lease(key:String, done:StorageSourceResult->Void):Void;

	/** Delivers what arrived from the platform's threads since the last poll; the shared Storage calls it once a frame. */
	public function poll():Void;

	/** Closes the store. */
	public function shutdown():Void;
}
