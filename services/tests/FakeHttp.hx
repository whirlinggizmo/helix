import haxe.io.Bytes;
import helix.platform.IHttp;

/** One response FakeHttp gives for a URL. */
typedef FakeResponse = {
	status:Int,
	?headers:Map<String, String>,
	?body:Bytes,
	?respond:Map<String, String>->Null<FakeResponse>
}

/** Stands in for HTTP in the services' tests: responses by URL, each answered at the next `poll` (its body in two parts), the requests
	kept, and the network turned off by the test. */
class FakeHttp implements IHttp {
	/** Gets the responses by URL; a URL with none answers 404. */
	public final routes = new Map<String, FakeResponse>();

	/** Gets every request made: its URL and headers. */
	public final requests:Array<{url:String, headers:Map<String, String>}> = [];

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
			sent.set("content-length", Std.string(bytes.length));
			head(response.status, sent);
			var half = bytes.length >> 1;
			if (half > 0)
				body(bytes.sub(0, half));
			if (bytes.length - half > 0)
				body(bytes.sub(half, bytes.length - half));
			done();
		});
		return () -> aborted = true;
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
