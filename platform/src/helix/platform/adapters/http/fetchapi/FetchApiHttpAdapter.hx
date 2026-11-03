package helix.platform.adapters.http.fetchapi;

import haxe.io.Bytes;
import helix.platform.IHttp;
import js.html.PerformanceResourceTiming;
import js.html.Response;

/** Provides `IHttp` in a page over `fetch`: the body read as it arrives, aborted through an `AbortController`.

	Conditional headers (`If-None-Match`, `If-Modified-Since`) to another origin would need a CORS preflight the server may refuse, so there
	they are left out and the browser revalidates its own copy instead (cache `no-cache`), answering 200.

	A body cut short of its `Content-Length` fails. Browsers fail most of those themselves, but not all: Chromium takes a connection closed
	partway through the head as a whole head and an empty body, and Firefox a compressed body cut short as a whole one. So a body that ends
	is checked against its `Content-Length`: by the bytes the browser's Resource Timing entry for the request says arrived, where the entry
	can be read (from the page's origin, or a server that sends `Timing-Allow-Origin`); or else by the bytes read, where the response is from
	the page's origin and isn't compressed. Where neither can be read, a response from another origin without `Timing-Allow-Origin`, `done`
	is called unchecked. A 204 or 304 answer has no body to check. A status below 100, which Chromium makes of a status line cut short,
	fails without `head`.

	A browser opens at most six connections to a server over HTTP/1.1 and queues the requests past them, so a request behind six others of
	this adapter's to the same origin isn't timed until one of them ends; requests the page makes otherwise aren't counted.

	The page's Resource Timing buffer is raised whenever it fills, so each request's entry is kept, until `dispose`. */
class FetchApiHttpAdapter implements IHttp {
	// How long a request may receive nothing, in seconds, when it isn't given: IHttp.get's default.
	static inline final IDLE_TIMEOUT = 30.;

	// The most connections a browser opens to one server at once over HTTP/1.1, queueing the requests past them.
	static inline final CONNECTIONS = 6;

	// Each request's abort, until it ends.
	var aborts:Array<Void->Void> = [];
	// Each origin's requests not yet ended, oldest first, each with whether its idle timeout runs and the call that starts it. A request
	// queued by the browser behind CONNECTIONS others isn't timed until one of them ends.
	var lines:Map<String, Array<{timed:Bool, time:Void->Void}>> = [];
	// Doubles the Resource Timing buffer when it fills: a full buffer drops each new entry.
	var grow:Dynamic->Void;

