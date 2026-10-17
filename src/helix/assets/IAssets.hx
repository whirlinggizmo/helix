package helix.assets;

import haxe.io.Bytes;
import helix.assets.Storage.Lease;
import helix.assets.Storage.StorageWriteResult;

/** How an asset load ended: its bytes, a failure message, or cancellation. */
enum AssetResult {
	Loaded(bytes:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Where a streamed audio asset is read from: a leased local copy, which its holder releases, or a remote URL. */
enum AudioLocation {
	Stored(value:Lease);
	Remote(url:String);
}

/** How the cache treats a downloaded copy no manifest lists (IAssets.setCacheMode); a listed one follows its manifest in every mode, and
	ensure's forceFetch downloads past the cache in every mode.

	- Revalidate, the default: a copy fresh by the host's Cache-Control (max-age not passed, or immutable) is used with no request; any other
	  is asked about first: 304, the copy is used (and fresh again); 200, the new file replaces it; 4xx, the copy is deleted and the load
	  fails; no answer (offline, a timeout) or a 5xx, the copy is used. no-cache and no-store make a copy never fresh, but it's kept, for the
	  next check and for starting offline.
	- Trust: a copy is used without asking, however old: offline-first play, files that never change, or a game that evicts by itself.
	- Off: nothing is kept between runs, and what earlier runs kept is neither used nor deleted (development); this run's downloads are held
	  in memory, so a file loads once a run. */
enum AssetCacheMode {
	Revalidate;
	Trust;
	Off;
}

/** How locating a streamed asset ended: its location, a failure message, or cancellation. */
enum AssetSourceResult {
	Located(value:AudioLocation);
	Failed(message:String);
	Cancelled;
}

/** Load progress: phase ("locating", "downloading", "storing" or "ready"), bytes received, and total bytes, or null when unknown. */
typedef AssetProgress = {final phase:String; final receivedBytes:Int; final totalBytes:Null<Int>;}

/** How ensure finds a file. source: where its bytes come from instead of its own path, a path read against the host as a browser reads a URL
	against a directory, or a whole URL; they're kept under the path asked for, remembering where they came from: a later plain load of the path
	asks about the copy there, and it streams from there when it's stale, as the host has nothing at the path. forceFetch: go past the cache to the host (or the packaged files),
	replacing what the cache holds. */
typedef EnsureOptions = {
	@:optional final source:String;
	@:optional final forceFetch:Bool;
}

/** The asset service games load through (AssetService): assets by relative path through the cache, streamed audio locations, and hot reload subscriptions. Completions run on the host thread. */
interface IAssets {
	/** Loads path's bytes as ensure does, without progress or a way to cancel. */
	function load(path:String, complete:AssetResult->Void):Void;

	/** Loads path's bytes: downloaded from the host when one is set and kept in the cache, or else read from the packaged files in place. A
		cached copy is used only while it's current: when a manifest (setManifest) lists the file, while the copy has the manifest's hash (else
		the file is downloaded past HTTP caches and kept only if it has it); otherwise while the host's Cache-Control says it's fresh, and then
		after asking the host (its ETag and Last-Modified sent): 304 keeps it, 200 replaces it, 4xx deletes it, and no answer (offline, a 5xx)
		uses it. complete runs exactly once on the host thread; Failed for an invalid path, a closed service, a missing asset, an HTTP status
		outside 200-299 with no copy to use, a download that doesn't match its manifest, or a storage or transport error. progress, if given,
		reports each phase until the request settles. */
	function ensure(path:String, complete:AssetResult->Void, ?progress:AssetProgress->Void, ?options:EnsureOptions):IRequest;

	/** What's put before each path to download it, ending in "/": a URL, or a folder relative to the page (the browser's "assets/"); null when
		files are read from the program's packaged files (natively, unless HELIX_ASSET_HOST names a host). */
	function getHost():Null<String>;

	/** Downloads from host from now on (a "/" is added if it has none), or reads the packaged files with null. The cache keeps each host's files
		apart. False for an empty host. */
	function setHost(host:Null<String>):Bool;

	/** Whether host answers: it serves probePath (an asset it should have) within timeoutSeconds. complete runs once, on the host thread. */
	function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):IRequest;

	/** The root manifest's path under the host ("manifest.json"), or null for none (the default). */
	function getManifest():Null<String>;

	/** Uses the manifest tree under the host from path (tools/gen_manifest.py writes one): the root asked about once a run (its cached copy
		used offline), a directory's manifest loaded only when an asset under it is, and again only when its hash changes; a file it lists is
		used from the cache with no request while the copy has its hash. A host without one, and a file none lists, are treated as the cache mode
		says (setCacheMode); a file its directory's manifest leaves out is asked about however fresh, as it has changed or gone. Null for none. False for a path that isn't a valid asset path. */
	function setManifest(path:Null<String>):Bool;

	/** How downloaded copies no manifest lists are treated (AssetCacheMode); Revalidate by default. */
	function getCacheMode():AssetCacheMode;

	/** Treats every copy checked from now on as mode says. */
	function setCacheMode(mode:AssetCacheMode):Void;

	/** Forgets every downloaded file, so the next load downloads it again, and what was read of the manifests, so the root is asked about
		again. complete runs once, on the host thread. */
	function clearCache(complete:StorageWriteResult->Void):IRequest;

	/** Locates path for streaming without loading it whole: a leased cached copy while it's current (as ensure says, without asking the host),
		else the remote URL (a base URL is set) or a leased packaged copy. complete runs exactly once on the host thread; the caller releases a Located(Stored) lease, and one that arrives after cancellation is released for it. Failed for an invalid path, a closed service, a missing packaged asset, or a storage error. */
	function streamSource(path:String, complete:AssetSourceResult->Void):IRequest;

	/** Tell target when path's file changes and has loaded again (development hot reload). One target per path once. */
	function subscribe(path:String, target:IReloadable):Void;

	/** Stops telling target about path's changes; does nothing if it was not subscribed. */
	function unsubscribe(path:String, target:IReloadable):Void;

	/** Whether a load is under way or its completion not yet run (Services.isBusy asks it, with the decoders). */
	function isBusy():Bool;
}
