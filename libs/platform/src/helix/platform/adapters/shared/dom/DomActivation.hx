package helix.platform.adapters.shared.dom;

import js.Browser;

/** Provides what the page's adapters share for what a browser allows only soon after the player presses something (fullscreen, the
	mouse's lock): asking now while a press is fresh, or inside the player's next lift, click or key. */
@:noCompletion
class DomActivation {
	// What's waiting to be asked at the next press, and the listener that asks it.
	static var waiting:Array<Void->Void> = [];
	static var listener:Null<Dynamic->Void>;

	/** Asks now while a press is fresh, else inside the player's next lift, click or key: a phone's tap counts only as its finger lifts, so
		asked from a frame as the finger lands, it would be refused.

		@param ask  What to ask. */
	public static function ask(ask:Void->Void):Void {
		var activation:Dynamic = js.Syntax.code("navigator.userActivation");
		if (activation == null || activation.isActive)
			ask();
		else
			atNextPress(ask);
	}

	// Asks once, inside the next lift, click or key: the events a browser counts as a press.
	static function atNextPress(ask:Void->Void):Void {
		waiting.push(ask);
		if (listener != null)
			return;
		var window:Dynamic = Browser.window;
		listener = _ -> {
			for (name in ["pointerup", "touchend", "click", "keydown"])
				window.removeEventListener(name, listener, true);
			listener = null;
			var asks = waiting;
			waiting = [];
			for (then in asks)
				then();
		};
		for (name in ["pointerup", "touchend", "click", "keydown"])
			window.addEventListener(name, listener, true);
	}
}
