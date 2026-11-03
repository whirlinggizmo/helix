import haxe.io.Bytes;
import helix.platform.IHttp;

/** Checks helix-platform's HTTP client against its contract over a test server that ends bodies early and stalls: a body as long as its
	Content-Length and a chunked body each call `done` with every byte, as do seven bodies at once sent slowly in parts, never a second
	apart (in a page the seventh waits behind the browser's six connections to a server). A body the server closes before its
	Content-Length (plain or gzip), and a chunked body it closes mid-chunk, each call `failed`, never `done`: `done` means the whole body
	is here. A connection it closes with no bytes, or partway through the status line, each calls `failed` and never `head`. One it
	closes partway through the headers calls `failed`: natively without `head`, and in a page after it, as the browser takes the cut head
	as a whole one with an empty body. A body that stops partway, a request never answered, and a connection never taken each fail after
	a second's idle timeout.

	In a page those are asked of the page's own origin. Of another origin, the server's second port: a gzip body cut short with
	`Timing-Allow-Origin` fails, as does a head cut short with it, and a gzip body cut short without it (the browser's own check); a head
	cut short without it calls `done` with no bytes, the gap the platform's docs describe.

	Built from the hxml files beside it: in a page, over `fetch`, and natively over `sys.Http`. The server's URL is its `server` option
	(`?server=` in a page, `HELIX_SERVER` natively), the other origin's `?other=`, a connection never taken `?unaccepted=` and
	`HELIX_UNACCEPTED`; `tools/platform_checks.py` gives them from a server it starts, and serves the page from it. It ends with
	`{passed, checks, failures, answers}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null
	until then. */
class HttpTests {
	// How long every request may take to answer, in seconds.
	static inline final TIMEOUT = 10.;
	// The idle timeout given the requests that stall or send slowly, in seconds.
	static inline final IDLE = 1.;
	// The bytes a whole body has.
	static inline final SIZE = 1000;

	static var http:IHttp;
	static var checks = 0;
	static var failures:Array<String> = [];
	static var answers:Array<String> = [];
	static var left = 0;
	static var started = 0.;

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		http = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		var query = new js.html.URLSearchParams(js.Browser.location.search),
			server = query.get("server"),
			other = query.get("other"),
			unaccepted = query.get("unaccepted");
		#else
		http = new helix.platform.adapters.http.haxehttp.HaxeHttpAdapter();
		var server = Sys.getEnv("HELIX_SERVER"),
			unaccepted = Sys.getEnv("HELIX_UNACCEPTED");
		#end
		if (server == null || unaccepted == null)
			check(false, "no server option");
		else {
			ask(server + "whole", "done");
			ask(server + "chunked", "done");
			// One more than a browser opens to a server at once, which queues the last behind the others' seconds of parts: in a page
			// they're asked of the other origin, whose connections aren't shared with the requests here.
			for (i in 0...7)
				ask(#if js other #else server #end + 'trickle?$i', "done", true, IDLE);
			ask(server + "short", "failed");
			ask(server + "gzip-short", "failed");
			ask(server + "cut-chunk", "failed");
			ask(server + "closed", "failed", false);
			ask(server + "cut-status", "failed", false);
			ask(server + "cut-head", "failed", #if js true #else false #end);
			ask(server + "stall", "failed: Nothing arrived", true, IDLE);
			ask(server + "silent", "failed: Nothing arrived", false, IDLE);
			ask(unaccepted, "failed: Nothing arrived", false, IDLE);
			#if js
			if (other == null)
				check(false, "no other option");
			else {
				ask(other + "gzip-short-timed", "failed");
				// Without Timing-Allow-Origin this is the browser's own check, as Chromium's and Firefox's are.
				ask(other + "gzip-short", "failed");
				ask(other + "cut-head-timed", "failed");
				ask(other + "cut-head", "done", true, null, 0);
			}
			#end
		}
		started = haxe.Timer.stamp();
		#if js
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		while (tick())
			Sys.sleep(1 / 120);
		finish();
		#end
	}

	// Asks for a URL, with an idle timeout or the default, and checks its answer is the one expected: "done" with size bytes, or one
	// starting "failed"; and that its head arrives, or never does when headed is false.
	static function ask(url:String, expected:String, headed = true, ?idleTimeout:Float, size = SIZE):Void {
		left++;
		var received = 0, answered = false, calling = true, heads = 0;
		function answer(how:String) {
			check(!calling, '$url: answered during the call');
			check(!answered, '$url: answered twice');
			answered = true;
			left--;
			answers.push('$url: $how');
			check(StringTools.startsWith(how, expected), '$url: $how, expected $expected');
			check(heads == (headed ? 1 : 0), '$url: $heads heads, expected ${headed ? 1 : 0}');
			if (how == "done")
				check(received == size, '$url: done with $received bytes of $size');
		}
		http.get(url, true, new Map(), (status, _) -> {
			heads++;
			check(status == 200, '$url: status $status');
		}, (part:Bytes) -> received += part.length,
			() -> answer("done"), why -> answer('failed: $why'), idleTimeout);
		calling = false;
	}

	// Polls the client; false once every request has answered, or the time is up.
	static function tick():Bool {
		http.poll();
		if (left == 0)
			return false;
		if (haxe.Timer.stamp() - started > TIMEOUT) {
			check(false, '$left requests not answered after $TIMEOUT seconds');
			return false;
		}
		return true;
	}

	static function check(value:Bool, message:String):Void {
		checks++;
		if (!value)
			failures.push(message);
	}

	static function finish():Void {
		http.dispose();
		var result = {
			passed: failures.length == 0,
			checks: checks,
			failures: failures,
			answers: answers
		};
		#if js
		js.Syntax.code("window.helixResult = {0}", result);
		#else
		Sys.println(haxe.Json.stringify(result));
		if (failures.length > 0)
			Sys.exit(1);
		#end
	}
}
