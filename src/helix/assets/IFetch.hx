package helix.assets;

import haxe.io.Bytes;

/** A GET of url: maxBytes limits the body (default 8 MiB), timeoutSeconds bounds it (default 15), noCache bypasses HTTP caches (default false). */
typedef FetchRequest = {var url:String; @:optional var maxBytes:Int; @:optional var timeoutSeconds:Float; @:optional var noCache:Bool;}

/** Body bytes received so far, and the total from Content-Length, or null when unknown. */
typedef FetchProgress = {var received:Int; var total:Null<Int>;}

/** A complete response: HTTP status, headers with lower-case names, and the whole body. */
typedef FetchResponse = {var status:Int; var headers:Map<String, String>; var bytes:Bytes;}

/** How a fetch ended: a response of any HTTP status, a transport failure message, or cancellation. */
enum FetchResult {
	Response(value:FetchResponse);
	Failed(message:String);
	Cancelled;
}

/** Bounded whole-response GET, incrementally read. Progress/completion on host thread.
	HTTP error status is a response, not a transport failure. */
interface IFetch {
	/** Queues a GET; at most two run at once, started from poll. complete runs exactly once on the host thread; Failed for a maxBytes or timeoutSeconds not above 0, a closed adapter, a body over maxBytes, a timeout, or a network error. progress, if given, runs on the host thread, coalesced between polls. */
	function fetch(request:FetchRequest, complete:FetchResult->Void, ?progress:FetchProgress->Void):IRequest;

	/** Starts queued fetches and runs progress and completions on the host thread. Call once per frame. */
	function poll():Void;

	/** Cancels every pending fetch (each completes Cancelled) and refuses later ones. */
	function shutdown():Void;
}
