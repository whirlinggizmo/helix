import haxe.io.Bytes;
import helix.platform.IHttp;

/** One response FakeHttp gives for a URL. */
typedef FakeResponse = {
	status:Int,
	?headers:Map<String, String>,
	?body:Bytes,
	?respond:Map<String, String>->Null<FakeResponse>,
	?ignoresRange:Bool
}

/** Stands in for HTTP in the services' tests: responses by URL, each answered at the next `poll` (its body in two parts), the requests
	kept, and the network turned off by the test.

	A 200 response takes a `Range` header of one range (`bytes=-N`, `bytes=A-B`, `bytes=A-`), answering 206 with that part of its body
	and a `Content-Range`, or 416 when none of the body is in it, unless it `ignoresRange`. An `If-Range` that isn't the response's ETag
	or Last-Modified gets the whole body. The bytes it has sent are counted. */
class FakeHttp implements IHttp {
	/** Gets the responses by URL; a URL with none answers 404. */
	public final routes = new Map<String, FakeResponse>();

	/** Gets every request made: its URL and headers. */
	public final requests:Array<{url:String, headers:Map<String, String>}> = [];

	/** Gets the body bytes sent so far. */
	public var bytesSent(default, null) = 0;

	/** Gets or sets whether every request fails, as offline. */
	public var offline = false;

	final queued:Array<Void->Void> = [];

	/** Creates one with no routes. */
	public function new() {}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
			done:Void->Void, failed:String->Void):Void->Void {
		requests.push({url: url, headers: headers});
		var aborted = false;
		queued.push(() -> {
			if (aborted)
				return;
			if (offline) {
				failed("offline");
				return;
			}
			var response = routes.get(url);
			if (response != null && response.respond != null)
				response = response.respond(headers);
			if (response == null)
				response = {status: 404};
			var bytes = response.body == null ? Bytes.alloc(0) : response.body;
			var sent = response.headers == null ? new Map<String, String>() : response.headers.copy();
			var status = response.status;
			var range = header(headers, "range"),
				ifRange = header(headers, "if-range");
			var current = ifRange == null || ifRange == sent.get("etag") || ifRange == sent.get("last-modified");
			if (status == 200 && range != null && response.ignoresRange != true && current) {
				var parsed = ~/^bytes=(\d*)-(\d*)$/;
				if (parsed.match(range)) {
					var total = bytes.length, first = 0, last = total - 1;
					if (parsed.matched(1) == "")
						first = total - Std.parseInt(parsed.matched(2));
					else {
						first = Std.parseInt(parsed.matched(1));
						if (parsed.matched(2) != "")
							last = Std.parseInt(parsed.matched(2));
					}
					if (first < 0)
						first = 0;
					if (last > total - 1)
						last = total - 1;
					if (first > last || first >= total) {
						status = 416;
						sent.set("content-range", 'bytes */$total');
						bytes = Bytes.alloc(0);
					} else {
						status = 206;
						sent.set("content-range", 'bytes $first-$last/$total');
						bytes = bytes.sub(first, last - first + 1);
					}
				}
			}
			sent.set("content-length", Std.string(bytes.length));
			bytesSent += bytes.length;
			head(status, sent);
			var half = bytes.length >> 1;
			if (half > 0)
				body(bytes.sub(0, half));
			if (bytes.length - half > 0)
				body(bytes.sub(half, bytes.length - half));
			done();
		});
		return () -> aborted = true;
	}

	// A request header, its name in any case.
	static function header(headers:Map<String, String>, name:String):Null<String> {
		for (key => value in headers)
			if (key.toLowerCase() == name)
				return value;
		return null;
	}

	/** Gets a value indicating whether a request waits for the next poll. */
	public var busy(get, never):Bool;

	function get_busy():Bool
		return queued.length > 0;

	public function poll():Void {
		var due = queued.splice(0, queued.length);
		for (f in due)
			f();
	}

	public function dispose():Void {}
}
