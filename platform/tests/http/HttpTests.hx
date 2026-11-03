import haxe.io.Bytes;
import helix.platform.IHttp;

/** Checks helix-platform's HTTP client against its contract over a test server that ends bodies early: a body as long as its
	Content-Length, and a chunked body, each calls `done` with every byte; a body the server closes before its Content-Length, and a
	chunked body it closes mid-chunk, each calls `failed`, never `done`. `done` means the whole body is here. A connection it closes with
	no bytes, or partway through the status line, each calls `failed` and never `head`; natively, so does one it closes partway through the
	headers. In a page that one isn't asked for: Chromium takes a head cut short as the whole head, and its body as empty, so `fetch`
	answers it 200 and `done`.

	Built from the hxml files beside it: in a page, over `fetch`, and natively over `sys.Http`. The server's URL is its `server` option
	(`?server=` in a page, `HELIX_SERVER` natively), which `tools/platform_checks.py` gives it from a server it starts. It ends with
	`{passed, checks, failures, answers}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null
	until then. */
class HttpTests {
	// How long a request may take to answer, in seconds.
	static inline final TIMEOUT = 10.;
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
		var server = new js.html.URLSearchParams(js.Browser.location.search).get("server");
		#else
		http = new helix.platform.adapters.http.haxehttp.HaxeHttpAdapter();
		var server = Sys.getEnv("HELIX_SERVER");
		#end
		if (server == null)
			check(false, "no server option");
		else {
			ask(server + "whole", "done");
			ask(server + "chunked", "done");
			ask(server + "short", "failed");
			ask(server + "cut-chunk", "failed");
			ask(server + "closed", "failed", false);
			ask(server + "cut-status", "failed", false);
			#if !js
			ask(server + "cut-head", "failed", false);
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

	// Asks for a URL and checks its answer is the one expected: "done" with the whole body, or "failed"; and that its head arrives, or never
	// does when headed is false.
	static function ask(url:String, expected:String, headed = true):Void {
		left++;
		var received = 0, answered = false, calling = true;
		function answer(how:String) {
			check(!calling, '$url: answered during the call');
			check(!answered, '$url: answered twice');
			answered = true;
			left--;
			answers.push('$url: $how');
			check(StringTools.startsWith(how, expected), '$url: $how, expected $expected');
			if (how == "done")
				check(received == SIZE, '$url: done with $received bytes of $SIZE');
		}
		http.get(url, true, new Map(), (status, _) -> check(headed && status == 200, '$url: status $status'), (part:Bytes) -> received += part.length,
			() -> answer("done"), why -> answer('failed: $why'));
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
