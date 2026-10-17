package helix.assets;

import haxe.io.Bytes;
import helix.core.Jobs;

/** A GET of url: maxBytes limits the body (default 8 MiB), timeoutSeconds bounds the whole transfer (default 15), noCache bypasses HTTP caches
	(default false), headers are sent with it (none by default). */
typedef FetchRequest = {
	final url:String;
	@:optional final maxBytes:Int;
	@:optional final timeoutSeconds:Float;
	@:optional final noCache:Bool;
	@:optional final headers:Map<String, String>;
}

/** Body bytes received so far, and the total from Content-Length, or null when unknown (or the body is compressed). */
typedef FetchProgress = {final receivedBytes:Int; final totalBytes:Null<Int>;}

/** A complete response: HTTP status, headers with lower-case names, and the whole body. */
typedef FetchResponse = {final status:Int; final headers:Map<String, String>; final bytes:Bytes;}

/** How a fetch ended: a response of any HTTP status, a transport failure message, or cancellation. */
enum FetchResult {
	Response(value:FetchResponse);
	Failed(message:String);
	Cancelled;
}

/** Bounded whole-response GETs over a platform's IHttp, the same on every platform: at most two at once, each body limited and the whole transfer
	timed, progress coalesced to once a frame, completions on the host thread. The runner's is what the Fetch static forwards to. */
@:build(helix.macro.Facade.record())
class FetchService {
	static inline var DEFAULT_MAX = 8 * 1024 * 1024;
	static inline var DEFAULT_TIMEOUT = 15.;

	var http:IHttp;
	var jobs = new Jobs(2);
	// The running fetches' timeouts and failures: each its job, its time limit, and what failing it does.
	var timers:Array<{job:Job<FetchResult>, seconds:Float, fail:String->Void}> = [];

	/** Fetches over http. */
	public function new(http:IHttp)
		this.http = http;

	/** Queues a GET of request.url. complete runs exactly once on the host thread; Failed for a maxBytes or timeoutSeconds not above 0, a closed
		service, a body over maxBytes, a timeout, or a transport failure. progress, if given, runs on the host thread at most once a frame. */
	public function fetch(request:FetchRequest, complete:FetchResult->Void, ?progress:FetchProgress->Void):IRequest {
		var limit = request.maxBytes == null ? DEFAULT_MAX : request.maxBytes,
			timeout = request.timeoutSeconds == null ? DEFAULT_TIMEOUT : request.timeoutSeconds;
		return jobs.add(job -> {
			if (limit <= 0 || !Math.isFinite(timeout) || timeout <= 0) {
				job.finish(Failed("Invalid fetch request"));
				return;
			}
			var status = 0, headers:Map<String, String> = [], total:Null<Int> = null, received = 0, reported = -1, buffer = new haxe.io.BytesBuffer(),
				abort:Void->Void = null, timer = null;
			function settle(result:FetchResult):Void {
				timers.remove(timer);
				job.finish(result);
			}
			function fail(message:String):Void {
				if (job.settled)
					return;
				if (abort != null)
					abort();
				settle(Failed(message));
			}
			timer = {job: job, seconds: timeout, fail: fail};
			timers.push(timer);
			abort = http.get(request.url, request.noCache == true, request.headers == null ? [] : request.headers, (code, names) -> {
				status = code;
				headers = names;
				// A compressed body's length isn't what arrives.
				total = headers.exists("content-encoding") ? null : Std.parseInt(headers["content-length"]);
			}, part -> {
				if (job.settled)
					return;
				received += part.length;
				if (received > limit) {
					fail("Fetch exceeds byte limit");
					return;
				}
				buffer.addBytes(part, 0, part.length);
				if (progress != null && reported != received)
					jobs.post(() -> if (!job.settled && reported != received) {
						reported = received;
						progress({receivedBytes: received, totalBytes: total});
					});
			}, error -> {
				if (job.settled)
					return;
				settle(error == null ? Response({status: status, headers: headers, bytes: buffer.getBytes()}) : Failed(error));
			});
			job.abort = () -> {
				timers.remove(timer);
				abort();
			};
		}, complete, Cancelled, Failed("Closed fetch service"));
	}

	/** Delivers what arrived, fails fetches past their time, starts queued ones and runs completions. Call once per frame. */
	public function poll():Void {
		http.poll();
		for (t in timers.copy())
			if (t.job.runningSeconds > t.seconds)
				t.fail("Fetch timeout");
		jobs.poll();
	}

	/** Cancels every pending fetch (each completes Cancelled), refuses later ones, and aborts the platform's transfers. */
	public function shutdown():Void {
		jobs.shutdown();
		http.shutdown();
	}
}
