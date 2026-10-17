package helix.host;

/** The host: what runs the program on a platform (a browser page's frame callbacks, a native process's app loop). It owns the loop, the
	clock, quitting, the window and where run options come from, and nothing else: the Runner it pumps builds and runs everything the app
	sees (the static classes it binds: Window, Input, Graphics and the others). */
interface IHost {
	/** Runs the program: init once, when the window and the GPU exist; frame once a display refresh; cleanup once, when it closes (the window
		closed, quit, or a browser page going away). Natively it returns only after the window closes. */
	public function run(init:Void->Void, frame:Void->Void, cleanup:Void->Void):Void;

	/** Seconds on a monotonic clock. */
	public function getTime():Float;

	/** The window the program draws in (the page, on the web). */
	public function getWindow():IWindow;

	/** Whether quitting closes anything, so whether an app should offer a quit key: not in a browser page, where quit stops the program but
		the page stays. */
	public function canQuit():Bool;

	/** Closes after the current frame: cleanup runs. Natively the window closes; in a browser page the frames stop and the canvas keeps its
		last one. */
	public function quit():Void;

	/** A run option as the platform passes it, or null when it isn't given: in a browser the URL query parameter name, natively the
		environment variable HELIX_ and name in capitals. */
	public function getOption(name:String):Null<String>;
}
