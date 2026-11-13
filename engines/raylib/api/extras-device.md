# Device

[Back to the library](README.md)

## Device

*class* in [`engines/raylib/src/helix/raylib/extras/Device.hx`](../src/helix/raylib/extras/Device.hx), `import helix.raylib.extras.Device;`

Provides what a game needs from the device that raylib 5.5 has no call for, helix-raylib's own: the safe area around a notch, what the device is, whether the window can close or go fullscreen, the screen's orientation, and the device's tilt. Imported apart: `import helix.raylib.extras.Device.*;`.

Each answers on every target. Where a target has no such thing the answer says so (no tilt natively, the whole window as the safe area on a desktop) rather than the call failing to compile. Each `...Async` call answers at a later poll, never during the call. A program that calls none of them links none of them.

```haxe
static inline var ORIENTATION_ANY:Int
static inline var ORIENTATION_LANDSCAPE:Int
static inline var ORIENTATION_PORTRAIT:Int
static inline var TILT_STATUS_OFF:Int
static inline var TILT_STATUS_WAITING_FOR_TAP:Int
static inline var TILT_STATUS_STARTING:Int
static inline var TILT_STATUS_ON:Int
static inline var TILT_STATUS_REFUSED:Int
static inline var TILT_STATUS_UNAVAILABLE:Int
static inline var TILT_STATUS_NEEDS_HTTPS:Int
static function IsPlatformWeb():Bool
```

- `ORIENTATION_ANY`: The screen held as the device is held, or released.
- `ORIENTATION_LANDSCAPE`: The screen held wider than tall.
- `ORIENTATION_PORTRAIT`: The screen held taller than wide.
- `TILT_STATUS_OFF`: The tilt isn't read: it was never asked for (`EnableTiltAsync`), or it was turned off (`DisableTilt`).
- `TILT_STATUS_WAITING_FOR_TAP`: The tilt waits for the next tap, where the system asks for permission.
- `TILT_STATUS_STARTING`: The tilt was asked for (`EnableTiltAsync`), and the first reading is awaited. The first reading turns the tilt on. After a second and a half without a reading, the tilt is unavailable.
- `TILT_STATUS_ON`: The tilt is read.
- `TILT_STATUS_REFUSED`: Permission was refused.
- `TILT_STATUS_UNAVAILABLE`: The device gives no readings: there is no sensor, or none answered.
- `TILT_STATUS_NEEDS_HTTPS`: The program isn't served securely, and the system gives no readings.
- `IsPlatformWeb`: Returns whether the program is built for a browser page rather than natively. See `GetPlatformOS` for naming the operating system.
  - returns: True in a page.

  It is known as the program builds, so the code for the other target drops out of the build, as `#if js` does.

### device: the safe area, the device, the window's abilities, orientation and tilt

```haxe
static function GetWindowSafeArea():Rectangle
static function GetPlatformOS():String
static function IsTouchAvailable():Bool
static function IsFinePointerAvailable():Bool
static function IsWindowCloseable():Bool
static function IsFullscreenAvailable():Bool
static function SetScreenOrientationAsync(orientation:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function GetScreenOrientation():Int
static function EnableTiltAsync(?done:() -> Void, ?failed:String -> Void):Void
static function DisableTilt():Void
static function GetTilt():Vector2
static function SetTiltRange(degrees:Float):Void
static function GetTiltStatus():Int
static function IsTiltCalibrating():Bool
static function IsTiltReady():Bool
static function CalibrateTilt():Void
```

- `GetWindowSafeArea`: Returns the part of the window no notch, rounded corner or system bar covers, in the screen's coordinates as `GetScreenWidth` measures them.
  - returns: The safe area.

  A HUD and buttons go inside it.

  Where nothing covers the window, as on a desktop, it is the whole window.
- `GetPlatformOS`: Returns the operating system's name in lowercase, or "" where the platform names none. See `IsPlatformWeb` for whether the program is built for a page.
  - returns: The system's name.

  The names are "windows", "macos", "linux", "android", "ios" and "chromeos".
- `IsTouchAvailable`: Returns whether the device has touch. A trackpad isn't touch. See `IsFinePointerAvailable` for whether there is a mouse, a trackpad or a pen.
  - returns: True with touch.

  A laptop may have both touch and a mouse.
