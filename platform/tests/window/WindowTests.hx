import helix.platform.IEvents;
import helix.platform.IWindow;

/** Represents one request: what it asks, and what its answer must agree with. */
typedef Request = {
	/** The request's name, in its answer's line and a failure's message. */
	final name:String;

	/** Asks, returning what the request returned. */
	final ask:(done:Void->Void, failed:String->Void)->Bool;

	/** Whether the request returns true; false for one refused before it asks. */
	final ?asks:Bool;

	/** Checks the window agrees with a `done`, once it has come; omitted, any `done` agrees. */
	final ?granted:() -> Bool;

	/** What the answer must be on this target: "done", or "failed"; omitted, either, as the window manager decides. */
	final ?expected:String;
}

/** Checks helix-platform's window requests against the contract, with the library alone: each answers once, at a later `IEvents.poll`
	and never during its call, with `done` once the window reflects it or `failed` and a reason; a request refused before it asks returns
	false and answers nothing. What a page can't do fails and what it can is done; natively, what the window manager does is its own, so
	each answer is listed (`<request>: done` or `failed: <reason>`) as what this desktop honors.

	Built from the hxml files beside it: in a page, and natively over SDL3 on the display it is given (a private one in the checks). It
	ends with `{passed, checks, failures, answers}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null
	until then. Run by `tools/platform_checks.py`. */
class WindowTests {
	// How long a request may take to answer, in seconds: the native adapter fails one after a second.
	static inline final TIMEOUT = 3.;
	// Frames after an answer in which a second one would be seen.
	static inline final SETTLE = 10;

