package helix.platform;

import haxe.io.Bytes;

/** Defines HTTP GET requests, whose response body arrives in parts and which can be aborted. */
interface IHttp extends IPollable {
	/** Starts a GET request.

		The callbacks are called on the main thread, never during this call. `head` is called once, then `body` for each part of the body
		as it arrives, then one of `done` or `failed`. An HTTP error status is a response, not a failure. After an abort, nothing more is
		called.

		A request that receives nothing for `idleTimeout` seconds fails: while it connects, while it waits for the head, or between parts of
		the body. A server that keeps sending, however slowly, doesn't time out. Natively, looking up the server's name isn't timed: that is
		left to the system's resolver.

		`done` means the body is as long as its `Content-Length`, where the platform can tell. In a page it sometimes can't: see
		`FetchApiHttpAdapter`.

		A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body, as HTTP allows any server to
		do.
		@param url  The URL. In a page, a relative URL is relative to the page. Natively, only http and https URLs are allowed.
		@param noCache  Whether to bypass HTTP caches, where the platform has one.
		@param headers  The request's headers, names in any case.
		@param head  Receives the response's status and its headers, names in lower case.
		@param body  Receives each part of the body.
		@param done  Called when the body is all here.
		@param failed  Receives why the transfer failed.
		@param idleTimeout  Optional. How long, in seconds, the request may receive nothing before it fails; defaults to 30, and is clamped
			to 0.001 to 86400 (a day).
		@return  The abort, which stops the transfer where the platform can. */
	function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
		done:Void->Void, failed:String->Void, ?idleTimeout:Float):Void->Void;

	/** Delivers what arrived on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Aborts every transfer. */
	function dispose():Void;
}
