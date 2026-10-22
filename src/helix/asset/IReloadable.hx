package helix.asset;

import haxe.io.Bytes;

/** Told when a subscribed asset's file changed and was loaded again (IAssets.subscribe). Called through the object, so after a hot reload its new code runs. */
interface IReloadable {
	/** path's file changed and loaded again as bytes, already in the cache; runs on the host thread. A throw is recorded as a failed reload. */
	function reloaded(path:String, bytes:Bytes):Void;
}