	static var window:IWindow;
	static var events:IEvents;
	static var requests:Array<Request>;
	static var next = 0;
	static var asked = -1.;
	static var answers:Array<String> = [];
	static var settled = 0;
	static var checks = 0;
	static var failures:Array<String> = [];
	static var printed:Array<String> = [];

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		setup();
		while (tick())
			Sys.sleep(1 / 120);
		finish();
		#end
	}

	/** Runs one frame: polls the events, which the answers come after, and asks the next request once the last has answered and settled.
		False once every request has. */
	static function tick():Bool {
		events.poll();
		if (next >= requests.length)
			return false;
		var request = requests[next], now = haxe.Timer.stamp();
		if (asked < 0) {
			asked = now;
			answers = [];
			settled = 0;
			var calling = true;
			var result = request.ask(() -> answers.push(calling ? "during the call" : "done"),
				why -> answers.push(calling ? "during the call" : 'failed: $why'));
			calling = false;
			var asks = request.asks != false;
			check(result == asks, '${request.name}: returned $result');
			check(answers.length == 0, '${request.name}: answered during the call');
			if (!asks) {
				printed.push('${request.name}: refused before asking');
				advance();
			}
			return true;
		}
		if (answers.length == 0) {
			if (now - asked > TIMEOUT) {
				check(false, '${request.name}: no answer after $TIMEOUT seconds');
				advance();
			}
			return true;
		}
		if (++settled < SETTLE)
			return true;
		var answer = answers[0];
		printed.push('${request.name}: $answer');
		check(answers.length == 1, '${request.name}: answered ${answers.length} times: $answers');
		check(answer == "done" || StringTools.startsWith(answer, "failed: ") && answer.length > 8, '${request.name}: $answer');
		if (request.expected != null)
			check(StringTools.startsWith(answer, request.expected), '${request.name}: $answer, expected ${request.expected}');
		if (answer == "done" && request.granted != null)
			check(request.granted(), '${request.name}: done, but the window doesn\'t say so');
		advance();
		return true;
	}

	static function advance():Void {
		next++;
		asked = -1;
	}

	static function check(value:Bool, message:String):Void {
		checks++;
		if (!value)
			failures.push(message);
	}

	/** Makes the requests: on both targets, then each target's own. */
	static function setup():Void {
		requests = [
			{name: "requestSize(0, 10)", ask: (d, f) -> window.requestSize(0, 10, d, f), asks: false},
			{name: "requestMinimumSize(-1, 0)", ask: (d, f) -> window.requestMinimumSize(-1, 0, d, f), asks: false},
			{name: "requestMonitorIndex(99)", ask: (d, f) -> window.requestMonitorIndex(99, d, f), asks: false},
			{name: "requestMonitorIndex(current)", ask: (d, f) -> window.requestMonitorIndex(window.monitorIndex, d, f), expected: "done"},
			{name: "requestVisible(false)", ask: (d, f) -> window.requestVisible(false, d, f), granted: () -> !window.visible},
			{name: "requestVisible(true)", ask: (d, f) -> window.requestVisible(true, d, f), granted: () -> window.visible},
			{name: "requestOpacity(0.5)", ask: (d, f) -> window.requestOpacity(.5, d, f), granted: () -> Math.abs(window.opacity - .5) < .01},
			{name: "requestOpacity(1)", ask: (d, f) -> window.requestOpacity(1, d, f)},
			{name: "requestFocus()", ask: (d, f) -> window.requestFocus(d, f), granted: () -> window.focused},
		];
		#if js
		requests = requests.concat([
			{name: "requestSize(640, 400)", ask: (d, f) -> window.requestSize(640, 400, d, f), expected: "failed"},
			{name: "requestPosition(50, 60)", ask: (d, f) -> window.requestPosition(50, 60, d, f), expected: "failed"},
			{name: "requestMaximized(true)", ask: (d, f) -> window.requestMaximized(true, d, f), expected: "failed"},
			{name: "requestMaximized(false)", ask: (d, f) -> window.requestMaximized(false, d, f), expected: "done"},
			{name: "requestMinimized(true)", ask: (d, f) -> window.requestMinimized(true, d, f), expected: "failed"},
			{name: "requestMinimized(false)", ask: (d, f) -> window.requestMinimized(false, d, f), expected: "done"},
			{name: "requestMinimumSize(200, 150)", ask: (d, f) -> window.requestMinimumSize(200, 150, d, f), expected: "failed"},
			{name: "requestMaximumSize(0, 0)", ask: (d, f) -> window.requestMaximumSize(0, 0, d, f), expected: "failed"},
		]);
		#else
		requests = requests.concat([
			{
				name: "requestSize(640, 400)",
				ask: (d, f) -> window.requestSize(640, 400, d, f),
				granted: () -> window.width == 640 && window.height == 400},
			{name: "requestSize(as it is)", ask: (d, f) -> window.requestSize(window.width, window.height, d, f), expected: "done"},
			{name: "requestPosition(50, 60)", ask: (d, f) -> window.requestPosition(50, 60, d, f), granted: () -> window.x == 50 && window.y == 60},
			{name: "requestMinimumSize(200, 150)", ask: (d, f) -> window.requestMinimumSize(200, 150, d, f), expected: "done"},
			{name: "requestMinimumSize(0, 0)", ask: (d, f) -> window.requestMinimumSize(0, 0, d, f), expected: "done"},
			{name: "requestMaximumSize(0, 0)", ask: (d, f) -> window.requestMaximumSize(0, 0, d, f), expected: "done"},
			{name: "requestMaximized(true)", ask: (d, f) -> window.requestMaximized(true, d, f), granted: () -> window.maximized},
			{
				name: "requestSize while maximized",
				ask: (d, f) -> window.maximized ? window.requestSize(300, 200, d, f) : window.requestSize(window.width, window.height, d, f),
				granted: () -> !window.maximized
			},
			{name: "requestMaximized(false)", ask: (d, f) -> window.requestMaximized(false, d, f), granted: () -> !window.maximized},
			{name: "requestMinimized(true)", ask: (d, f) -> window.requestMinimized(true, d, f), granted: () -> window.minimized},
			{name: "requestMinimized(false)", ask: (d, f) -> window.requestMinimized(false, d, f), granted: () -> !window.minimized},
			{
				name: "requestFullscreen(true)",
				ask: (d, f) -> window.requestFullscreen(true, d, f),
				granted: () -> window.fullscreen
			},
			{
				name: "requestSize while fullscreen",
				ask: (d, f) -> window.fullscreen ? window.requestSize(300, 200, d, f) : window.requestSize(window.width, window.height, d, f),
				granted: () -> !window.fullscreen
			},
			{name: "requestFullscreen(true) again", ask: (d, f) -> window.requestFullscreen(window.fullscreen, d, f), expected: "done"},
			{name: "requestFullscreen(false)", ask: (d, f) -> window.requestFullscreen(false, d, f), granted: () -> !window.fullscreen},
			{name: "requestFocus() after", ask: (d, f) -> window.requestFocus(d, f), granted: () -> window.focused},
		]);
		#end
	}

	static function finish():Void {
		var result = {
			passed: failures.length == 0,
			checks: checks,
			failures: failures,
			answers: printed
		};
		#if js
		js.Syntax.code("window.helixResult = {0}", result);
		#else
		Sys.println(haxe.Json.stringify(result));
		if (window.canClose())
			window.close();
		Sys.exit(failures.length == 0 ? 0 : 1);
		#end
	}
}
