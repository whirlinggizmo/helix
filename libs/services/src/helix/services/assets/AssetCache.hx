package helix.services.assets;

import haxe.io.Bytes;

/** Decides whether a server's kept copy of a file is current, and keeps the copies. Construct one of its kinds. */
@:allow(helix.services.assets)
abstract class AssetCache {
	/** Whether downloads ask past the HTTP caches. */
	var pastHttpCaches = false;

	/** Whether copies are kept as files, located where they are kept; false holds them in memory. */
	var keepsFiles = true;

	/** Creates the cache, as one of its kinds. */
	function new() {}

	/** Decides what the server does for a path. */
	abstract function decide(server:ServerSource, path:String, request:AssetRequest, decided:CacheDecision->Void):Void;

	/** Reads the kept copy a record describes; gone is called, once the record and the bytes are deleted, when it isn't there whole. */
	abstract function readCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, gone:Void->Void):Void;

	/** Locates the kept copy a record describes; gone is called, once the record and the bytes are deleted, when it isn't there whole. */
	abstract function locateCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, located:(String, Void->Void) -> Void,
		gone:Void->Void, failed:String->Void):Void;

	/** Keeps a downloaded file with its record: the old record deleted first when replacing, then the bytes written, then the record. kept
		is called once the bytes are written, failed when they can't be. */
	abstract function keep(server:ServerSource, path:String, bytes:Bytes, record:CopyRecord, replacing:Bool, kept:Void->Void, failed:String->Void):Void;

	/** Writes a copy's record again, its copy unchanged (an answer of 304). */
	abstract function renew(server:ServerSource, path:String, record:CopyRecord):Void;

	/** Deletes a copy's record and then its bytes. */
	abstract function forget(server:ServerSource, path:String, forgotten:Void->Void, failed:String->Void):Void;

	/** Empties the copies, and forgets what this run holds. */
	abstract function clearCopies(server:ServerSource, cleared:Void->Void, failed:String->Void):Void;

	/** Tells whether downloaded bytes have the label they were downloaded for, at the request's next poll. A cache that doesn't label
		says yes.

		@param bytes  The download.
		@param label  The label it was downloaded for.
		@param request  Its request, which the answer waits on: aborted, nothing is called.
		@param verified  Receives whether they match. */
	function verify(bytes:Bytes, label:String, request:AssetRequest, verified:Bool->Void):Void
		request.later(() -> verified(true));
}
