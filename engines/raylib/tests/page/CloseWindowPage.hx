import helix.raylib.Raylib.*;
import js.Browser;

/** Checks `CloseWindow` in a page (tools/raylib_page_checks.py): with the keyboard, mouse, touch and gamepads read, a key, a wheel turn and
	a right click on the canvas are cancelled and the canvas takes no touch gestures; after it, each reaches a listener of the page's own
	uncancelled, the canvas's style is the page's, `IsWindowReady` is false, and the code after the call runs. The canvas drawn red is
	cleared after it, which the tool checks on the page's screenshot (CloseWindowPage.check.json). Leaves {passed, checks, failures} in `window.helixResult`. */
class CloseWindowPage {
	static var checks = 0;
	static final failures:Array<String> = [];

	static function check(value:Bool, message:String):Void {
		if (value)
			checks++;
		else
			failures.push(message);
	}

	// Whether an event sent to a target, cancelable, was cancelled by the time a listener of the page's own, added last, sees it.
	static function cancelled(target:js.html.EventTarget, event:js.html.Event):Bool {
		var seen = false, prevented = false;
		var own = (e:js.html.Event) -> {
			seen = true;
			prevented = e.defaultPrevented;
		};
		target.addEventListener(event.type, own);
		target.dispatchEvent(event);
		target.removeEventListener(event.type, own);
		if (!seen)
			failures.push('${event.type}: the page\'s own listener never saw it');
		return prevented;
	}

	static function key():js.html.Event
		return new js.html.KeyboardEvent("keydown", {
			code: "Space",
			key: " ",
			cancelable: true,
			bubbles: true
		});

	static function wheel():js.html.Event
		return new js.html.WheelEvent("wheel", {deltaY: 100, cancelable: true, bubbles: true});

	static function menu():js.html.Event
		return new js.html.MouseEvent("contextmenu", {button: 2, cancelable: true, bubbles: true});

	static function main():Void {
		InitWindow(320, 240, "close");
		var frames = 0;
		while (!WindowShouldClose() && frames < 10) {
			// Each device read, so each adapter is made and listening.
			IsKeyDown(KEY_SPACE);
			GetMousePosition();
			GetTouchPointCount();
			IsGamepadAvailable(0);
			BeginDrawing();
			ClearBackground(RED);
			EndDrawing();
			frames++;
		}
		var canvas:js.html.CanvasElement = cast Browser.document.getElementById("canvas");
		check(IsWindowReady(), "open: the window is ready");
		check(cancelled(Browser.window, key()), "open: a key is cancelled");
		check(cancelled(canvas, wheel()), "open: a wheel turn on the canvas is cancelled");
		check(cancelled(canvas, menu()), "open: a right click on the canvas is cancelled");
		check(canvas.style.touchAction == "none", "open: the canvas takes no touch gestures");
		CloseWindow();
		check(!IsWindowReady(), "closed: the window isn't ready");
		check(!cancelled(Browser.window, key()), "closed: a key reaches the page uncancelled");
		check(!cancelled(canvas, wheel()), "closed: a wheel turn reaches the page uncancelled");
		check(!cancelled(canvas, menu()), "closed: a right click reaches the page uncancelled");
		check(canvas.style.touchAction == "" && canvas.style.cursor == "", "closed: the canvas's style is the page's");
		Sys.println("after CloseWindow: the program goes on");
		var result:Dynamic = {passed: failures.length == 0, checks: checks, failures: failures};
		Reflect.setField(Browser.window, "helixResult", result);
	}
}
