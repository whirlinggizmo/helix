package helix.assets;

import haxe.io.Bytes;
import helix.assets.IStorage.LocalAudio;

/** How an asset load ended: its bytes, a failure message, or cancellation. */
enum AssetResult {
	Loaded(bytes:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Where a streamed audio asset is read from: a leased local copy, which its holder releases, or a remote URL. */
enum AudioLocation {
	Stored(value:LocalAudio);
	Remote(url:String);
}

/** How locating a streamed asset ended: its location, a failure message, or cancellation. */
enum AssetSourceResult {
	Located(value:AudioLocation);
	Failed(message:String);
	Cancelled;
}

/** Load progress: phase ("locating", "downloading", "storing" or "ready"), bytes received, and total bytes, or null when unknown. */
typedef AssetProgress = {var phase:String; var received:Int; var total:Null<Int>;}

/** The asset service games load through (AssetService): assets by relative path through the cache, streamed audio locations, and hot reload subscriptions. Completions run on the host thread. */
interface IAssets {
	/** Loads path's bytes as ensure does, without progress or a way to cancel. */
	function load(path:String, complete:AssetResult->Void):Void;

	/** Loads path's bytes from the cache, or else downloads them (a base URL is set) or reads them from the packaged store, and caches them before completing. complete runs exactly once on the host thread; Failed for an invalid path, a closed service, a missing asset, an HTTP status outside 200-299, or a storage or transport error. progress, if given, reports each phase until the request settles. */
	function ensure(path:String, complete:AssetResult->Void, ?progress:AssetProgress->Void):IRequest;

	/** Locates path for streaming without loading it whole: a leased cached copy, else the remote URL (a base URL is set) or a leased packaged copy. complete runs exactly once on the host thread; the caller releases a Located(Stored) lease, and one that arrives after cancellation is released for it. Failed for an invalid path, a closed service, a missing packaged asset, or a storage error. */
	function streamSource(path:String, complete:AssetSourceResult->Void):IRequest;

	/** Tell target when path's file changes and has loaded again (development hot reload). One target per path once. */
	function subscribe(path:String, target:IReloadable):Void;

	/** Stops telling target about path's changes; does nothing if it was not subscribed. */
	function unsubscribe(path:String, target:IReloadable):Void;
}