	/** Creates the adapter. */
	public function new() {
		var performance = js.Browser.window.performance;
		grow = _ -> performance.setResourceTimingBufferSize(performance.getEntriesByType("resource").length * 2);
		performance.addEventListener("resourcetimingbufferfull", grow);
	}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
			done:Void->Void, failed:String->Void, ?idleTimeout:Float):Void->Void {
		var controller = new js.html.AbortController(),
			stopped = false,
			timer:Null<Int> = null,
			timeout = idleTimeout == null ? IDLE_TIMEOUT : Math.min(Math.max(idleTimeout, 0.001), 86400),
			sent = new js.html.Headers(),
			cache = noCache ? js.html.RequestCache.NO_STORE : js.html.RequestCache.DEFAULT,
			name = new js.html.URL(url, js.Browser.location.href).href,
			origin = new js.html.URL(name).origin,
			foreign = origin != js.Browser.location.origin,
			line = lines[origin];
		var turn:{timed:Bool, time:Void->Void} = {timed: false, time: null};
		if (line == null)
			lines[origin] = line = [];
		for (name => value in headers) {
			var lower = name.toLowerCase();
			if (foreign && (lower == "if-none-match" || lower == "if-modified-since")) {
				if (!noCache)
					cache = js.html.RequestCache.NO_CACHE;
			} else
				sent.set(name, value);
		}
		var abort:Void->Void = null;
		function quiet():Void
			if (timer != null) {
				js.Browser.window.clearTimeout(timer);
				timer = null;
			}
		function stop():Bool {
			if (stopped)
				return false;
			stopped = true;
			quiet();
			aborts.remove(abort);
			line.remove(turn);
			if (line.length == 0)
				lines.remove(origin);
			for (i in 0...(line.length < CONNECTIONS ? line.length : CONNECTIONS))
				if (!line[i].timed)
					line[i].time();
			return true;
		}
		function fail(error:Dynamic):Dynamic {
			if (stop())
				failed(Std.string(error));
			return null;
		}
		// Starts the wait for the next thing to arrive again, failing the request when nothing does in time.
		function wait():Void {
			quiet();
			turn.timed = true;
			timer = js.Browser.window.setTimeout(() -> if (stop()) {
				controller.abort();
				failed('Nothing arrived from the server for $timeout ${timeout == 1 ? "second" : "seconds"}');
			}, timeout * 1000);
		}
		abort = () -> if (stop()) controller.abort();
		aborts.push(abort);
		turn.time = wait;
		line.push(turn);
		if (line.length <= CONNECTIONS)
			wait();
		// Every entry for this request starts no earlier than now; an earlier request to the same URL has an earlier one.
		var started = js.Browser.window.performance.now();
		js.Browser.window.fetch(url, {signal: controller.signal, cache: cache, headers: sent}).then(response -> {
			if (stopped)
				return null;
			// Chromium answers a status line cut short, "HTTP/1.1 20", as a response with status 20.
			if (response.status < 100) {
				controller.abort();
				return fail("The response doesn't start with an HTTP status line");
			}
			wait();
			var received:Map<String, String> = [];
			response.headers.forEach((value, name, _) -> received[name.toLowerCase()] = value);
			head(response.status, received);
			var reader:Dynamic = (cast response : Dynamic).body == null ? null : (cast response : Dynamic).body.getReader();
			var bytes = 0.;
			function end(whole:Bool):Void
				if (whole) {
					if (stop())
						done();
				} else
					fail("The connection closed before the body's Content-Length");
			if (reader == null) {
				quiet();
				check(response, bytes, name, started, false, end);
				return null;
			}
			var read:Void->Void = null;
			read = () -> reader.read().then(part -> {
				if (stopped)
					return null;
				if (part.done) {
					quiet();
					check(response, bytes, name, started, false, end);
				} else {
					wait();
					var chunk:js.lib.Uint8Array = cast part.value;
					bytes += chunk.byteLength;
					body(Bytes.ofData(chunk.buffer.slice(chunk.byteOffset, chunk.byteOffset + chunk.byteLength)));
					read();
				}
				return null;
			}, fail);
			read();
			return null;
		}, fail);
		return abort;
	}

	/** Does nothing: the page's callbacks already run on the main thread. */
	public function poll():Void {}

	public function dispose():Void {
		for (abort in aborts.copy())
			abort();
		js.Browser.window.performance.removeEventListener("resourcetimingbufferfull", grow);
	}

	// Calls whole with whether a body that ended, after bytes of it were read, was all there, as far as can be told: see the class's
	// remarks. Chromium adds a request's Resource Timing entry a task after its body ends, so with neither check to be made yet it looks
	// again once, retried, a task later.
	static function check(response:Response, bytes:Float, name:String, started:Float, retried:Bool, whole:Bool->Void):Void {
		var length = response.headers.get("content-length"),
			size = length == null ? Math.NaN : Std.parseFloat(length);
		if (Math.isNaN(size) || response.status == 204 || response.status == 304)
			return whole(true);
		var entry = timing(name, started);
		// An entry the page may not read holds zeros; one it may read has its head's bytes at least, in transferSize, but for a cached copy.
		if (entry != null && (entry.encodedBodySize > 0 || entry.transferSize > 0))
			return whole(entry.encodedBodySize >= size);
		// From another origin, a Content-Encoding the server doesn't expose reads as none.
		var encoding = response.headers.get("content-encoding");
		if (encoding == null ? response.type == js.html.ResponseType.BASIC : encoding.toLowerCase() == "identity")
			return whole(bytes >= size);
		if (entry == null && !retried)
			js.Browser.window.setTimeout(() -> check(response, bytes, name, started, true, whole), 0);
		else
			whole(true);
	}

	// The Resource Timing entry for a request to name that began at started: the first to start since.
	static function timing(name:String, started:Float):Null<PerformanceResourceTiming> {
		var found:PerformanceResourceTiming = null;
		for (entry in js.Browser.window.performance.getEntriesByName(name, "resource"))
			if (entry.startTime >= started && (found == null || entry.startTime < found.startTime))
				found = cast entry;
		return found;
	}
}