- `IsFinePointerAvailable`: Returns whether the device has a fine pointer, such as a mouse, a trackpad or a pen. See `IsTouchAvailable` for whether there is touch.
  - returns: True with a fine pointer.

  False on a phone or a tablet alone.
- `IsWindowCloseable`: Returns whether `CloseWindow` removes the window. Where it doesn't, the window stays, cleared, and a game may hide its Quit.
  - returns: True where `CloseWindow` removes the window.
- `IsFullscreenAvailable`: Returns whether the window can go fullscreen. See `ToggleFullscreen` for asking for it.
  - returns: True where `ToggleFullscreen` can be granted.

  False where the system doesn't allow it, as on an iPhone.
- `SetScreenOrientationAsync`: Asynchronously asks for the screen to be held one way up, or released. See `GetScreenOrientation` for reading how it is held.
  - `orientation`: `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`, or `ORIENTATION_ANY` to release a lock.
  - `done`: Optional. Called once the screen is held, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  Refused where the system doesn't hold the screen, as natively and on iOS. Some systems hold it only in fullscreen, so a program asks once `IsWindowFullscreen()` is true.

  Where the lock is refused, a game shows "turn your device" when the shape is wrong (`GetScreenWidth() < GetScreenHeight()`).

  A value that isn't an `ORIENTATION_` value is refused.
- `GetScreenOrientation`: Returns how the screen is held for the program, as `SetScreenOrientationAsync` asked, or `ORIENTATION_ANY` when it isn't held.
  - returns: `ORIENTATION_ANY`, `ORIENTATION_LANDSCAPE` or `ORIENTATION_PORTRAIT`.

  The screen is let go as the window leaves fullscreen.
- `EnableTiltAsync`: Asynchronously asks for the device's tilt readings, for a game steered by tilting a phone. See `GetTilt` for reading them and `DisableTilt` for stopping them.
  - `done`: Optional. Called once readings arrive, at a later poll.
  - `failed`: Optional. Receives why there will be none: refused, not served securely, or no sensor; when omitted, it is logged.

  Refused where the device has no tilt sensor, as natively.

  The system may ask for permission at the next tap. A game asks before the tap that starts play, and that tap also asks for permission.
- `DisableTilt`: Stops the tilt's readings. See `EnableTiltAsync` for asking for them.
  A permission granted stays granted.
- `GetTilt`: Returns the tilt from level, turned with the screen, each axis -1 to 1. See `CalibrateTilt` for setting what reads as level.
  - returns: The tilt.

  x is across the screen and y is down it.

  A full tilt of 1 is `SetTiltRange`'s angle.

  The tilt is 0 until readings arrive, and while level is being taken (`IsTiltCalibrating`).
- `SetTiltRange`: Sets the angle, in degrees, that reads as a full tilt of 1. It defaults to 30.
  - `degrees`: The angle.
- `GetTiltStatus`: Returns the tilt's status: `TILT_STATUS_OFF`, `TILT_STATUS_WAITING_FOR_TAP`, `TILT_STATUS_STARTING`, `TILT_STATUS_ON`, `TILT_STATUS_REFUSED`, `TILT_STATUS_UNAVAILABLE` or `TILT_STATUS_NEEDS_HTTPS`. A game shows "tap to allow tilt" while the tilt waits for a tap.
  - returns: The status.
- `IsTiltCalibrating`: Returns whether level is being taken: the tilt is on, and reads 0 until the device is held steady for half a second. Level is taken when the readings start, after the screen turns, and after `CalibrateTilt`. A game shows "hold steady" meanwhile.
  - returns: True while level is being taken.
- `IsTiltReady`: Returns whether the tilt steers: the tilt is on (`TILT_STATUS_ON`) and level is taken (`IsTiltCalibrating` is false). A game starts a race, or resumes one, while this is true.
  - returns: True while the tilt steers.
- `CalibrateTilt`: Takes level again: the tilt reads 0 until the device is held steady for half a second, and how the device is held then becomes level (`IsTiltCalibrating`). A game's "Level" button is this call. See `GetTilt` for reading the tilt from level.
