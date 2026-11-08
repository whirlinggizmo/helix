import helix.platform.Device;
import helix.platform.Orientation;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.internal.Runtime;
import helix.services.input.Tilt;
import helix.services.input.Touch;
import helix.services.screen.Screen;

/** Checks `extras.Device`'s answers about the device and the page over fakes (services' `FakeSystem`, `FakeWindow`, `FakeEvents` and
	`FakeDevices`, and a window here that holds the screen one way up): the safe area in the screen's coordinates, a design's among them;
	the run options; the device; whether the window closes and goes fullscreen; the orientation asked for, granted, refused and out of
	range; and the tilt, its range and its level, refused where the platform can't read it. Each `...Async` call answers once, at a
	later poll. */
@:access(helix.raylib.internal.Runtime)
class DeviceTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var window:TurningWindow;
	static var events:FakeEvents;

	static function frame():Void {
		var now = Runtime.waiting;
		Runtime.waiting = [];
		for (f in now)
			f();
		events.poll();
		window.answer();
		if (Runtime.tiltService != null)
			Runtime.tiltService.poll();
	}

	// Calls a request, checking it answers once, after its call: "done", or "failed: " and the reason.
	static function answer(request:(done:Void->Void, failed:String->Void)->Void):String {
		var answers:Array<String> = [], calling = true;
		request(() -> answers.push(calling ? "during the call" : "done"), error -> answers.push(calling ? "during the call" : 'failed: $error'));
		calling = false;
		for (_ in 0...4)
			frame();
		check(answers.length == 1, 'answered once: $answers');
		return answers[0];
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var system = new FakeSystem();
		Runtime.system = system;
		window = new TurningWindow();
		events = new FakeEvents();
		Runtime.window = window;
		Runtime.events = events;
		Runtime.screen = new Screen(window, events);

		// The safe area, in the screen's coordinates: the window's logical pixels, or a design's.
		window.insetLeft = 40;
		window.insetTop = 20;
		window.insetBottom = 30;
		var safe = GetWindowSafeArea();
		check(safe.x == 40 && safe.y == 20 && safe.width == 760 && safe.height == 550, 'the safe area, in logical pixels: $safe');
		window.ratio = 2;
		safe = GetWindowSafeArea();
		check(safe.x == 40 && safe.width == 760 && GetScreenWidth() == 800, 'the safe area at a pixel ratio of 2, as GetScreenWidth: $safe');
		Runtime.screen.setDesignSize(400, 300, Stretch);
		safe = GetWindowSafeArea();
		check(safe.x == 20 && safe.y == 10 && safe.width == 380 && safe.height == 275 && GetScreenWidth() == 400,
			'the safe area in a design\'s pixels, as GetScreenWidth: $safe');
		Runtime.screen = new Screen(window, events);
		window.insetLeft = window.insetTop = window.insetBottom = 0;
		safe = GetWindowSafeArea();
		check(safe.x == 0 && safe.y == 0 && safe.width == 800 && safe.height == 600, 'no insets, the whole window: $safe');

		// Run options.
		system.options.set("level", "3");
		check(GetRunOption("level") == "3", "a run option set");
		check(GetRunOption("speed") == null, "a run option not set is null");

		// The device.
		var devices = new FakeDevices();
		Runtime.touchService = new Touch(events, devices);
		system.described = new Device(true, "android", "arm64", false);
		check(IsPlatformWeb() && GetPlatformOS() == "android" && IsTouchAvailable() && !IsFinePointerAvailable(), "a phone's page");
		system.described = new Device(false, "linux", "x86_64", true);
		devices.touchAvailable = false;
		check(!IsPlatformWeb() && GetPlatformOS() == "linux" && !IsTouchAvailable() && IsFinePointerAvailable(), "a desktop");

		// The window's abilities.
		check(!IsWindowCloseable(), "a window that can't close (the fake's, as a page's)");
		check(IsFullscreenAvailable(), "a window that can go fullscreen");

		// Orientation.
		check(GetScreenOrientation() == ORIENTATION_ANY, "not held until asked");
		check(answer((d, f) -> SetScreenOrientationAsync(ORIENTATION_LANDSCAPE, d, f)) == "done"
			&& GetScreenOrientation() == ORIENTATION_LANDSCAPE,
			"held landscape once granted");
		check(answer((d, f) -> SetScreenOrientationAsync(ORIENTATION_ANY, d, f)) == "done"
			&& GetScreenOrientation() == ORIENTATION_ANY, "released");
		window.locks = false;
		check(answer((d, f) -> SetScreenOrientationAsync(ORIENTATION_PORTRAIT, d, f)) == "failed: the screen can't be held one way up here",
			"refused where it can't be asked");
		check(answer((d, f) -> SetScreenOrientationAsync(7, d, f)).indexOf("failed: 7 is not") == 0, "a value out of range is refused");

		// The tilt: off until asked, refused where it can't be read, and read once granted.
		check(Runtime.tiltService == null, "the tilt isn't made until a tilt function is called");
		var devices = new FakeDevices();
		Runtime.tiltService = new Tilt(events, devices);
		var tilt = GetTilt();
		check(tilt.x == 0 && tilt.y == 0, "no tilt before readings");
		var asked = [];
		EnableTiltAsync(() -> asked.push("done"), why -> asked.push(why));
		check(devices.tiltRequested && asked.length == 0, "asked of the platform, answering later");
		events.next.push(TiltState(On));
		// Held steady at level for over half a second, then tilted 15 degrees right and 30 forward.
		var start = haxe.Timer.stamp();
		while (haxe.Timer.stamp() - start < .6) {
			events.next.push(Tilt(10, 5, 0));
			frame();
		}
		events.next.push(Tilt(40, 20, 0));
		frame();
		tilt = GetTilt();
		check(Math.abs(tilt.x - .5) < 1e-9 && Math.abs(tilt.y - 1) < 1e-9, 'the tilt from level over 30 degrees: $tilt');
		SetTiltRange(60);
		events.next.push(Tilt(40, 20, 0));
		frame();
		tilt = GetTilt();
		check(Math.abs(tilt.x - .25) < 1e-9 && Math.abs(tilt.y - .5) < 1e-9, 'the tilt over 60 degrees: $tilt');
		CalibrateTilt();
		tilt = GetTilt();
		check(tilt.x == 0 && tilt.y == 0, "level taken again, reading 0 meanwhile");
		DisableTilt();
		check(!devices.tiltRequested, "turned off");
		Runtime.tiltService = new Tilt(events, new UnreadableTilt());
		check(answer((d, f) -> EnableTiltAsync(d, f)) == "failed: the tilt can't be read here", "refused where the tilt can't be read");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}

/** A window that holds the screen one way up when `locks`, answering at the next `answer`. */
class TurningWindow extends FakeWindow {
	/** Gets or sets whether it can hold the screen. */
	public var locks = true;

	var held:Orientation = Any;

	override function get_orientation():Orientation
		return held;

	override public function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool {
		if (!locks)
			return false;
		return later("orientation", () -> held = orientation, done, failed);
	}
}

/** A tilt that can't be read, as natively. */
class UnreadableTilt implements helix.platform.ITilt {
	/** Creates one. */
	public function new() {}

	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool
		return false;

	public function releaseAccess():Void {}

	public function dispose():Void {}
}
