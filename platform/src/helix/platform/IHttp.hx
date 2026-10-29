package helix.platform;

import haxe.io.Bytes;

/** Defines HTTP GET: a response whose body arrives in parts, and its abort. */
interface IHttp extends IPollable {
	/** Starts a GET.

		On the main thread, never during this call: `head` once, `body` for each part of the body as it arrives, then one of `done` or
		`failed`. An HTTP error status is a response, not a failure. After an abort nothing more is called.

		A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body, as HTTP allows any server to.
		@param url  The URL: relative to the page in a page; natively http or https only.
		@param noCache  Whether to bypass HTTP caches, where the platform has one.
		@param headers  The request's headers, names in any case.
		@param head  Receives the response's status and its headers, names in lower case.
		@param body  Receives each part of the body.
		@param done  Called when the body is all here.
		@param failed  Receives why the transfer failed.
		@return The abort: it stops the transfer where the platform can. */
	function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
		done:Void->Void, failed:String->Void):Void->Void;

	/** Delivers what arrived on the platform's threads since the last poll; call once a frame. */
	function poll():Void;

	/** Aborts every transfer. */
	function dispose():Void;
}
