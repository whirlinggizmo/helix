package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Answers;
import helix.raylib.internal.Runtime;
#end

/** Provides what a game needs from the device and the page that raylib 5.5 has no call for: the safe area, the run options, the
	device, the window's abilities, the screen's orientation and the tilt.

	`helix.raylib.extras.Device` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RDevice {
	#if !macro
	// ---- Safe area ----

	/** Returns the part of the window no notch, rounded corner or system bar covers, in the screen's coordinates as `GetScreenWidth`
		measures them.

		A HUD and buttons go inside it.

		On a desktop it is the whole window. In a page it is the whole window unless the viewport meta tag has `viewport-fit=cover`.

		@return  The safe area. */
	static function GetWindowSafeArea():Rectangle {
		var screen = Runtime.screen;
		return new Rectangle(screen.safeAreaX, screen.safeAreaY, screen.safeAreaWidth, screen.safeAreaHeight);
	}

	// ---- Run options ----

	/** Returns an option the program was started with, or null when it isn't set.

		In a page it is the URL's query parameter of that name (`?level=3`).

		Natively it is the command line's `--level=3`, or else the environment variable `HELIX_` and the name in capitals
		(`HELIX_LEVEL=3`).

		@param name  The option's name.
		@return  Its value, or null when it isn't set. */
	static function GetRunOption(name:String):Null<String> {
		return Runtime.system.getOption(name);
	}

	// ---- Device ----

	/** Returns whether the program runs in a browser page rather than natively. See `GetPlatformOS` for naming the operating system.

		@return  True in a page. */
	static function IsPlatformWeb():Bool {
		return Runtime.system.device.browser;
	}

	/** Returns the operating system's name in lowercase, or "" where the platform names none. See `IsPlatformWeb` for whether the program runs in a page.

		The names are "windows", "macos", "linux", "android", "ios" and "chromeos".

		@return  The system's name. */
	static function GetPlatformOS():String {
		return Runtime.system.device.os;
	}

	/** Returns whether the device has a touch screen. See `IsFinePointerAvailable` for whether there is a mouse, a trackpad or a pen.

		Always false natively.

		A laptop may have both a touch screen and a mouse. Touch controls also belong on the first touch, not on this alone.

		@return  True with a touch screen. */
	static function IsTouchScreenAvailable():Bool {
		return Runtime.system.device.touchScreen;
	}

	/** Returns whether the device has a fine pointer, such as a mouse, a trackpad or a pen. See `IsTouchScreenAvailable` for whether there is a touch screen.

		False on a phone or a tablet alone.

		@return  True with a fine pointer. */
	static function IsFinePointerAvailable():Bool {
		return Runtime.system.device.finePointer;
	}

	// ---- Window ----

	/** Returns whether the program can close its own window.

		False in a page, which can't close its tab. A game hides its Quit there.

		@return  True where `CloseWindow` ends the program's window. */
	static function IsWindowCloseable():Bool {
		return Runtime.window.canClose();
	}

	/** Returns whether the window can go fullscreen. See `ToggleFullscreenAsync` for asking for it.

		False in a page that isn't allowed to, such as an iframe without permission or iOS Safari on an iPhone.

		@return  True where `ToggleFullscreenAsync` can be granted. */
	static function IsFullscreenAvailable():Bool {
		return Runtime.window.canFullscreen();
	}

	// ---- Orientation ----

	/** Asynchronously asks for the screen to be held one way up, or released. See `GetScreenOrientation` for reading how it is held.

		Natively and on iOS it is refused.

		Only some browsers lock it. Chrome on Android locks it only in fullscreen, so a program asks in `ToggleFullscreenAsync`'s `done`.

		Where the lock is refused, a game shows "turn your device" when the shape is wrong (`GetScreenWidth() < GetScreenHeight()`).

		A value that isn't an `ORIENTATION_` value is refused.

		@param orientation  `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`, or `ORIENTATION_ANY` to release a lock.
		@param done  Optional. Called once the screen is held, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function SetScreenOrientationAsync(orientation:Int, ?done:Void->Void, ?failed:String->Void):Void {
		if (orientation < 0 || orientation > 2) {
			Runtime.later(() -> Answers.refuse("SetScreenOrientationAsync", '$orientation is not an ORIENTATION_ value', failed));
			return;
		}
		var window = Runtime.window;
		Answers.ask("SetScreenOrientationAsync", (granted, refused) -> window.requestOrientation(cast orientation, granted, refused),
			"the screen can't be held one way up here", done, failed);
	}

	/** Returns how the screen is held for the program, as `SetScreenOrientationAsync` asked, or `ORIENTATION_ANY` when it isn't held.

		A page loses the lock as it leaves fullscreen.

		@return  `ORIENTATION_ANY`, `ORIENTATION_LANDSCAPE` or `ORIENTATION_PORTRAIT`. */
	static function GetScreenOrientation():Int {
		return Runtime.window.orientation;
	}

	// ---- Tilt ----

	/** Asynchronously asks for the device's tilt readings, for a game steered by tilting a phone. See `GetTilt` for
		reading them and `DisableTilt` for stopping them.

		Natively it is refused.

		A page may need permission, which the browser asks for at the next tap. A game asks before the tap that starts play.

		@param done  Optional. Called once readings arrive, at a later poll.
		@param failed  Optional. Receives why there will be none: refused, the page isn't HTTPS, or no sensor; when omitted, it is logged. */
	static function EnableTiltAsync(?done:Void->Void, ?failed:String->Void):Void {
		var tilt = Runtime.tilt();
		Answers.ask("EnableTiltAsync", (granted, refused) -> tilt.requestAccess(granted, refused), "the tilt can't be read here", done, failed);
	}

	/** Stops the tilt's readings. See `EnableTiltAsync` for asking for them.

		A permission granted stays granted. */
	static function DisableTilt():Void {
		Runtime.tilt().releaseAccess();
	}

	/** Returns the tilt from level, turned with the screen, each axis -1 to 1. See `CalibrateTilt` for setting what reads as level.

		x is across the screen and y is down it.

		A full tilt of 1 is `SetTiltRange`'s angle.

		The tilt is 0 until readings arrive and the device has been held steady once. Level is taken then.

		@return  The tilt. */
	static function GetTilt():Vector2 {
		var tilt = Runtime.tilt();
		return new Vector2(tilt.getAxis(X), tilt.getAxis(Y));
	}

	/** Sets the angle, in degrees, that reads as a full tilt of 1. It defaults to 30.

		@param degrees  The angle. */
	static function SetTiltRange(degrees:Float):Void {
		Runtime.tilt().range = degrees;
	}

	/** Takes how the device is held now as level. See `GetTilt` for reading the tilt from it. */
	static function CalibrateTilt():Void {
		Runtime.tilt().calibrate();
	}
	#end
}
