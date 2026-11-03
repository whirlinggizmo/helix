package helix.services.assets;

import haxe.io.Bytes;

/** Keeps nothing between runs. Each file is downloaded once a run and held in memory. It is meant for development.

	Its downloads ask past the HTTP caches, so a run sees the server's files as they are now. */
class MemoryCache extends AssetCache {
	// This run's files, by server and path.
	final held = new Map<String, Bytes>();

	/** Creates the cache. */
	public function new() {
		super();
		pastHttpCaches = true;
		keepsFiles = false;
	}

	function decide(server:ServerSource, path:String, request:AssetRequest, decided:CacheDecision->Void):Void {
		var bytes = held.get(key(server, path));
		request.later(() -> decided(bytes != null ? Held(bytes) : Download(null, null, false)));
	}

	function readCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, gone:Void->Void):Void
		request.later(gone);

	function locateCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, located:(String, Void->Void) -> Void, gone:Void->Void,
			failed:String->Void):Void
		request.later(gone);

	function keep(server:ServerSource, path:String, bytes:Bytes, record:CopyRecord, replacing:Bool, kept:Void->Void, failed:String->Void):Void {
		held.set(key(server, path), bytes);
		kept();
	}

	function renew(server:ServerSource, path:String, record:CopyRecord):Void {}

	function forget(server:ServerSource, path:String, forgotten:Void->Void, failed:String->Void):Void {
		held.remove(key(server, path));
		forgotten();
	}

	function clearCopies(server:ServerSource, cleared:Void->Void, failed:String->Void):Void {
		for (k in [for (k in held.keys()) k])
			if (StringTools.startsWith(k, server.directory + "/"))
				held.remove(k);
		cleared();
	}

	static function key(server:ServerSource, path:String):String
		return server.directory + "/" + path;
}
