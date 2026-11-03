import haxe.io.Bytes;
import helix.platform.IClipboard;
import helix.platform.IEvents;
import helix.platform.IMouse;
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
	each answer is listed (`<request>: done` or `failed: <reason>`) as what this desktop honors. The mouse's lock and the clipboard
	answer the same way, and are checked here too, as are a dropped file read (`drop`) and the safe area (`checkSafeArea`): natively each is done, the clipboard reading back what was put on it; in a page the
	lock already as asked is done, and the clipboard answers as the browser decides.

	Built from the hxml files beside it: in a page, and natively over SDL3 on the display it is given (a private one in the checks). It
	ends with `{passed, checks, failures, answers}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null
	until then. Run by `tools/platform_checks.py`. */
#if cpp
@:headerCode("#include <SDL3/SDL.h>")
#end
class WindowTests {
	// How long a request may take to answer, in seconds: the native adapter fails one after a second.
	static inline final TIMEOUT = 3.;
	// Frames after an answer in which a second one would be seen.
	static inline final SETTLE = 10;

	static var window:IWindow;
	static var events:IEvents;
	static var mouse:IMouse;
	static var clipboard:IClipboard;
	static var read:Null<String>;
	static var readImage:Null<Bytes>;
	static var requests:Array<Request>;
	static var next = 0;
	static var asked = -1.;
	static var answers:Array<String> = [];
	static var settled = 0;
	static var checks = 0;
	static var failures:Array<String> = [];
	static var printed:Array<String> = [];
	// Called with a FilesDropped's count, after the poll delivering it; and what the dropped file read gave.
	static var onDrop:Null<Int->Void>;
	static var droppedName:Null<String>;
	static var droppedBytes:Null<Bytes>;
	// The dropped file's contents.
	static final DROPPED = "helix drop";

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		var dom = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		events = dom;
		mouse = new helix.platform.adapters.mouse.dom.DomMouseAdapter({events: dom});
		clipboard = new helix.platform.adapters.clipboard.dom.DomClipboardAdapter();
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		var sdl = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		events = sdl;
		mouse = new helix.platform.adapters.mouse.sdl3.Sdl3MouseAdapter({events: sdl});
		clipboard = new helix.platform.adapters.clipboard.sdl3.Sdl3ClipboardAdapter();
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
		for (event in events.events)
			switch event {
				case FilesDropped(count) if (onDrop != null):
					onDrop(count);
				case _:
			}
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

	/** Checks the safe area: natively on a private display, the whole window; in a page, the viewport less the insets the page's query
		names (`safeArea=top,right,bottom,left`, CSS pixels, which `tools/page_check.cjs` has Chromium emulate), or the whole viewport. */
	static function checkSafeArea():Void {
		var top = 0, right = 0, bottom = 0, left = 0;
		#if js
		var given = new js.html.URLSearchParams(js.Browser.window.location.search).get("safeArea");
		if (given != null) {
			var sides = [for (side in given.split(",")) Std.parseInt(side)];
			top = sides[0];
			right = sides[1];
			bottom = sides[2];
			left = sides[3];
		}
		#end
		var found = '${window.safeAreaX},${window.safeAreaY} ${window.safeAreaWidth}x${window.safeAreaHeight} in ${window.width}x${window.height}';
		printed.push('safe area: $found');
		check(window.safeAreaX == left
			&& window.safeAreaY == top
			&& window.safeAreaWidth == window.width - left - right
			&& window.safeAreaHeight == window.height - top - bottom,
			'safe area $found, expected the window less $top,$right,$bottom,$left');
	}

	/** Makes the requests: on both targets, then each target's own. */
	static function setup():Void {
		checkSafeArea();
		requests = [
			{
				name: "a file dropped",
				ask: (d, f) -> {
					onDrop = count -> {
						onDrop = null;
						count == 1 ? d() : f('$count files');
					};
					drop();
					return true;
				},
				expected: "done"
			},
			{
				name: "readDroppedFile(0)",
				ask: (d, f) -> {
					window.readDroppedFile(0, 1 << 20, (name, bytes) -> {
						droppedName = name;
						droppedBytes = bytes;
						d();
					}, f);
					return true;
				},
				expected: "done",
				granted: () -> droppedName == "dropped.txt" && droppedBytes.toString() == DROPPED},
			{
				name: "readDroppedFile(0) over maxBytes",
				ask: (d, f) -> {
					window.readDroppedFile(0, 4, (_, _) -> d(), f);
					return true;
				},
				expected: "failed"
			},
			{
				name: "readDroppedFile(5)",
				ask: (d, f) -> {
					window.readDroppedFile(5, 1 << 20, (_, _) -> d(), f);
					return true;
				},
				expected: "failed"
			},
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
			{
				name: "requestLock(false), not locked",
				ask: (d, f) -> mouse.requestLock(false, d, f),
				expected: "done",
				granted: () -> !mouse.locked
			},
			{
				name: "clipboard setText",
				ask: (d, f) -> {
					clipboard.setText("helix", d, f);
					return true;
				}
			},
			{name: "clipboard requestText", ask: (d, f) -> clipboard.requestText(_ -> d(), f)},
			{name: "clipboard requestImage", ask: (d, f) -> clipboard.requestImage(_ -> d(), f)},
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
			{
				name: "requestLock(true)",
				ask: (d, f) -> mouse.requestLock(true, d, f),
				expected: "done",
				granted: () -> mouse.locked
			},
			{
				name: "requestLock(false)",
				ask: (d, f) -> mouse.requestLock(false, d, f),
				expected: "done",
				granted: () -> !mouse.locked
			},
			{
				name: "clipboard setText",
				ask: (d, f) -> {
					clipboard.setText("helix", d, f);
					return true;
				},
				expected: "done"
			},
			{
				name: "clipboard requestText",
				ask: (d, f) -> clipboard.requestText(text -> {
					read = text;
					d();
				}, f),
				expected: "done",
				granted: () -> read == "helix"
			},
			{
				name: "clipboard setImage",
				ask: (d, f) -> {
					clipboard.setImage(PNG, d, f);
					return true;
				},
				expected: "done"
			},
			{
				name: "clipboard requestImage",
				ask: (d, f) -> clipboard.requestImage(png -> {
					readImage = png;
					d();
				}, f),
				expected: "done",
				granted: () -> readImage != null && readImage.compare(PNG) == 0},
		]);
		#end
	}

	/** Drops a file named dropped.txt holding `DROPPED` on the window, as the player would: natively SDL's drop events for a file
		written beside the program, in a page a drop event on the canvas. */
	static function drop():Void {
		#if js
		js.Syntax.code("(function(){var t=new DataTransfer();t.items.add(new File([{0}],'dropped.txt'));
			document.getElementById('canvas').dispatchEvent(new DragEvent('drop',{dataTransfer:t,cancelable:true}));})()", DROPPED);
		#else
		var path = haxe.io.Path.join([Sys.getCwd(), "native", "dropped.txt"]);
		sys.io.File.saveContent(path, DROPPED);
		pushDrop(path);
		#end
	}

	#if cpp
	// SDL's events for one file dropped: the file, then the drop's end. SDL keeps the copy of the path as the event's data.

	@:functionCode("SDL_Event e;SDL_zero(e);e.type=SDL_EVENT_DROP_FILE;e.drop.data=SDL_strdup(path.utf8_str());SDL_PushEvent(&e);
		SDL_zero(e);e.type=SDL_EVENT_DROP_COMPLETE;SDL_PushEvent(&e);")
	static function pushDrop(path:String):Void {}
	#end

	// A 1 x 1 PNG, put on the clipboard and read back.
	static final PNG = haxe.crypto.Base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==");

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
