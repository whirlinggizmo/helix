package helix.asset;

import haxe.io.Bytes;

/** HTTP GET on a platform: a response arriving in parts. Limits, timeouts, progress and queuing are the shared FetchService's. */
@:noCompletion
interface IHttp {
	/** Starts a GET of url (relative to the page in a browser; http or https natively) with the request headers given (names in any case),
		bypassing HTTP caches when noCache (where the platform can). On the host thread, never during this call: head once (the HTTP status, and the headers with lower-case names), body for each part
		of the body as it arrives, then end once (null when the body is all here, else why the transfer failed). An HTTP error status is a
		response, not a failure. Returns abort: it stops the transfer where the platform can, and nothing is called after. */
	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(Int, Map<String, String>) -> Void, body:Bytes->Void,
		end:Null<String>->Void):Void->Void;

	/** Delivers what arrived from the platform's threads since the last poll; the shared FetchService calls it once a frame. */
	public function poll():Void;

	/** Aborts every transfer. */
	public function shutdown():Void;
}
