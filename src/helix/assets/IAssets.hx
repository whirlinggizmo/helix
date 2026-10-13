package helix.assets;

import haxe.io.Bytes;
import helix.assets.IStorage.LocalAudio;
import helix.assets.IStorage.StorageWriteResult;

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

/** How ensure finds a file. source: where its bytes come from instead of its own path, a path read against the host as a browser reads a URL
	against a directory, or a whole URL; they're kept under the path asked for. forceFetch: go past the cache to the host (or the packaged files),
	replacing what the cache holds. */
typedef EnsureOptions = {
	@:optional var source:String;
	@:optional var forceFetch:Bool;
}

/** The asset service games load through (AssetService): assets by relative path through the cache, streamed audio locations, and hot reload subscriptions. Completions run on the host thread. */
interface IAssets {
	/** Loads path's bytes as ensure does, without progress or a way to cancel. */
	function load(path:String, complete:AssetResult->Void):Void;

	/** Loads path's bytes from the cache, or else downloads them (a host is set) and caches them, or reads them from the packaged files in place. complete runs exactly once on the host thread; Failed for an invalid path, a closed service, a missing asset, an HTTP status outside 200-299, or a storage or transport error. progress, if given, reports each phase until the request settles. */
	function ensure(path:String, complete:AssetResult->Void, ?progress:AssetProgress->Void, ?options:EnsureOptions):IRequest;

	/** What's put before each path to download it, ending in "/": a URL, or a folder relative to the page (the browser's "assets/"); null when
		files are read from the program's packaged files (natively, unless HELIX_ASSET_HOST names a host). */
	function getHost():Null<String>;

	/** Downloads from host from now on (a "/" is added if it has none), or reads the packaged files with null. The cache keeps each host's files
		apart. False for an empty host. */
	function setHost(host:Null<String>):Bool;

	/** Whether host answers: it serves probePath (an asset it should have) within timeoutSeconds. complete runs once, on the host thread. */
	function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):IRequest;

	/** Forgets every downloaded file, so the next load downloads it again. complete runs once, on the host thread. */
	function clearCache(complete:StorageWriteResult->Void):IRequest;

	/** Locates path for streaming without loading it whole: a leased cached copy, else the remote URL (a base URL is set) or a leased packaged copy. complete runs exactly once on the host thread; the caller releases a Located(Stored) lease, and one that arrives after cancellation is released for it. Failed for an invalid path, a closed service, a missing packaged asset, or a storage error. */
	function streamSource(path:String, complete:AssetSourceResult->Void):IRequest;

	/** Tell target when path's file changes and has loaded again (development hot reload). One target per path once. */
	function subscribe(path:String, target:IReloadable):Void;

	/** Stops telling target about path's changes; does nothing if it was not subscribed. */
	function unsubscribe(path:String, target:IReloadable):Void;
}
