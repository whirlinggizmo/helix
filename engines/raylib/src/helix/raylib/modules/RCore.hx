package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.math.Quaternion3D;
import helix.math.Trig;
import helix.math.Vector3D;
import helix.raylib.internal.Answers;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.DroppedFiles;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.internal.CallbackFiles;
import helix.raylib.internal.Automation;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
#end

/** Provides raylib's rcore: the window and the frame, the keyboard, mouse, touch and gamepads, files, the 2D and 3D cameras and shaders.

	`Raylib` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RCore {
	#if !macro
	// ---- Window and frame ----

	/** Opens the window and its graphics.

		Seeds `GetRandomValue` from the time, unless `SetRandomSeed` was called first.

		@param width  The window's width, in pixels.
		@param height  The window's height, in pixels.
		@param title  The window's title. */
	static function InitWindow(width:Int, height:Int, title:String):Void {
		Runtime.open(width, height, title);
		start = Runtime.system.getTime();
		// raylib seeds its random numbers from the time, unless SetRandomSeed says otherwise.
		if (!seeded)
			SetRandomSeed(Std.int(Date.now().getTime() % 0x7fffffff));
	}

	/** Closes the window, after keeping what `SaveFileTextAsync` wrote. The program goes on after it: the code after the call runs.

		The window shows nothing after it, and its keys, mouse, touch and gamepads are no longer read. */
	static function CloseWindow():Void {
		Runtime.close();
	}

	/** Returns whether the window should close, after the exit key is pressed or the window is asked to close.

		The exit key is Escape unless `SetExitKey` changed it.

		@return  True once the window should close. */
	static function WindowShouldClose():Bool {
		#if js
		if (++Runtime.unframed > 100000)
			throw "WindowShouldClose: called 100000 times since the last EndDrawing(). Call EndDrawing() once a frame in the loop.";
		#end
		return Runtime.shouldClose;
	}

	/** Returns whether the window is open.

		@return  True after `InitWindow`, until `CloseWindow`. */
	static function IsWindowReady():Bool {
		return Runtime.window != null && !Runtime.closed;
	}

	/** Returns whether the window changed size since the last frame.

		@return  True for the frame after a resize. */
	static function IsWindowResized():Bool {
		return Runtime.screen.resized;
	}

	/** Sets the window's title.

		@param title  The title. */
	static function SetWindowTitle(title:String):Void {
		Runtime.window.title = title;
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowSizeAsync` for asking for a size.

		@param width  The width, in pixels.
		@param height  The height, in pixels. */
	@:unsupported("SetWindowSize: The window changes later, or is refused. See SetWindowSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowSize(width:Int, height:Int):Void {
		throw "SetWindowSize is unimplemented";
	}

	/** Returns whether the window is fullscreen, false for a borderless window (`ToggleBorderlessWindowedAsync`).

		@return  True while it is. */
	static function IsWindowFullscreen():Bool {
		return Runtime.screen.fullscreen && !Runtime.borderless;
	}

	/** Returns whether the window is hidden (`FLAG_WINDOW_HIDDEN`).

		@return  True while it is. */
	static function IsWindowHidden():Bool {
		return !Runtime.window.visible;
	}

	/** Returns whether the window is minimized.

		@return  True while it is. */
	static function IsWindowMinimized():Bool {
		return Runtime.window.minimized || Runtime.hidden;
	}

	/** Returns whether the window is maximized.

		@return  True while it is. */
	static function IsWindowMaximized():Bool {
		return Runtime.window.maximized;
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `MaximizeWindowAsync` for asking for the window
		maximized. */
	@:unsupported("MaximizeWindow: The window changes later, or is refused. See MaximizeWindowAsync(?done:Void->Void, ?failed:String->Void)")
	static function MaximizeWindow():Void {
		throw "MaximizeWindow is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `MinimizeWindowAsync` for asking for the window
		minimized. */
	@:unsupported("MinimizeWindow: The window changes later, or is refused. See MinimizeWindowAsync(?done:Void->Void, ?failed:String->Void)")
	static function MinimizeWindow():Void {
		throw "MinimizeWindow is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `RestoreWindowAsync` for asking for the window
		restored. */
	@:unsupported("RestoreWindow: The window changes later, or is refused. See RestoreWindowAsync(?done:Void->Void, ?failed:String->Void)")
	static function RestoreWindow():Void {
		throw "RestoreWindow is unimplemented";
	}

	/** Doesn't compile on any target, since the window gets the keyboard later or not at all. See `SetWindowFocusedAsync` for asking for the
		keyboard. */
	@:unsupported("SetWindowFocused: The window changes later, or is refused. See SetWindowFocusedAsync(?done:Void->Void, ?failed:String->Void)")
	static function SetWindowFocused():Void {
		throw "SetWindowFocused is unimplemented";
	}

	/** Sets the window's icon. See `SetWindowIcons` for giving several sizes.

		The image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. Another format logs a warning and changes nothing.

		An image with no data is ignored.

		@param image  The icon. */
	static function SetWindowIcon(image:Image):Void {
		if (image.data == null)
			return;
		if (image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
			Runtime.log(LOG_WARNING, "GLFW: Window icon image must be in R8G8B8A8 pixel format");
			return;
		}
		Runtime.window.setIcon(image.width, image.height, image.data);
	}

	/** Sets the window's icon from several sizes, using the largest.

		Each image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. One in another format logs a warning and changes nothing.

		@param images  The icons.
		@param count  How many of them. */
	static function SetWindowIcons(images:Array<Image>, count:Int):Void {
		var largest:Null<Image> = null;
		for (i in 0...count) {
			var image = images[i];
			if (image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
				Runtime.log(LOG_WARNING, "GLFW: Window icon image must be in R8G8B8A8 pixel format");
				return;
			}
			if (image.data != null && (largest == null || image.width * image.height > largest.width * largest.height))
				largest = image;
		}
		if (largest != null)
			Runtime.window.setIcon(largest.width, largest.height, largest.data);
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowOpacityAsync` for asking for an opacity.

		Refused by a desktop without a compositor.

		@param opacity  From 0 (clear) to 1 (opaque). */
	@:unsupported("SetWindowOpacity: The window changes later, or is refused. See SetWindowOpacityAsync(opacity:Float, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowOpacity(opacity:Float):Void {
		throw "SetWindowOpacity is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowMinSizeAsync` for asking for the smallest
		size the window may take.

		@param width  The width, in the screen's pixels.
		@param height  The height. */
	@:unsupported("SetWindowMinSize: The window changes later, or is refused. See SetWindowMinSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowMinSize(width:Int, height:Int):Void {
		throw "SetWindowMinSize is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowMaxSizeAsync` for asking for the largest
		size the window may take.

		@param width  The width, in the screen's pixels.
		@param height  The height. */
	@:unsupported("SetWindowMaxSize: The window changes later, or is refused. See SetWindowMaxSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowMaxSize(width:Int, height:Int):Void {
		throw "SetWindowMaxSize is unimplemented";
	}

	/** Returns how many times a second a monitor shows a new picture.

		@param monitor  The monitor.
		@return  The refresh rate in hertz, or 0 when it isn't known. */
	static function GetMonitorRefreshRate(monitor:Int):Int {
		return Math.round(Runtime.window.getMonitorRefreshRate(monitor));
	}

	/** Opens a URL in the system's browser.

		Opens only http, https and mailto URLs.

		A URL with `'` or `"` logs a warning and doesn't open.

		A URL that fails to open logs a warning.

		@param url  The URL. */
	static function OpenURL(url:String):Void {
		if (url.indexOf("'") >= 0 || url.indexOf('"') >= 0)
			Runtime.log(LOG_WARNING, "SYSTEM: Provided URL could be potentially malicious, avoid [\'\"] characters");
		else if (!Runtime.system.openUrl(url))
			Runtime.log(LOG_WARNING, 'SYSTEM: Failed to open URL: $url');
	}

	/** Doesn't compile on any target, since the clipboard is written later or is refused. See `SetClipboardTextAsync` for writing the
		clipboard.

		@param text  The text. */
	@:unsupported("SetClipboardText: The clipboard is written later, or is refused. See SetClipboardTextAsync(text:String, ?done:Void->Void, ?failed:String->Void)")
	static function SetClipboardText(text:String):Void {
		throw "SetClipboardText is unimplemented";
	}

	/** Doesn't compile on any target, since the clipboard answers later. See `GetClipboardTextAsync` for reading the clipboard.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("GetClipboardText: Synchronous clipboard access is not supported. See GetClipboardTextAsync(read:String->Void, ?failed:String->Void)")
	static function GetClipboardText():String {
		throw "GetClipboardText is unimplemented";
	}

	/** Doesn't compile on any target, since the clipboard answers later. See `GetClipboardImageAsync` for reading an image from the
		clipboard.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("GetClipboardImage: Synchronous clipboard access is not supported. See GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void)")
	static function GetClipboardImage():Image {
		throw "GetClipboardImage is unimplemented";
	}

	/** Doesn't compile, since helix-raylib's window has no native handle to give.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("GetWindowHandle: The native window's handle is the platform's own and is not given out.")
	static function GetWindowHandle():Dynamic {
		throw "GetWindowHandle is unimplemented";
	}

	/** Doesn't compile, since SDL3 doesn't tell a monitor's physical size. See `GetMonitorWidth` for reading the width in pixels.

		@param monitor  The monitor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("GetMonitorPhysicalWidth: A monitor's physical size is not known to helix-raylib's platform.")
	static function GetMonitorPhysicalWidth(monitor:Int):Int {
		throw "GetMonitorPhysicalWidth is unimplemented";
	}

	/** Doesn't compile, since SDL3 doesn't tell a monitor's physical size. See `GetMonitorHeight` for reading the height in pixels.

		@param monitor  The monitor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("GetMonitorPhysicalHeight: A monitor's physical size is not known to helix-raylib's platform.")
	static function GetMonitorPhysicalHeight(monitor:Int):Int {
		throw "GetMonitorPhysicalHeight is unimplemented";
	}

	/** Returns whether the window has the keyboard.

		@return  True while it has. */
	static function IsWindowFocused():Bool {
		return Runtime.window.focused;
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `ToggleFullscreenAsync` for asking for fullscreen. */
	@:unsupported("ToggleFullscreen: The window changes later, or is refused. See ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void)")
	static function ToggleFullscreen():Void {
		throw "ToggleFullscreen is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `ToggleBorderlessWindowedAsync` for asking for a
		borderless window. */
	@:unsupported("ToggleBorderlessWindowed: The window changes later, or is refused. See ToggleBorderlessWindowedAsync(?done:Void->Void, ?failed:String->Void)")
	static function ToggleBorderlessWindowed():Void {
		throw "ToggleBorderlessWindowed is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowPositionAsync` for asking for a place on
		the desktop.

		Refused where the system doesn't allow it, as Wayland doesn't.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels. */
	@:unsupported("SetWindowPosition: The window changes later, or is refused. See SetWindowPositionAsync(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowPosition(x:Int, y:Int):Void {
		throw "SetWindowPosition is unimplemented";
	}

	/** Doesn't compile on any target, since the window changes later or is refused. See `SetWindowMonitorAsync` for asking for another
		monitor.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`. */
	@:unsupported("SetWindowMonitor: The window changes later, or is refused. See SetWindowMonitorAsync(monitor:Int, ?done:Void->Void, ?failed:String->Void)")
	static function SetWindowMonitor(monitor:Int):Void {
		throw "SetWindowMonitor is unimplemented";
	}

	/** Returns the window's place on the desktop.

		@return  Its left and top edges, in pixels. */
	static function GetWindowPosition():Vector2 {
		return new Vector2(Runtime.window.x, Runtime.window.y);
	}

	/** Returns how many of the display's pixels a pixel drawn takes, across and down, 2 on most phones and high-density displays.

		@return  The scale. */
	static function GetWindowScaleDPI():Vector2 {
		return new Vector2(Runtime.window.pixelRatio, Runtime.window.pixelRatio);
	}

	/** Returns the number of monitors.

		@return  The count, at least 1. */
	static function GetMonitorCount():Int {
		return Runtime.window.monitorCount;
	}

	/** Returns the monitor holding the window.

		@return  Its index. */
	static function GetCurrentMonitor():Int {
		return Runtime.window.monitorIndex;
	}

	/** Returns a monitor's top-left corner on the desktop.

		@param monitor  The monitor.
		@return  The corner, in pixels. */
	static function GetMonitorPosition(monitor:Int):Vector2 {
		return new Vector2(Runtime.window.getMonitorX(monitor), Runtime.window.getMonitorY(monitor));
	}

	/** Returns a monitor's width.

		@param monitor  The monitor.
		@return  The width, in pixels. */
	static function GetMonitorWidth(monitor:Int):Int {
		return Runtime.window.getMonitorWidth(monitor);
	}

	/** Returns a monitor's height.

		@param monitor  The monitor.
		@return  The height, in pixels. */
	static function GetMonitorHeight(monitor:Int):Int {
		return Runtime.window.getMonitorHeight(monitor);
	}

	/** Returns a monitor's name.

		@param monitor  The monitor.
		@return  The name. */
	static function GetMonitorName(monitor:Int):String {
		return Runtime.window.getMonitorName(monitor);
	}

	/** Returns the screen's width, in the pixels drawing is in. See `GetRenderWidth` for reading the framebuffer's width.

		@return  The width. */
	static function GetScreenWidth():Int {
		return Std.int(Runtime.screen.width);
	}

	/** Returns the screen's height, in the pixels drawing is in. See `GetRenderHeight` for reading the framebuffer's height.

		@return  The height. */
	static function GetScreenHeight():Int {
		return Std.int(Runtime.screen.height);
	}

	/** Returns the framebuffer's width, in the display's pixels. See `GetScreenWidth` for reading the width drawing is in.

		@return  The width. */
	static function GetRenderWidth():Int {
		return Runtime.window.framebufferWidth;
	}

	/** Returns the framebuffer's height, in the display's pixels. See `GetScreenHeight` for reading the height drawing is in.

		@return  The height. */
	static function GetRenderHeight():Int {
		return Runtime.window.framebufferHeight;
	}

	/** Sets flags for the window before `InitWindow` (`FLAG_*`).

		`FLAG_MSAA_4X_HINT` asks for 4 samples a pixel.

		`FLAG_VSYNC_HINT` shows frames at the display's refresh. Without it, frames show as soon as they are drawn.

		The window is resizable whatever the flags.

		@param flags  The flags, or'd together. */
	static function SetConfigFlags(flags:Int):Void {
		configFlags = flags;
	}

	/** Sets flags on the open window (`FLAG_*`).

		Changes nothing on the window itself, which stays resizable. `IsWindowState` reads the flags back.

		@param flags  The flags, or'd together. */
	static function SetWindowState(flags:Int):Void {
		configFlags |= flags;
	}

	/** Clears flags on the open window (`FLAG_*`).

		@param flags  The flags, or'd together. */
	static function ClearWindowState(flags:Int):Void {
		configFlags &= ~flags;
	}

	/** Returns whether flags are set on the window.

		`FLAG_FULLSCREEN_MODE` and `FLAG_BORDERLESS_WINDOWED_MODE` read what the window is now, as `IsWindowFullscreen` does.

		@param flag  The flags, or'd together.
		@return  True when all of them are. */
	static function IsWindowState(flag:Int):Bool {
		var flags = configFlags & ~(FLAG_FULLSCREEN_MODE | FLAG_BORDERLESS_WINDOWED_MODE);
		if (IsWindowFullscreen())
			flags |= FLAG_FULLSCREEN_MODE;
		if (Runtime.borderless)
			flags |= FLAG_BORDERLESS_WINDOWED_MODE;
		return flags & flag == flag;
	}

	/** Sets the most frames a second, for `EndDrawing` to wait out the rest of each frame.

		@param fps  The frames a second, or 0 for no limit. */
	static function SetTargetFPS(fps:Int):Void {
		Runtime.time.targetDelta = fps < 1 ? 0 : 1 / fps;
	}

	/** Returns the frames a second, averaged over the last half second or so.

		@return  The frames a second. */
	static function GetFPS():Int {
		return Runtime.time == null ? 0 : Math.round(Runtime.time.fps);
	}

	/** Returns the seconds the last frame took.

		@return  The seconds. */
	static function GetFrameTime():Float {
		return Runtime.time == null ? 0 : Runtime.time.realDelta;
	}

	/** Stops the program for a time, drawing nothing and reading no input until it ends.

		@param seconds  How long. */
	static function WaitTime(seconds:Float):Void {
		Runtime.sleep(seconds);
	}

	/** Returns the seconds since `InitWindow`.

		@return  The seconds. */
	static function GetTime():Float {
		return Runtime.system.getTime() - start;
	}

	/** Sets the key that closes the window, or `KEY_NULL` for none.

		Escape until set.

		@param key  The key. */
	static function SetExitKey(key:Int):Void {
		Runtime.exitKey = key;
	}

	/** Begins a frame's drawing. */
	static function BeginDrawing():Void {
		Runtime.beginDrawing();
		Runtime.frame.begin(GetScreenWidth(), GetScreenHeight());
	}

	/** Ends a frame's drawing and shows it, then waits out the rest of the frame (`SetTargetFPS`) and reads the next frame's input.

		Built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`, only ends the drawing. The program then
		calls `SwapScreenBuffer` to show the frame, `WaitTime` to wait and `PollInputEvents` to read the input. */
	static function EndDrawing():Void {
		Runtime.endFrame();
	}

	/** Shows the frame `EndDrawing` ended, for a program built with `-D helix-raylib-custom-frame-control`.

		Does nothing without the define, as `EndDrawing` has shown the frame already.

		A frame not shown by the next `EndDrawing` is shown then. */
	static function SwapScreenBuffer():Void {
		if (Runtime.frame != null)
			Runtime.frame.present();
	}

	/** Reads the input that came since the last read: each key's, button's and finger's state, and the window's events.

		`EndDrawing` reads the input already, unless the program is built with `-D helix-raylib-custom-frame-control`.

		A second read starts a new frame of input, so a key pressed before it reads as held.

		With `EnableEventWaiting`, waits for an event first. */
	static function PollInputEvents():Void {
		if (Runtime.events != null)
			Runtime.poll();
	}

	/** Makes each frame wait for an event before the next is read. See `DisableEventWaiting` for going back to reading the events
		there are.

		An event is a key, a mouse button, the mouse moving or the window changing, from a device the program reads.

		The program draws nothing while waiting, and uses little time.

		The platform and helix-raylib's async loads are still served, so a load answers while waiting and is drawn after the next event. */
	static function EnableEventWaiting():Void {
		Runtime.eventWaiting = true;
	}

	/** Makes each frame read the events there are and go on, the default until `EnableEventWaiting`. */
	static function DisableEventWaiting():Void {
		Runtime.eventWaiting = false;
	}

	/** Clears the frame to a color, dropping what was drawn before it.

		@param color  The color. */
	static function ClearBackground(color:Color):Void {
		Runtime.frame.clear((color.a << 24) | (color.r << 16) | (color.g << 8) | color.b);
	}

	/** Returns a random whole number from min to max, both included, from raylib's generator. See `LoadRandomSequence` for drawing several
		numbers with none twice.

		The generator is xoshiro128** (helix-math's `Random`), so a seed gives the numbers raylib's gives.

		min and max are swapped when min is more.

		@param min  The least.
		@param max  The most.
		@return  The number. */
	static function GetRandomValue(min:Int, max:Int):Int {
		if (min > max) {
			var t = min;
			min = max;
			max = t;
		}
		return randomIn(min, max);
	}

	/** Seeds `GetRandomValue` and `LoadRandomSequence`.

		The numbers repeat from the same seed, and are the ones raylib's give.

		Until called, `InitWindow` seeds from the time.

		@param seed  The seed, read as unsigned. */
	static function SetRandomSeed(seed:Int):Void {
		random.seed = seed;
		seeded = true;
	}

	// A whole number below 2^53 as its low 32 bits.
	static function word(value:Float):Int {
		var low = value % 4294967296.0;
		return low >= 2147483648.0 ? Std.int(low - 4294967296.0) : Std.int(low);
	}

	/** Returns numbers from min to max, both included, none twice, from `GetRandomValue`'s generator.

		A seed gives the numbers raylib's gives.

		min and max aren't swapped. When min is more, the numbers run from min up by the range's size.

		@param count  How many.
		@param min  The least.
		@param max  The most.
		@return  The numbers, or null when there are fewer than count in the range. */
	static function LoadRandomSequence(count:Int, min:Int, max:Int):Null<Array<Int>> {
		var span = unsigned(rangeSpan(min, max));
		if (unsigned(count) > span)
			return null;
		var sequence:Array<Int> = [];
		while (sequence.length < count) {
			var value = randomIn(min, max);
			if (sequence.indexOf(value) < 0)
				sequence.push(value);
		}
		return sequence;
	}

	/** Frees numbers `LoadRandomSequence` gave.

		Has nothing to free.

		@param sequence  The numbers. */
	static function UnloadRandomSequence(sequence:Null<Array<Int>>):Void {}

	// raylib's rprand, helix-math's generator, in the state raylib's starts in until seeded.
	static final random = {
		var generator = new helix.math.Random();
		generator.state = [0x96ea83c1, 0x218b21e5, 0xaa91febd, 0x976414d4];
		generator;
	};

	// abs(max - min) + 1 as C's ints compute it, wrapping.
	static function rangeSpan(min:Int, max:Int):Int {
		var d = (max - min) | 0;
		return ((d < 0 ? -d : d) + 1) | 0;
	}

	// A number from the generator in min's range, as rprand's: its 32 bits modulo the range's size, both unsigned, plus min, wrapping.
	static function randomIn(min:Int, max:Int):Int {
		return word(unsigned(random.nextBits()) % unsigned(rangeSpan(min, max)) + unsigned(min));
	}

	// A 32-bit number read as unsigned.
	static inline function unsigned(value:Int):Float {
		return value < 0 ? value + 4294967296.0 : value;
	}

	// ---- Keyboard ----

	/** Returns whether a key went down this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	static function IsKeyPressed(key:Int):Bool {
		var k = toKey(key), played = Runtime.played;
		if (played != null)
			return k >= 0 && !played.previousKeys[k] && played.keys[k];
		return k >= 0 && Runtime.keyboard().isKeyPressed(cast k);
	}

	/** Returns whether a key is held.

		@param key  The key (`KEY_*`).
		@return  True while it is down. */
	static function IsKeyDown(key:Int):Bool {
		var k = toKey(key), played = Runtime.played;
		if (played != null)
			return k >= 0 && played.keys[k];
		return k >= 0 && Runtime.keyboard().isKeyDown(cast k);
	}

	/** Returns whether a key went up this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	static function IsKeyReleased(key:Int):Bool {
		var k = toKey(key), played = Runtime.played;
		if (played != null)
			return k >= 0 && played.previousKeys[k] && !played.keys[k];
		return k >= 0 && Runtime.keyboard().isKeyReleased(cast k);
	}

	/** Returns whether a key isn't held.

		@param key  The key (`KEY_*`).
		@return  True while it is up. */
	static function IsKeyUp(key:Int):Bool {
		return !IsKeyDown(key);
	}

	/** Returns the next key pressed this frame, each key once. See `GetCharPressed` for reading typed text.

		A loop calling it until it returns `KEY_NULL` reads every key pressed.

		@return  The key (`KEY_*`), or `KEY_NULL` when no more were pressed. */
	static function GetKeyPressed():Int {
		Runtime.keyboard();
		return Runtime.keysPressed.length == 0 ? KEY_NULL : Runtime.keysPressed.shift();
	}

	/** Returns whether the system repeated a held key this frame.

		The system starts repeating a key after a moment, at its own rate.

		@param key  The key (`KEY_*`).
		@return  True for the frames it repeated. */
	static function IsKeyPressedRepeat(key:Int):Bool {
		Runtime.keyboard();
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyRepeated(cast k);
	}

	/** Returns the next character typed this frame, each once. See `GetKeyPressed` for reading keys.

		A loop calling it until it returns 0 reads every character typed.

		Typed text is read from the first call on, so a phone's keyboard shows from then.

		@return  The character's codepoint, or 0 when no more were typed. */
	static function GetCharPressed():Int {
		Runtime.typing();
		return Runtime.charsPressed.length == 0 ? 0 : Runtime.charsPressed.shift();
	}

	// ---- Mouse and touch ----

	/** Returns whether a mouse button went down this frame.

		A free finger (`EnableVirtualGamepad`) touching counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsMouseButtonPressed(button:Int):Bool {
		var played = Runtime.played;
		if (played != null)
			return button >= 0 && button < 8 && !played.previousButtons[button] && played.buttons[button];
		return realButtonPressed(button);
	}

	// Whether a mouse button went down this frame, as the devices have it.
	static function realButtonPressed(button:Int):Bool {
		var mouse = Runtime.mouse();
		var pressed = Runtime.touch().pressed;
		// Pressed when no finger now down was down before this frame, so a finger that landed and lifted within the frame counts.
		if (button == MOUSE_BUTTON_LEFT
			&& pressed.length > 0
			&& [for (id in Runtime.touch().fingers) if (pressed.indexOf(id) < 0) id].length == 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonPressed(cast button);
	}

	/** Returns whether a mouse button is held.

		A finger down counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is down. */
	static function IsMouseButtonDown(button:Int):Bool {
		var played = Runtime.played;
		if (played != null)
			return button >= 0 && button < 8 && played.buttons[button];
		return realButtonDown(button);
	}

	// Whether a mouse button is held, as the devices have it.
	static function realButtonDown(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().fingers.length > 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonDown(cast button);
	}

	/** Returns whether a mouse button went up this frame.

		The last finger lifting counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsMouseButtonReleased(button:Int):Bool {
		var played = Runtime.played;
		if (played != null)
			return button >= 0 && button < 8 && played.previousButtons[button] && !played.buttons[button];
		return realButtonReleased(button);
	}

	// Whether a mouse button went up this frame, as the devices have it.
	static function realButtonReleased(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().released.length > 0 && Runtime.touch().fingers.length == 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonReleased(cast button);
	}

	/** Returns whether a mouse button isn't held.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is up. */
	static function IsMouseButtonUp(button:Int):Bool {
		return !IsMouseButtonDown(button);
	}

	/** Returns the mouse's x, in the screen's pixels, the first finger's while one is down.

		@return  The x. */
	static function GetMouseX():Int {
		return Std.int(GetMousePosition().x);
	}

	/** Returns the mouse's y, in the screen's pixels, the first finger's while one is down.

		@return  The y. */
	static function GetMouseY():Int {
		return Std.int(GetMousePosition().y);
	}

	/** Returns the mouse's position, in the screen's pixels, the first finger's while one is down.

		`SetMouseOffset`'s offset is added first, then `SetMouseScale`'s scale applied.

		@return  The position. */
	static function GetMousePosition():Vector2 {
		var played = Runtime.played;
		if (played != null)
			return new Vector2((played.mouseX + mouseOffsetX) * mouseScaleX, (played.mouseY + mouseOffsetY) * mouseScaleY);
		pointer();
		return new Vector2((lastPointerX + mouseOffsetX) * mouseScaleX, (lastPointerY + mouseOffsetY) * mouseScaleY);
	}

	// The pointer's position, as the devices have it, in the screen's pixels.
	static function realPointer():Vector2 {
		pointer();
		return new Vector2(lastPointerX, lastPointerY);
	}

	// Brings the pointer's position up to date: the first finger's while one is down, else the mouse's once it moves, in the screen's pixels.
	static function pointer():Void {
		var mouse = Runtime.mouse(),
			touch = Runtime.touch(),
			screen = Runtime.screen;
		var fingers = touch.fingers.length > 0 ? touch.fingers : touch.released;
		if (fingers.length > 0) {
			lastPointerX = screen.toDesignX(touch.getX(fingers[0]));
			lastPointerY = screen.toDesignY(touch.getY(fingers[0]));
		} else if (mouse.x != lastMouseX || mouse.y != lastMouseY) {
			lastMouseX = mouse.x;
			lastMouseY = mouse.y;
			lastPointerX = screen.toDesignX(mouse.x);
			lastPointerY = screen.toDesignY(mouse.y);
		}
	}

	/** Moves the mouse to a place on the screen.

		`GetMouseDelta` this frame includes the move.

		Where the system refuses, as Wayland does, the cursor stays. The position reads the place given until the
		mouse moves, and a warning says why, once a run for each reason.

		@param x  The place across, in the screen's pixels.
		@param y  The place down. */
	static function SetMousePosition(x:Int, y:Int):Void {
		var mouse = Runtime.mouse(), adapter = Runtime.mouseAdapter;
		if (!adapter.setPosition(Runtime.screen.toScreenX(x), Runtime.screen.toScreenY(y))) {
			if (!adapter.canSetPosition()) {
				if (!warnedMousePage)
					Runtime.log(LOG_WARNING, "INPUT: SetMousePosition can't move the cursor: a page doesn't let a program move it");
				warnedMousePage = true;
			} else {
				if (!warnedMouseRefused)
					Runtime.log(LOG_WARNING, "INPUT: SetMousePosition can't move the cursor: the system refused");
				warnedMouseRefused = true;
			}
		}
		lastMouseX = mouse.x;
		lastMouseY = mouse.y;
		lastPointerX = x;
		lastPointerY = y;
		var played = Runtime.played;
		if (played != null) {
			played.mouseX = x;
			played.mouseY = y;
		}
	}

	/** Sets what `GetMousePosition` adds to the mouse's position, before its scale.

		@param offsetX  Added across.
		@param offsetY  Added down. */
	static function SetMouseOffset(offsetX:Int, offsetY:Int):Void {
		mouseOffsetX = offsetX;
		mouseOffsetY = offsetY;
	}

	/** Sets what `GetMousePosition` multiplies the mouse's position by, after its offset.

		@param scaleX  The scale across.
		@param scaleY  The scale down. */
	static function SetMouseScale(scaleX:Float, scaleY:Float):Void {
		mouseScaleX = scaleX;
		mouseScaleY = scaleY;
	}

	/** Returns how far the wheel turned this frame, in both directions, right and forward positive. See `GetMouseWheelMove` for reading the
		larger direction alone.

		@return  The notches. */
	static function GetMouseWheelMoveV():Vector2 {
		var played = Runtime.played;
		if (played != null)
			return new Vector2(played.wheelX, played.wheelY);
		return realWheel();
	}

	// How far the wheel turned this frame, as the mouse has it.
	static function realWheel():Vector2 {
		var mouse = Runtime.mouse();
		return new Vector2(mouse.wheelX, mouse.wheelY);
	}

	/** Shows the cursor. */
	static function ShowCursor():Void {
		Runtime.mouse();
		Runtime.mouseAdapter.cursorVisible = true;
		cursorHidden = false;
	}

	/** Hides the cursor over the window. */
	static function HideCursor():Void {
		Runtime.mouse();
		Runtime.mouseAdapter.cursorVisible = false;
		cursorHidden = true;
	}

	/** Returns whether the cursor is hidden, by `HideCursor` or `DisableCursor`.

		@return  True while it is. */
	static function IsCursorHidden():Bool {
		return cursorHidden;
	}

	/** Doesn't compile on any target, since the mouse is let go later. See `EnableCursorAsync` for letting go of the mouse. */
	@:unsupported("EnableCursor: The mouse is let go later, or is refused. See EnableCursorAsync(?done:Void->Void, ?failed:String->Void)")
	static function EnableCursor():Void {
		throw "EnableCursor is unimplemented";
	}

	/** Doesn't compile on any target, since the mouse is locked later or refused. See `DisableCursorAsync` for locking the mouse. */
	@:unsupported("DisableCursor: The mouse is locked later, or is refused. See DisableCursorAsync(?done:Void->Void, ?failed:String->Void)")
	static function DisableCursor():Void {
		throw "DisableCursor is unimplemented";
	}

	/** Returns whether the mouse is over the window.

		@return  True from its first move over the window until it leaves. */
	static function IsCursorOnScreen():Bool {
		Runtime.mouse();
		return Runtime.cursorOnScreen;
	}

	/** Sets the cursor's shape, the system's own cursor of each kind.

		@param cursor  The shape (`MOUSE_CURSOR_*`). `MOUSE_CURSOR_DEFAULT` and `MOUSE_CURSOR_ARROW` are both the arrow. */
	static function SetMouseCursor(cursor:Int):Void {
		Runtime.mouse();
		Runtime.mouseAdapter.cursorShape = switch cursor {
			case MOUSE_CURSOR_IBEAM: Text;
			case MOUSE_CURSOR_CROSSHAIR: Crosshair;
			case MOUSE_CURSOR_POINTING_HAND: Pointer;
			case MOUSE_CURSOR_RESIZE_EW: ResizeHorizontal;
			case MOUSE_CURSOR_RESIZE_NS: ResizeVertical;
			case MOUSE_CURSOR_RESIZE_NWSE: ResizeDiagonalDown;
			case MOUSE_CURSOR_RESIZE_NESW: ResizeDiagonalUp;
			case MOUSE_CURSOR_RESIZE_ALL: Move;
			case MOUSE_CURSOR_NOT_ALLOWED: NotAllowed;
			case _: Arrow;
		}
	}

	/** Returns how far the wheel turned this frame, the larger of its two directions, forward positive. See `GetMouseWheelMoveV` for
		reading both directions.

		@return  The notches. */
	static function GetMouseWheelMove():Float {
		var wheel = GetMouseWheelMoveV();
		return Math.abs(wheel.x) > Math.abs(wheel.y) ? wheel.x : wheel.y;
	}

	/** Returns the number of fingers down, leaving out those a virtual gamepad (`EnableVirtualGamepad`) captured.

		@return  The count. */
	static function GetTouchPointCount():Int {
		var played = Runtime.played;
		if (played != null)
			return [for (down in played.touches) if (down) down].length;
		return Runtime.touch().fingers.length;
	}

	// Whether a finger is down, by its place, 0 for the first down, as the touch has it.
	static function realTouchDown(index:Int):Bool {
		return index < Runtime.touch().fingers.length;
	}

	// Where a finger is, by its place, as the touch has it, in the screen's pixels. The first, while none is down, is the pointer.
	static function realTouchPosition(index:Int):Vector2 {
		var touch = Runtime.touch();
		if (index == 0 && touch.fingers.length == 0)
			return realPointer();
		if (index < 0 || index >= touch.fingers.length)
			return new Vector2();
		var id = touch.fingers[index];
		return new Vector2(Runtime.screen.toDesignX(touch.getX(id)), Runtime.screen.toDesignY(touch.getY(id)));
	}

	/** Returns a finger's position, in the screen's pixels.

		While no finger is down, the first is where the mouse is. See `EnableVirtualGamepad`
		(`import helix.raylib.extras.VirtualGamepad.*;`) for on-screen sticks read as a gamepad's.

		@param index  Which finger, 0 for the first down.
		@return  The position, or (0, 0) when fewer are down. */
	static function GetTouchPosition(index:Int):Vector2 {
		var played = Runtime.played;
		if (played != null)
			return index >= 0 && index < 8 ? new Vector2(played.touchX[index], played.touchY[index]) : new Vector2();
		return realTouchPosition(index);
	}

	/** Returns a finger's id, which stays the same while it is down.

		@param index  Which finger, 0 for the first down.
		@return  The id, or -1 when fewer are down. */
	static function GetTouchPointId(index:Int):Int {
		var touch = Runtime.touch();
		return index >= 0 && index < touch.fingers.length ? touch.fingers[index] : -1;
	}

	/** Returns the first finger's x, in the screen's pixels, the mouse's while no finger is down.

		@return  The x. */
	static function GetTouchX():Int {
		return Std.int(GetTouchPosition(0).x);
	}

	/** Returns the first finger's y, in the screen's pixels, the mouse's while no finger is down.

		@return  The y. */
	static function GetTouchY():Int {
		return Std.int(GetTouchPosition(0).y);
	}

	/** Sets which gestures are detected.

		All gestures until called.

		@param flags  The gestures (`GESTURE_*`), or'd together. */
	static function SetGesturesEnabled(flags:Int):Void {
		Runtime.gestures().enabled = flags;
	}

	/** Returns whether a gesture is the one detected now.

		A mouse button counts as a finger.

		A tap or double tap lasts a frame, then becomes a hold. A swipe lasts a frame.

		@param gesture  The gesture (`GESTURE_*`).
		@return  True while it is the gesture, and enabled. */
	static function IsGestureDetected(gesture:Int):Bool {
		return GetGestureDetected() == gesture;
	}

	/** Returns the gesture detected now.

		@return  The gesture (`GESTURE_*`), or `GESTURE_NONE` when it isn't enabled. */
	static function GetGestureDetected():Int {
		var played = Runtime.played;
		if (played != null)
			return Runtime.gestures().enabled & played.gesture;
		return Runtime.gestures().current;
	}

	// The gesture detected now, as the gestures have it.
	static function realGesture():Int {
		return Runtime.gestures().current;
	}

	/** Returns how long the hold has lasted.

		@return  The seconds, or 0 when the gesture isn't `GESTURE_HOLD`. */
	static function GetGestureHoldDuration():Float {
		return Runtime.gestures().holdDuration;
	}

	/** Returns the drag, from where the finger landed to where it is, in fractions of the screen.

		@return  The vector. */
	static function GetGestureDragVector():Vector2 {
		var gestures = Runtime.gestures();
		return new Vector2(gestures.dragX, gestures.dragY);
	}

	/** Returns the last swipe's angle.

		@return  The degrees, counterclockwise from right. */
	static function GetGestureDragAngle():Float {
		return Runtime.gestures().dragAngle;
	}

	/** Returns the pinch, from the first finger to the second, in fractions of the screen.

		@return  The vector. */
	static function GetGesturePinchVector():Vector2 {
		var gestures = Runtime.gestures();
		return new Vector2(gestures.pinchX, gestures.pinchY);
	}

	/** Returns the pinch's angle.

		@return  The degrees, counterclockwise from right. */
	static function GetGesturePinchAngle():Float {
		return Runtime.gestures().pinchAngle;
	}

	// ---- Gamepads ----

	/** Shakes a gamepad, its left motor the heavy one and its right the light one.

		Shaking lasts at most 2 seconds.

		An empty slot is passed over.

		A gamepad that can't shake stays still and logs a warning, once a run.

		@param gamepad  The gamepad, 0 to 3.
		@param leftMotor  The heavy motor's strength, 0 to 1.
		@param rightMotor  The light motor's strength, 0 to 1.
		@param duration  How long, in seconds. */
	static function SetGamepadVibration(gamepad:Int, leftMotor:Float, rightMotor:Float, duration:Float):Void {
		if (!realGamepadReady(gamepad))
			return;
		if (!Runtime.gamepadsAdapter.setVibration(gamepad, leftMotor, rightMotor, Math.min(duration, 2))) {
			if (!warnedVibration)
				Runtime.log(LOG_WARNING,
					'GAMEPAD: [ID $gamepad] SetGamepadVibration can\'t shake it: ' +
					#if js "it has no motors, or the browser has no vibration" #else "it has no motors" #end);
			warnedVibration = true;
		}
	}

	/** Adds mappings for gamepads the system doesn't know, in SDL's controller database format.

		@param mappings  The mappings, one a line.
		@return  How many were added or updated, or 0 where the system maps gamepads itself. */
	static function SetGamepadMappings(mappings:String):Int {
		Runtime.gamepads();
		return Runtime.gamepadsAdapter.addMappings(mappings);
	}

	/** Returns whether a gamepad is connected.

		A virtual gamepad (`EnableVirtualGamepad`) counts. `IsGamepadVirtual` tells it from a physical one.

		@param gamepad  The gamepad, 0 to 3.
		@return  True while one is connected there. */
	static function IsGamepadAvailable(gamepad:Int):Bool {
		var played = Runtime.played;
		if (played != null)
			return gamepad >= 0 && gamepad < 4 && played.gamepads[gamepad];
		return realGamepadReady(gamepad);
	}

	// Whether a gamepad is connected, as the gamepads have it.
	static function realGamepadReady(gamepad:Int):Bool {
		return gamepad >= 0 && gamepad < 4 && Runtime.gamepads().isConnected(gamepad);
	}

	// Whether a gamepad's button is held, as the gamepads have it.
	static function realGamepadButtonDown(gamepad:Int, button:Int):Bool {
		var b = toGamepadButton(button);
		return b >= 0 && realGamepadReady(gamepad) && Runtime.gamepads().isButtonDown(gamepad, cast b);
	}

	// A gamepad's axis, as the gamepads have it.
	static function realGamepadAxis(gamepad:Int, axis:Int):Float {
		if (axis < 0 || axis > 5 || !realGamepadReady(gamepad))
			return 0;
		var value = Runtime.gamepads().getAxis(gamepad, cast axis);
		return axis >= GAMEPAD_AXIS_LEFT_TRIGGER ? value * 2 - 1 : value;
	}

	// A played gamepad button's state, now or the last frame, or null while nothing is played.
	static function playedGamepadButton(gamepad:Int, button:Int, previous:Bool):Null<Bool> {
		var played = Runtime.played;
		if (played == null)
			return null;
		if (gamepad < 0 || gamepad >= 4 || button < 0 || button >= 32 || !played.gamepads[gamepad])
			return false;
		return (previous ? played.previousGamepadButtons : played.gamepadButtons)[gamepad * 32 + button];
	}

	/** Returns a gamepad's name.

		@param gamepad  The gamepad, 0 to 3.
		@return  Its name, or "" when none is connected. */
	static function GetGamepadName(gamepad:Int):String {
		return IsGamepadAvailable(gamepad) ? Runtime.gamepads().getName(gamepad) : "";
	}

	/** Returns whether a gamepad's button went down this frame. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool {
		var now = playedGamepadButton(gamepad, button, false);
		if (now != null)
			return now && !playedGamepadButton(gamepad, button, true);
		var b = toGamepadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonPressed(gamepad, cast b);
	}

	/** Returns whether a gamepad's button is held. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is down. */
	static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool {
		var now = playedGamepadButton(gamepad, button, false);
		if (now != null)
			return now;
		var b = toGamepadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonDown(gamepad, cast b);
	}

	/** Returns whether a gamepad's button went up this frame. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool {
		var now = playedGamepadButton(gamepad, button, false);
		if (now != null)
			return !now && playedGamepadButton(gamepad, button, true);
		var b = toGamepadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonReleased(gamepad, cast b);
	}

	/** Returns whether a gamepad's button isn't held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is up. */
	static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool {
		return !IsGamepadButtonDown(gamepad, button);
	}

	/** Returns the last button held, polling the buttons as raylib does.

		The poll runs over gamepads 0 to 3, each's buttons in the platform's order.

		@return  The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held. */
	static function GetGamepadButtonPressed():Int {
		var last = GAMEPAD_BUTTON_UNKNOWN;
		for (gamepad in 0...4)
			if (IsGamepadAvailable(gamepad)) {
				for (button in pollOrder)
					if (IsGamepadButtonDown(gamepad, button))
						last = button;
				#if !js
				// GLFW has the second triggers as axes alone; raylib 6.2 counts each as held past 0.1.
				if (GetGamepadAxisMovement(gamepad, GAMEPAD_AXIS_LEFT_TRIGGER) > 0.1)
					last = GAMEPAD_BUTTON_LEFT_TRIGGER_2;
				if (GetGamepadAxisMovement(gamepad, GAMEPAD_AXIS_RIGHT_TRIGGER) > 0.1)
					last = GAMEPAD_BUTTON_RIGHT_TRIGGER_2;
				#end
			}
		return last;
	}

	// raylib's buttons in the order its platform polls them: the standard gamepad's in a page, GLFW's on the desktop.
	static final pollOrder = #if js [7, 6, 8, 5, 9, 11, 10, 12, 13, 15, 16, 17, 1, 3, 4, 2] #else [7, 6, 8, 5, 9, 11, 13, 15, 14, 16, 17, 1, 2, 3, 4] #end;

	/** Returns the number of axes a gamepad has.

		@param gamepad  The gamepad, 0 to 3.
		@return  6 while one is connected, else 0. */
	static function GetGamepadAxisCount(gamepad:Int):Int {
		return IsGamepadAvailable(gamepad) ? 6 : 0;
	}

	/** Returns how far a gamepad's axis is pushed.

		A physical gamepad's axis reads raw. A virtual gamepad's sticks (`EnableVirtualGamepad`) read past their dead zone.

		A stick runs from -1 to 1, down and right positive.

		A trigger runs from -1 released to 1 pulled.

		@param gamepad  The gamepad, 0 to 3.
		@param axis  The axis (`GAMEPAD_AXIS_*`).
		@return  The value. */
	static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float {
		var played = Runtime.played;
		if (played != null)
			return gamepad >= 0
				&& gamepad < 4
				&& axis >= 0
				&& axis < 8
				&& played.gamepads[gamepad] ? played.gamepadAxes[gamepad * 8 + axis] : 0;
		return realGamepadAxis(gamepad, axis);
	}

	// ---- Files ----

	/** Returns whether a file exists, as `FileExistsAsync` answers it. See `DirectoryExists` for a directory.

		@param fileName  The file.
		@return  True when it exists. */
	@:waits
	static function FileExists(fileName:String, answer:Bool->Void):Void {
		RFilesAsync.FileExistsAsync(fileName, answer);
	}

	/** Reads a text file, as `LoadFileTextAsync` reads it, and returns its text. See `LoadFileData` for reading a file's bytes.

		@param fileName  The file.
		@return  Its text, or null when it couldn't be read. Why it couldn't is logged. */
	@:waits
	static function LoadFileText(fileName:String, answer:Null<String>->Void):Void {
		RFilesAsync.LoadFileTextAsync(fileName, answer, Answers.failing("LoadFileText", answer, null));
	}

	/** Frees text `LoadFileText` or `LoadFileTextAsync` gave.

		Has nothing to free.

		@param text  The text. */
	static function UnloadFileText(text:Null<String>):Void {}

	/** Writes a text file, as `SaveFileTextAsync` writes it, and returns once it is written. See `SaveFileData` for writing bytes.

		`LoadFileText` reads it back.

		@param fileName  The file.
		@param text  Its text.
		@return  Whether it was written. Why it wasn't is logged. */
	@:waits
	static function SaveFileText(fileName:String, text:String, answer:Bool->Void):Void {
		RFilesAsync.SaveFileTextAsync(fileName, text, answer.bind(true), Answers.failing("SaveFileText", answer, false));
	}

	// Writes a text file as SaveFileTextAsync does: through the program's SetSaveFileTextCallback when it has one, answered at a later
	// poll by what it returned; else kept in the saves, answered once they are written.
	static function writeText(fileName:String, text:String, written:Void->Void, failed:String->Void):Void {
		var path = normalize(fileName);
		if (saveText != null) {
			var wrote = saveText(path, text);
			Runtime.later(() -> wrote ? written() : failed('$path: the program\'s save callback didn\'t write it'));
			return;
		}
		keep(path, SAVED + path, text, written, failed);
	}

	// Writes a file's bytes as SaveFileDataAsync does: through the program's SetSaveFileDataCallback when it has one, else kept in the
	// saves.
	static function writeData(fileName:String, data:Null<haxe.io.Bytes>, dataSize:Int, written:Void->Void, failed:String->Void):Void {
		var path = normalize(fileName);
		if (data == null || dataSize < 0 || dataSize > data.length) {
			Runtime.later(() -> failed('$path: there are no $dataSize bytes to write'));
			return;
		}
		if (saveData != null) {
			var wrote = saveData(path, data, dataSize);
			Runtime.later(() -> wrote ? written() : failed('$path: the program\'s save callback didn\'t write it'));
			return;
		}
		keep(path, SAVED_DATA + path, haxe.crypto.Base64.encode(data.sub(0, dataSize)), written, failed);
	}

	// Keeps a file in the saves under its key, with the time it was written, once they are read; answered once they are written. Saves
	// that can't be read are left as they are.
	static function keep(path:String, key:String, value:String, written:Void->Void, failed:String->Void):Void {
		var time = Math.ffloor(Date.now().getTime() / 1000);
		Runtime.withSaves(saves -> {
			if (!saves.loaded) {
				failed('$path: the saves can\'t be read, so nothing is written to them');
				return;
			}
			saves.setString(key, value);
			saves.setFloat(SAVED_TIME + path, time);
			saves.flush(written, error -> failed('$path: $error'));
		});
	}

	/** Reads a file's bytes, as `LoadFileDataAsync` reads them, and returns them. See `LoadFileText` for reading a text file.

		@param fileName  The file.
		@return  Its bytes, or null when it couldn't be read. Why it couldn't is logged. */
	@:waits
	static function LoadFileData(fileName:String, answer:Null<haxe.io.Bytes>->Void):Void {
		RFilesAsync.LoadFileDataAsync(fileName, answer, Answers.failing("LoadFileData", answer, null));
	}

	/** Frees bytes `LoadFileData` or `LoadFileDataAsync` gave.

		Has nothing to free.

		@param data  The bytes. */
	static function UnloadFileData(data:Null<haxe.io.Bytes>):Void {}

	/** Writes a file's bytes, as `SaveFileDataAsync` writes them, and returns once they are written. See `SaveFileText` for writing
		text.

		`LoadFileData` reads them back.

		@param fileName  The file.
		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Whether they were written. Why they weren't is logged. */
	@:waits
	static function SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int, answer:Bool->Void):Void {
		RFilesAsync.SaveFileDataAsync(fileName, data, dataSize, answer.bind(true), Answers.failing("SaveFileData", answer, false));
	}

	/** Writes bytes as a C header, as `ExportDataAsCodeAsync` writes it, and returns once it is written.

		@param data  The bytes.
		@param dataSize  How many of them.
		@param fileName  The file; its name, upper case, names the define and the array.
		@return  Whether it was written. Why it wasn't is logged. */
	@:waits
	static function ExportDataAsCode(data:haxe.io.Bytes, dataSize:Int, fileName:String, answer:Bool->Void):Void {
		RFilesAsync.ExportDataAsCodeAsync(data, dataSize, fileName, answer.bind(true), Answers.failing("ExportDataAsCode", answer, false));
	}

	// ExportDataAsCodeAsync's text, as raylib's writes it, byte for byte.
	static function dataAsCode(data:haxe.io.Bytes, dataSize:Int, fileName:String):String {
		var text = new StringBuf();
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n");
		text.add("//                                                                                    //\n");
		text.add("// DataAsCode exporter v1.0 - Raw data exported as an array of bytes                  //\n");
		text.add("//                                                                                    //\n");
		text.add("// more info and bugs-report:  github.com/raysan5/raylib                              //\n");
		text.add("// feedback and support:       ray[at]raylib.com                                      //\n");
		text.add("//                                                                                    //\n");
		text.add("// Copyright (c) 2022-2024 Ramon Santamaria (@raysan5)                                //\n");
		text.add("//                                                                                    //\n");
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n\n");
		var name = new StringBuf(), base = GetFileNameWithoutExt(fileName);
		for (i in 0...base.length) {
			var c = StringTools.fastCodeAt(base, i);
			name.addChar(c >= "a".code
				&& c <= "z".code ? c - 32 : c == ".".code || c == "-".code || c == "?".code || c == "!".code || c == "+".code ? "_".code : c);
		}
		var varName = name.toString();
		text.add('#define ${varName}_DATA_SIZE     $dataSize\n\n');
		text.add('static unsigned char ${varName}_DATA[${varName}_DATA_SIZE] = { ');
		inline function at(i:Int):String
			return StringTools.hex(data != null && i >= 0 && i < data.length ? data.get(i) : 0).toLowerCase();
		for (i in 0...dataSize - 1)
			text.add(i % 20 == 0 ? '0x${at(i)},\n' : '0x${at(i)}, ');
		text.add('0x${at(dataSize - 1)} };\n');
		return text.toString();
	}

	// ---- Directories ----

	/** Returns the working directory. See `GetApplicationDirectory` for finding
		the program's files.

		`TakeScreenshotAsync` writes to it.

		helix-raylib's loads don't read from it. A file's name is under the program's files wherever the working directory is.

		@return  The directory, without a slash at its end. */
	static function GetWorkingDirectory():String {
		#if js
		return ".";
		#else
		return haxe.io.Path.removeTrailingSlashes(Sys.getCwd());
		#end
	}

	/** Returns the directory the program's files are read from.

		A load given a path in it reads the file the path names, so `GetApplicationDirectory() + "resources/a.png"` loads
		"resources/a.png".

		@return  The directory, with a slash at its end. */
	static function GetApplicationDirectory():String {
		#if js
		return "./";
		#else
		return haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize(haxe.io.Path.join([Runtime.system.getProgramDirectory(), Runtime.root])));
		#end
	}

	/** Changes the working directory.

		`TakeScreenshotAsync` writes to the new directory from then on.

		helix-raylib's loads are unchanged, reading the program's files wherever the working directory is.

		A failure logs a warning.

		@param dir  The directory.
		@return  True when the working directory is it now. */
	static function ChangeDirectory(dir:String):Bool {
		#if js
		var changed = dir == "." || dir == "./";
		#else
		// Sys.setCwd doesn't fail everywhere for a directory that isn't there, so it is looked for first.
		var changed = false;
		try {
			if (sys.FileSystem.exists(dir) && sys.FileSystem.isDirectory(dir)) {
				Sys.setCwd(dir);
				changed = true;
			}
		} catch (_:Dynamic) {}
		if (changed)
			Runtime.workingDirectoryChanged();
		#end
		if (!changed)
			Runtime.log(LOG_WARNING, 'SYSTEM: Failed to change to directory: $dir');
		return changed;
	}

	// ---- File names ----

	/** Returns whether a file name ends in one of some extensions, ignoring the case of A to Z.

		Up to 15 characters of the file's extension are compared, and the list's first 32 extensions.

		An extension in the list without its dot matches as well ("png" as ".png").

		@param fileName  The file name.
		@param ext  The extensions, `;` between them: ".png;.jpg".
		@return  True when its extension, from its last dot, is one of them. */
	static function IsFileExtension(fileName:String, ext:String):Bool {
		var fileExt = GetFileExtension(fileName);
		if (fileExt == null)
			return false;
		var fileExtLower = asciiLower(fileExt).substr(0, 15);
		var extList = asciiLower(ext).split(";");
		if (extList.length > 32)
			extList = extList.slice(0, 32);
		for (check in extList) {
			// An extension given without its dot is compared with the file's without its own.
			var own = check.charAt(0) != "." ? fileExtLower.substr(1) : fileExtLower;
			if (own == check)
				return true;
		}
		return false;
	}

	/** Returns a file name's extension, from its last dot: "file.tar.gz" gives ".gz".

		@param fileName  The file name, or a path.
		@return  The extension with its dot, or null when there is no dot or the name starts with its only one. */
	static function GetFileExtension(fileName:String):String {
		var dot = fileName.lastIndexOf(".");
		return dot <= 0 ? null : fileName.substr(dot);
	}

	/** Returns a path's file name, what follows its last `/` or `\`.

		@param filePath  The path.
		@return  The file name with its extension, or the path itself when it has no slash. */
	static function GetFileName(filePath:String):String {
		if (filePath == null)
			return null;
		return filePath.substr(lastSlash(filePath) + 1);
	}

	/** Returns a path's file name without its extension, up to its last dot unless that dot is its first character.

		@param filePath  The path.
		@return  The file name, or "" for null. */
	static function GetFileNameWithoutExt(filePath:String):String {
		if (filePath == null)
			return "";
		var name = GetFileName(filePath);
		var dot = name.lastIndexOf(".");
		return dot > 0 ? name.substr(0, dot) : name;
	}

	/** Returns the directory of a path, up to its last `/` or `\`.

		A relative path's directory starts "./": "dir/file.png" gives "./dir", "file.png" gives "./", and "/file.png" gives "/".

		@param filePath  The path.
		@return  The directory, without a slash at its end. */
	static function GetDirectoryPath(filePath:String):String {
		var first = filePath.charAt(0), second = filePath.charAt(1);
		// A path is relative unless it starts with a slash or a drive letter ("C:").
		var relative = second != ":" && first != "\\" && first != "/";
		var slash = lastSlash(filePath);
		if (slash < 0)
			return relative ? "./" : "";
		if (slash == 0)
			return first;
		return (relative ? "./" : "") + filePath.substr(0, slash);
	}

	/** Returns the directory a path is in, up to its last `/` or `\` but one at its end, keeping a root's ("/", "C:\").

		"/a/b/" gives "/a", "/a" gives "/" and "abc" gives "".

		Every path is taken as a directory's, so a path naming a file gives the file's directory.

		@param dirPath  The path.
		@return  The directory above it, or "" when there is none. */
	static function GetPrevDirectoryPath(dirPath:String):String {
		var lastIndex = dirPath.length - 1;
		var i = lastIndex;
		while (i >= 0) {
			var c = dirPath.charAt(i);
			if (c == "\\" || c == "/") {
				// A leading separator ("/usr") or a drive's root ("C:\") stays; one at the end ("/usr/bin/") is skipped.
				if (i == 0 || (i == 2 && dirPath.charAt(1) == ":"))
					i += 1;
				else if (i == lastIndex) {
					i--;
					continue;
				}
				return dirPath.substr(0, i);
			}
			i--;
		}
		return "";
	}

	/** Returns whether a file name could name a file on any system: none of `< > : " / \ | ? *` or a control character, and not
		only dots.

		@param fileName  The file name, without a directory.
		@return  True when it could, and true for null or "". */
	static function IsFileNameValid(fileName:String):Bool {
		if (fileName == null || fileName.length == 0)
			return true;
		var allPeriods = true;
		for (i in 0...fileName.length) {
			var c = StringTools.fastCodeAt(fileName, i);
			switch c {
				case "<".code | ">".code | ":".code | "\"".code | "/".code | "\\".code | "|".code | "?".code | "*".code:
					return false;
				case _ if (c < 32):
					return false;
				case _:
			}
			if (c != ".".code)
				allPeriods = false;
		}
		return !allPeriods;
	}

	// ---- Directories and dropped files ----

	/** Returns whether a directory exists, as `DirectoryExistsAsync` answers it. See `FileExists` for a file.

		@param dirPath  The directory.
		@return  True when it exists. */
	@:waits
	static function DirectoryExists(dirPath:String, answer:Bool->Void):Void {
		RFilesAsync.DirectoryExistsAsync(dirPath, answer);
	}

	/** Returns a file's size, as `GetFileLengthAsync` answers it.

		@param fileName  The file.
		@return  Its size in bytes; 0 when there is no file, as raylib's. */
	@:waits
	static function GetFileLength(fileName:String, answer:Int->Void):Void {
		RFilesAsync.GetFileLengthAsync(fileName, answer);
	}

	/** Makes a directory, succeeding for any path that could name one.

		Nothing is made, as a directory is there once a file is written under it.

		@param dirPath  The directory.
		@return  0 for success, 1 for null or "", and -1 for a path that can't name a directory. */
	static function MakeDirectory(dirPath:String):Int {
		if (dirPath == null || dirPath == "")
			return 1;
		var path = normalize(dirPath);
		while (path.length > 1 && StringTools.endsWith(path, "/"))
			path = path.substr(0, path.length - 1);
		return path == "" || path == "." || path == "/" || helix.platform.FilePath.isValid(path) ? 0 : -1;
	}

	// Whether a path is absolute, as raylib 6.2's TakeScreenshot finds it: natively on Windows one starting with `\\` or a drive letter,
	// a colon and a slash ("C:\", "D:/"); elsewhere, and in a page, one starting with `/`. False for null or "".
	static function isPathAbsolute(path:String):Bool {
		if (path == null || path == "")
			return false;
		#if windows
		if (StringTools.startsWith(path, "\\\\"))
			return true;
		var drive = path.charCodeAt(0);
		return ((drive >= "A".code && drive <= "Z".code)
			|| (drive >= "a".code && drive <= "z".code))
			&& path.charAt(1) == ":"
			&& (path.charAt(2) == "\\" || path.charAt(2) == "/");
		#else
		return path.charAt(0) == "/";
		#end
	}

	/** Returns whether a path is a file, not a directory, as `IsPathFileAsync` answers it. See `DirectoryExists` for a directory.

		@param path  The path.
		@return  True for a file; false for a directory or nothing there. */
	@:waits
	static function IsPathFile(path:String, answer:Bool->Void):Void {
		RFilesAsync.IsPathFileAsync(path, answer);
	}

	/** Lists a directory's files and subdirectories, as `LoadDirectoryFilesAsync` lists them. See `LoadDirectoryFilesEx` for a filter
		by extension and the subdirectories' files.

		@param dirPath  The directory.
		@return  The list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's. */
	@:waits
	static function LoadDirectoryFiles(dirPath:String, answer:FilePathList->Void):Void {
		RFilesAsync.LoadDirectoryFilesAsync(dirPath, answer);
	}

	/** Lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too, as `LoadDirectoryFilesExAsync`
		lists them. See `LoadDirectoryFiles` for listing one directory's every file and subdirectory.

		@param basePath  The directory.
		@param filter  The extensions kept, such as ".png;.jpg;DIR", or null for every file.
		@param scanSubdirs  Whether the subdirectories' files are listed too.
		@return  The list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning. */
	@:waits
	static function LoadDirectoryFilesEx(basePath:String, filter:String, scanSubdirs:Bool, answer:FilePathList->Void):Void {
		RFilesAsync.LoadDirectoryFilesExAsync(basePath, filter, scanSubdirs, answer);
	}

	/** Frees a listing `LoadDirectoryFilesAsync` or `LoadDirectoryFilesExAsync` gave.

		Has nothing to free, and the list is unchanged.

		@param files  The listing. */
	static function UnloadDirectoryFiles(files:FilePathList):Void {}

	/** Returns whether files were dropped on the window. See `LoadDroppedFiles` for
		reading their paths.

		Stays true until `UnloadDroppedFiles`.

		A new drop's files replace the last one's.

		A dropped file counts once its bytes are read, a frame or so after the drop.

		@return  True while dropped files are held. */
	static function IsFileDropped():Bool {
		return DroppedFiles.paths().length > 0;
	}

	/** Returns the paths of the files last dropped.

		Each path is helix-raylib's own, `helix-raylib-dropped/<n>/<name>`, which every load reads, as `LoadTextureAsync(path)` does.

		The file's name is the path's last part, with `_` for a character a path can't hold.

		A directory dropped isn't listed.

		@return  The paths, `count` of them, with `capacity` 0. */
	static function LoadDroppedFiles():FilePathList {
		var list = new FilePathList();
		list.paths = DroppedFiles.paths().copy();
		list.count = list.paths.length;
		return list;
	}

	/** Lets go of the list of files last dropped, so `IsFileDropped` is false until the next drop.

		The files stay. A load of one of their paths, started before or after, reads the file until the next drop's files replace them.

		@param files  The list `LoadDroppedFiles` gave. A list of no files changes nothing. */
	static function UnloadDroppedFiles(files:FilePathList):Void {
		if (files == null || files.count <= 0)
			return;
		Runtime.dropped = [];
	}

	/** Returns when a file was last written, as `GetFileModTimeAsync` answers it.

		@param fileName  The file.
		@return  The time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's. */
	@:waits
	static function GetFileModTime(fileName:String, answer:Int->Void):Void {
		RFilesAsync.GetFileModTimeAsync(fileName, answer);
	}

	// ---- Encoding and hashes ----

	/** Compresses bytes as raylib's `CompressData` does, byte for byte, raw DEFLATE with no zlib header at sdefl's level 8. See
		`DecompressData` for reading them back.

		@param data  The bytes.
		@param dataSize  How many of them.
		@param compDataSize  Its first element is set to the compressed size.
		@return  The compressed bytes. */
	static function CompressData(data:haxe.io.Bytes, dataSize:Int, compDataSize:Array<Int>):haxe.io.Bytes {
		var compressed = helix.formats.deflate.Deflate.compress(dataSize < data.length ? data.sub(0, dataSize) : data, 8);
		if (compDataSize != null)
			compDataSize[0] = compressed.length;
		Runtime.log(LOG_INFO, 'SYSTEM: Compress data: Original size: $dataSize -> Comp. size: ${compressed.length}');
		return compressed;
	}

	/** Returns DEFLATE data decompressed, a raw stream with no zlib header as `CompressData` makes.

		Gives at most 64 MB.

		Data that isn't DEFLATE, or stops short, gives the bytes read before it, perhaps none, and logs a warning.

		@param compData  The compressed bytes.
		@param compDataSize  How many of them.
		@param dataSize  Its first element is set to how many bytes it gives.
		@return  The bytes. */
	static function DecompressData(compData:haxe.io.Bytes, compDataSize:Int, dataSize:Array<Int>):haxe.io.Bytes {
		var limit = 64 * 1024 * 1024;
		var output = new haxe.io.BytesBuffer(),
			chunk = haxe.io.Bytes.alloc(65536);
		try {
			var inflate = new haxe.zip.InflateImpl(new haxe.io.BytesInput(compData, 0, compDataSize), false, false);
			while (output.length < limit) {
				var wanted = limit - output.length < chunk.length ? limit - output.length : chunk.length;
				var read = inflate.readBytes(chunk, 0, wanted);
				output.addBytes(chunk, 0, read);
				if (read < wanted)
					break;
			}
		} catch (e:haxe.Exception) {
			Runtime.log(LOG_WARNING, "SYSTEM: Failed to decompress data: " + e.message);
		}
		var data = output.getBytes();
		if (dataSize != null)
			dataSize[0] = data.length;
		Runtime.log(LOG_INFO, 'SYSTEM: Decompress data: Comp. size: $compDataSize -> Original size: ${data.length}');
		return data;
	}

	/** Returns some bytes as Base64 text, padded with `=` to a multiple of 4 characters. See `DecodeDataBase64` for reading them back.

		@param data  The bytes.
		@param dataSize  How many of them.
		@param outputSize  Its first element is set to the text's length.
		@return  The text. */
	static function EncodeDataBase64(data:haxe.io.Bytes, dataSize:Int, outputSize:Array<Int>):String {
		var size = 4 * Std.int((dataSize + 2) / 3);
		if (outputSize != null)
			outputSize[0] = size;
		var text = new StringBuf(), i = 0;
		while (i < dataSize) {
			var a = data.get(i++);
			var b = i < dataSize ? data.get(i++) : 0;
			var c = i < dataSize ? data.get(i++) : 0;
			var triple = (a << 16) | (b << 8) | c;
			text.addChar(StringTools.fastCodeAt(BASE64, (triple >> 18) & 0x3F));
			text.addChar(StringTools.fastCodeAt(BASE64, (triple >> 12) & 0x3F));
			text.addChar(StringTools.fastCodeAt(BASE64, (triple >> 6) & 0x3F));
			text.addChar(StringTools.fastCodeAt(BASE64, triple & 0x3F));
		}
		var padding = [0, 2, 1][dataSize % 3];
		return text.toString().substr(0, size - padding) + "==".substr(0, padding);
	}

	/** Returns the bytes of Base64 text.

		The text runs to a zero byte or the end, read 4 characters at a time.

		A character that isn't Base64's reads as 0.

		Text whose length isn't a multiple of 4 logs a warning and is read up to its last 4 characters.

		@param data  The text's bytes.
		@param outputSize  Its first element is set to how many bytes it gives: 3 for every 4 characters, less one for each `=` at the
			end.
		@return  The bytes. */
	static function DecodeDataBase64(data:haxe.io.Bytes, outputSize:Array<Int>):haxe.io.Bytes {
		inline function value(c:Int):Int
			return if (c >= "A".code && c <= "Z".code) c - "A".code; else if (c >= "a".code && c <= "z".code) c - "a".code + 26; else if (c >= "0".code
				&& c <= "9".code) c
				- "0".code + 52; else if (c == "+".code) 62; else if (c == "/".code) 63; else 0;
		var dataSize = 0;
		while (dataSize < data.length && data.get(dataSize) != 0)
			dataSize++;
		var ending = dataSize - 1, padding = 0;
		while (ending >= 0 && data.get(ending) == "=".code) {
			padding++;
			ending--;
		}
		var estimatedOutputSize = 3 * Std.int(dataSize / 4) - padding;
		var maxOutputSize = 3 * Std.int(dataSize / 4);
		var decoded = haxe.io.Bytes.alloc(maxOutputSize);
		decoded.fill(0, maxOutputSize, 0);
		var outputCount = 0, i = 0;
		while (i < dataSize) {
			// Every 4 characters give 3 bytes.
			if (i + 2 >= dataSize) {
				Runtime.log(LOG_WARNING, "BASE64: Decoding error: Input data size is not valid");
				break;
			}
			var sixtetA = value(data.get(i)), sixtetB = value(data.get(i + 1));
			var sixtetC = i + 2 < dataSize && data.get(i + 2) != "=".code ? value(data.get(i + 2)) : 0;
			var sixtetD = i + 3 < dataSize && data.get(i + 3) != "=".code ? value(data.get(i + 3)) : 0;
			var octetPack = (sixtetA << 18) | (sixtetB << 12) | (sixtetC << 6) | sixtetD;
			if (outputCount + 3 > maxOutputSize) {
				Runtime.log(LOG_WARNING, "BASE64: Decoding error: Output data size is too small");
				break;
			}
			decoded.set(outputCount, (octetPack >> 16) & 0xff);
			decoded.set(outputCount + 1, (octetPack >> 8) & 0xff);
			decoded.set(outputCount + 2, octetPack & 0xff);
			outputCount += 3;
			i += 4;
		}
		if (estimatedOutputSize != outputCount - padding)
			Runtime.log(LOG_WARNING, "BASE64: Decoded size differs from estimation");
		if (outputSize != null)
			outputSize[0] = estimatedOutputSize;
		return decoded.sub(0, estimatedOutputSize < 0 ? 0 : estimatedOutputSize);
	}

	/** Returns the CRC-32 of some bytes, as zlib and PNG compute it.

		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Its 32 bits, one above 0x7fffffff negative. */
	static function ComputeCRC32(data:haxe.io.Bytes, dataSize:Int):Int {
		if (crcTable == null) {
			crcTable = [];
			for (n in 0...256) {
				var c = n;
				for (k in 0...8)
					c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
				crcTable.push(c | 0);
			}
		}
		var crc = ~0;
		for (i in 0...dataSize)
			crc = (crc >>> 8) ^ crcTable[(data.get(i) ^ crc) & 0xff];
		return ~crc;
	}

	/** Returns the MD5 hash of some bytes.

		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Its 4 words, as raylib gives them: each read from 4 bytes of the hash, the first the lowest, and one above 0x7fffffff
			is negative. */
	static function ComputeMD5(data:haxe.io.Bytes, dataSize:Int):Array<Int> {
		var hash = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476];
		var newDataSize = (Std.int((dataSize + 8) / 64) + 1) * 64 - 8;
		var msg = haxe.io.Bytes.alloc(newDataSize + 64);
		msg.fill(0, msg.length, 0);
		msg.blit(0, data, 0, dataSize);
		msg.set(dataSize, 128);
		msg.setInt32(newDataSize, 8 * dataSize);
		var offset = 0;
		while (offset < newDataSize) {
			var a = hash[0], b = hash[1], c = hash[2], d = hash[3];
			for (i in 0...64) {
				var f, g;
				if (i < 16) {
					f = (b & c) | (~b & d);
					g = i;
				} else if (i < 32) {
					f = (d & b) | (~d & c);
					g = (5 * i + 1) % 16;
				} else if (i < 48) {
					f = b ^ c ^ d;
					g = (3 * i + 5) % 16;
				} else {
					f = c ^ (b | ~d);
					g = (7 * i) % 16;
				}
				var temp = d;
				d = c;
				c = b;
				b = (b + rotateLeft((((a + f) | 0) + ((MD5_K[i] + msg.getInt32(offset + 4 * g)) | 0)) | 0, MD5_R[i])) | 0;
				a = temp;
			}
			hash[0] = (hash[0] + a) | 0;
			hash[1] = (hash[1] + b) | 0;
			hash[2] = (hash[2] + c) | 0;
			hash[3] = (hash[3] + d) | 0;
			offset += 64;
		}
		return hash;
	}

	/** Returns the standard SHA-1 hash of some bytes.

		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Its 5 words, the first the hash's first 4 bytes, the highest first. One above 0x7fffffff is negative. */
	static function ComputeSHA1(data:haxe.io.Bytes, dataSize:Int):Array<Int> {
		var hash = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
		var newDataSize = (Std.int((dataSize + 8) / 64) + 1) * 64;
		var msg = haxe.io.Bytes.alloc(newDataSize);
		msg.fill(0, msg.length, 0);
		msg.blit(0, data, 0, dataSize);
		msg.set(dataSize, 128);
		lengthInBits(msg, newDataSize, dataSize);
		var w = [for (i in 0...80) 0];
		var offset = 0;
		while (offset < newDataSize) {
			for (i in 0...16) {
				var at = offset + i * 4;
				w[i] = (msg.get(at) << 24) | (msg.get(at + 1) << 16) | (msg.get(at + 2) << 8) | msg.get(at + 3);
			}
			for (i in 16...80)
				w[i] = rotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
			var a = hash[0], b = hash[1], c = hash[2], d = hash[3], e = hash[4];
			for (i in 0...80) {
				var f, k;
				if (i < 20) {
					f = (b & c) | (~b & d);
					k = 0x5A827999;
				} else if (i < 40) {
					f = b ^ c ^ d;
					k = 0x6ED9EBA1;
				} else if (i < 60) {
					f = (b & c) | (b & d) | (c & d);
					k = 0x8F1BBCDC;
				} else {
					f = b ^ c ^ d;
					k = 0xCA62C1D6;
				}
				var temp = (((((rotateLeft(a, 5) + f) | 0) + e) | 0) + ((k + w[i]) | 0)) | 0;
				e = d;
				d = c;
				c = rotateLeft(b, 30);
				b = a;
				a = temp;
			}
			hash[0] = (hash[0] + a) | 0;
			hash[1] = (hash[1] + b) | 0;
			hash[2] = (hash[2] + c) | 0;
			hash[3] = (hash[3] + d) | 0;
			hash[4] = (hash[4] + e) | 0;
			offset += 64;
		}
		return hash;
	}

	// A message's length in bits as SHA-1 ends its padding: 64 bits, the highest byte first, in the 8 bytes before end.
	static function lengthInBits(msg:haxe.io.Bytes, end:Int, dataSize:Int):Void {
		var low = dataSize << 3, high = dataSize >>> 29;
		for (i in 0...4) {
			msg.set(end - 1 - i, (low >>> (8 * i)) & 255);
			msg.set(end - 5 - i, (high >>> (8 * i)) & 255);
		}
	}

	// ---- Hooks ----

	/** Reads files through the program from now on.

		Every load raylib makes of a file (textures, models, sounds, music, data) asks the callback first. A null answer reads the file as
		it would be read without the callback.

		A texture's or model's images decode asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load the ones
		the callback gives.

		@param callback  Returns a file's bytes or null, or is null for none. */
	static function SetLoadFileDataCallback(callback:Null<(fileName:String) -> Null<haxe.io.Bytes>>):Void {
		CallbackFiles.load = callback;
	}

	/** Writes files through the program from now on (`SaveFileDataAsync`).

		@param callback  Writes a file's bytes, returning whether it did, or is null for none. */
	static function SetSaveFileDataCallback(callback:Null<(fileName:String, data:haxe.io.Bytes, dataSize:Int) -> Bool>):Void {
		saveData = callback;
	}

	/** Reads text files through the program from now on (`LoadFileTextAsync`).

		@param callback  Returns a file's text or null, or is null for none. */
	static function SetLoadFileTextCallback(callback:Null<(fileName:String) -> Null<String>>):Void {
		loadText = callback;
	}

	/** Writes text files through the program from now on (`SaveFileTextAsync`).

		@param callback  Writes a file's text, returning whether it did, or is null for none. */
	static function SetSaveFileTextCallback(callback:Null<(fileName:String, text:String) -> Bool>):Void {
		saveText = callback;
	}

	// ---- Automation events ----
	// raylib's LoadAutomationEventList(NULL): an empty list to record into, its capacity raylib's. Raylib.LoadAutomationEventList, a
	// macro, calls it; a file is read by LoadAutomationEventListAsync.
	// raylib's LoadAutomationEventList given a file, in answer form (Raylib.LoadAutomationEventList waits for it): a file that can't be
	// read is logged, and answers an empty list.
	static function loadAutomationEventList(fileName:String, answer:AutomationEventList->Void):Void {
		RFilesAsync.LoadAutomationEventListAsync(fileName, answer, error -> {
			Answers.refuse("LoadAutomationEventList", error, null);
			answer(newAutomationEventList());
		});
	}

	static function newAutomationEventList():AutomationEventList {
		var list = new AutomationEventList();
		list.capacity = Automation.CAPACITY;
		Runtime.log(LOG_INFO, "AUTOMATION: New empty events list loaded successfully");
		return list;
	}

	/** Frees a list's events.

		Has nothing to free, and the list is unchanged.

		@param list  The list. */
	static function UnloadAutomationEventList(list:AutomationEventList):Void {}

	/** Writes a list's events as text, as `ExportAutomationEventListAsync` writes it, and returns once it is written. See
		`LoadAutomationEventList` for reading it back.

		@param list  The list.
		@param fileName  The file.
		@return  Whether it was written. Why it wasn't is logged. */
	@:waits
	static function ExportAutomationEventList(list:AutomationEventList, fileName:String, answer:Bool->Void):Void {
		RFilesAsync.ExportAutomationEventListAsync(list, fileName, answer.bind(true), Answers.failing("ExportAutomationEventList", answer, false));
	}

	// ExportAutomationEventListAsync's text, as raylib's writes it, byte for byte.
	static function automationText(list:AutomationEventList):String {
		var text = new StringBuf();
		text.add("#\n");
		text.add("# Automation events exporter v1.0 - raylib automation events list\n");
		text.add("#\n");
		text.add("#    c <events_count>\n");
		text.add("#    e <frame> <event_type> <param0> <param1> <param2> <param3> // <event_type_name>\n");
		text.add("#\n");
		text.add("# more info and bugs-report:  github.com/raysan5/raylib\n");
		text.add("# feedback and support:       ray[at]raylib.com\n");
		text.add("#\n");
		text.add("# Copyright (c) 2023-2024 Ramon Santamaria (@raysan5)\n");
		text.add("#\n\n");
		text.add('c ${list.count}\n');
		for (i in 0...list.count) {
			var event = list.events[i];
			var p = [for (j in 0...4) j < event.params.length ? event.params[j] : 0];
			var name = event.type >= 0 && event.type < Automation.TYPE_NAMES.length ? Automation.TYPE_NAMES[event.type] : "";
			text.add('e ${event.frame} ${event.type} ${p[0]} ${p[1]} ${p[2]} ${p[3]} // Event: $name\n');
		}
		return text.toString();
	}

	/** Sets the list `StartAutomationEventRecording` records into.

		From the first call, the input functions read the input as automation keeps it, so an event `PlayAutomationEvent` plays reads as
		real input.

		@param list  The list, made by `LoadAutomationEventList(null)` or `LoadAutomationEventListAsync`. */
	static function SetAutomationEventList(list:AutomationEventList):Void {
		Automation.use().list = list;
	}

	/** Sets the frame the next event recorded is stamped with, each frame after counting up from it.

		The frames since `InitWindow` until set.

		@param frame  The frame. */
	static function SetAutomationEventBaseFrame(frame:Int):Void {
		Automation.use().frameOffset = frame - Runtime.frames;
	}

	/** Starts recording into the list `SetAutomationEventList` set. See `StopAutomationEventRecording` for stopping.

		Records as each frame ends, before the next frame's input is read. Each event recorded is logged.

		Records:

		- every key, mouse button and finger held.
		- the mouse's moves, the wheel's and the fingers'.
		- the gamepads' buttons held and axes off rest.
		- the gesture.

		A full list (16384 events) records no more. */
	static function StartAutomationEventRecording():Void {
		Automation.use().recording = true;
	}

	/** Stops recording. */
	static function StopAutomationEventRecording():Void {
		Automation.use().recording = false;
	}

	/** Plays an event, making its input the input the functions read now.

		The input stays until the devices change it or another event does.

		A window event or an action is done. raylib's `WINDOW_CLOSE` event makes `WindowShouldClose` true.

		Plays nothing while recording.

		A program plays each event in its frame, after the frame's input is read. A key held is an event every frame, so a frame's events
		are played together.

		@param event  The event. */
	static function PlayAutomationEvent(event:AutomationEvent):Void {
		Automation.use().play(event);
	}

	// ---- Memory ----

	/** Doesn't compile, since Haxe has no raw memory to allocate. See `haxe.io.Bytes.alloc` for making bytes.

		@param size  The bytes.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("MemAlloc: Haxe has no raw memory to allocate. Make bytes instead: haxe.io.Bytes.alloc(size)")
	static function MemAlloc(size:Int):Dynamic {
		throw "MemAlloc is unimplemented";
	}

	/** Doesn't compile, since Haxe has no raw memory to reallocate. See `haxe.io.Bytes.alloc` and `blit` for copying into new bytes.

		@param ptr  The memory.
		@param size  The bytes.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("MemRealloc: Haxe has no raw memory to reallocate. Make new bytes and copy into them instead: haxe.io.Bytes.alloc(size), then blit")
	static function MemRealloc(ptr:Dynamic, size:Int):Dynamic {
		throw "MemRealloc is unimplemented";
	}

	/** Doesn't compile, since Haxe frees memory once nothing holds it.

		@param ptr  The memory. */
	@:unsupported("MemFree: Haxe frees memory once nothing holds it. Drop the reference instead.")
	static function MemFree(ptr:Dynamic):Void {
		throw "MemFree is unimplemented";
	}

	// ---- Screenshots ----

	/** Doesn't compile on any target, since a screenshot is read back as the next frame ends and saved after. See `TakeScreenshotAsync`
		for saving a screenshot.

		@param fileName  The file's name, or its path. */
	@:unsupported("TakeScreenshot: A screenshot is saved later, or is refused. See TakeScreenshotAsync(fileName:String, ?done:Void->Void, ?failed:String->Void)")
	static function TakeScreenshot(fileName:String):Void {
		throw "TakeScreenshot is unimplemented";
	}

	// ---- Log ----

	/** Writes a message to the log when its level is at least `SetTraceLogLevel`'s.

		The text is written as it is, with no printf formatting. Haxe's string interpolation builds it.

		@param logLevel  The level (`LOG_*`).
		@param text  The message. */
	static function TraceLog(logLevel:Int, text:String):Void {
		Runtime.log(logLevel, text);
	}

	/** Sets the least level the log writes.

		`LOG_INFO` until set.

		@param logLevel  The level (`LOG_*`). */
	static function SetTraceLogLevel(logLevel:Int):Void {
		Runtime.logLevel = logLevel;
	}

	/** Writes the log through the program from now on, helix-raylib's own messages among it.

		@param callback  Receives each message's level and text, or is null for helix-raylib's own log. */
	static function SetTraceLogCallback(callback:Null<(logLevel:Int, text:String) -> Void>):Void {
		Runtime.logCallback = callback;
	}

	// ---- emscripten's calls, which raylib's web programs make: each refuses, saying what to write instead ----

	/** Doesn't compile, since raylib's own loop already runs once a frame. See `WindowShouldClose` for writing the loop.

		@param func  The frame's function.
		@param fps  The frames a second, or 0 for the display's.
		@param simulateInfiniteLoop  Whether the call never returns. */
	@:unsupported("emscripten_set_main_loop: Not needed: raylib's loop, while (!WindowShouldClose()) { ... }, already runs once a frame. Write that loop in main, the frame's code in its body.")
	static function emscripten_set_main_loop(func:Void->Void, fps:Int, simulateInfiniteLoop:Bool):Void {
		throw "emscripten_set_main_loop is unsupported";
	}

	/** Doesn't compile, since raylib's own loop already runs once a frame. See `WindowShouldClose` for writing the loop.

		@param func  The frame's function.
		@param arg  What the function is given.
		@param fps  The frames a second, or 0 for the display's.
		@param simulateInfiniteLoop  Whether the call never returns. */
	@:unsupported("emscripten_set_main_loop_arg: Not needed: raylib's loop, while (!WindowShouldClose()) { ... }, already runs once a frame. Write that loop in main, the frame's code in its body, reading the argument from a variable.")
	static function emscripten_set_main_loop_arg(func:Dynamic->Void, arg:Dynamic, fps:Int, simulateInfiniteLoop:Bool):Void {
		throw "emscripten_set_main_loop_arg is unsupported";
	}

	/** Doesn't compile, since a program leaves raylib's own loop instead. See `WindowShouldClose` for writing the loop. */
	@:unsupported("emscripten_cancel_main_loop: Not needed: leave raylib's loop, while (!WindowShouldClose()) { ... }, with break; the code after the loop runs then.")
	static function emscripten_cancel_main_loop():Void {
		throw "emscripten_cancel_main_loop is unsupported";
	}

	/** Doesn't compile on any target, since a program runs no script of its own. See `GetWindowSafeArea` for the part of the window
		nothing covers, and `SetScreenOrientationAsync` for holding the screen one way up.

		@param script  The JavaScript. */
	@:unsupported("emscripten_run_script: Not supported. See GetWindowSafeArea() for the safe area, SetScreenOrientationAsync(orientation:Int, ?done:Void->Void, ?failed:String->Void) for the screen's orientation and EnableTiltAsync(?done:Void->Void, ?failed:String->Void) for the tilt in helix.raylib.extras.Device (import helix.raylib.extras.Device.*;)")
	static function emscripten_run_script(script:String):Void {
		throw "emscripten_run_script is unsupported";
	}

	/** Doesn't compile on any target, since a program runs no script of its own. See `IsTouchAvailable` for whether the device has
		touch, and `GetScreenOrientation` for how the screen is held.

		@param script  The JavaScript.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("emscripten_run_script_int: Not supported. See IsTouchAvailable() and IsFinePointerAvailable() for the device's touch and pointer, and GetScreenOrientation() for how the screen is held in helix.raylib.extras.Device (import helix.raylib.extras.Device.*;)")
	static function emscripten_run_script_int(script:String):Int {
		throw "emscripten_run_script_int is unsupported";
	}

	/** Doesn't compile on any target, since a program runs no script of its own. See `GetPlatformOS` for naming the system.

		@param script  The JavaScript.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("emscripten_run_script_string: Not supported. See GetPlatformOS() for the system's name in helix.raylib.extras.Device (import helix.raylib.extras.Device.*;)")
	static function emscripten_run_script_string(script:String):String {
		throw "emscripten_run_script_string is unsupported";
	}

	/** Doesn't compile. See `GetTime` for reading the seconds since `InitWindow`.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("emscripten_get_now: Not supported. See GetTime(), the seconds since InitWindow (emscripten's milliseconds are GetTime() * 1000).")
	static function emscripten_get_now():Float {
		throw "emscripten_get_now is unsupported";
	}

	/** Doesn't compile, since a frame can't wait. See `GetTime` for timing a later frame.

		@param ms  The milliseconds. */
	@:unsupported("emscripten_sleep: Not supported: a frame can't wait. End the frame and carry on in a later one, timed with GetTime() or GetFrameTime().")
	static function emscripten_sleep(ms:Int):Void {
		throw "emscripten_sleep is unsupported";
	}

	// ---- What the functions share ----
	static inline final SAVED_DATA = "data:";
	// When a file SaveFileText or SaveFileData wrote was saved, in seconds since the Unix epoch.
	static inline final SAVED_TIME = "time:";
	static var loadText:Null<String->Null<String>> = null;
	static var saveText:Null<(String, String) -> Bool> = null;
	static var saveData:Null<(String, haxe.io.Bytes, Int) -> Bool> = null;

	// A file's bytes as they are at hand, without logging: the program's load callback's, then the saves' (once read), then the
	// program's own an async load brought in.

	static function dataNow(path:String):Null<haxe.io.Bytes> {
		if (CallbackFiles.load != null) {
			var given = CallbackFiles.load(path);
			if (given != null)
				return given;
		}
		if (Runtime.saves != null && Runtime.saves.hasKey(SAVED_DATA + path))
			return haxe.crypto.Base64.decode(Runtime.saves.getString(SAVED_DATA + path, ""));
		return Runtime.file(path);
	}

	static inline final SAVED = "file:";
	static inline final BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	static var crcTable:Null<Array<Int>> = null;
	// MD5's shift for each step, and its constants, the binary integer parts of the sines of 1 to 64.
	static final MD5_R = [
		7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4,
		11, 16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
	];
	static final MD5_K = [
		0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
		0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
		0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
		0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
		0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
		0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
	];

	// A 32-bit word turned left by some bits.
	static inline function rotateLeft(x:Int, bits:Int):Int {
		return (x << bits) | (x >>> (32 - bits));
	}

	// The index of a path's last `/` or `\`, or -1.
	static function lastSlash(path:String):Int {
		var slash = path.lastIndexOf("/"), back = path.lastIndexOf("\\");
		return slash > back ? slash : back;
	}

	// Text with A to Z made lower case, as raylib's TextToLower does, and nothing else.
	static function asciiLower(text:String):String {
		var lower = new StringBuf();
		for (i in 0...text.length) {
			var c = StringTools.fastCodeAt(text, i);
			lower.addChar(c >= "A".code && c <= "Z".code ? c + 32 : c);
		}
		return lower.toString();
	}

	static var start = 0.;
	static var configFlags = 0;
	static var seeded = false;
	static var lastMouseX = 0.;
	static var lastMouseY = 0.;
	static var lastPointerX = 0.;
	static var lastPointerY = 0.;
	static var mouseOffsetX = 0.;
	static var mouseOffsetY = 0.;
	static var mouseScaleX = 1.;
	static var mouseScaleY = 1.;
	static var cursorHidden = false;
	// Whether a refusal has been warned of this run: the cursor not moving in a page, the system refusing to move it, a gamepad not shaking.
	static var warnedMousePage = false;
	static var warnedMouseRefused = false;
	static var warnedVibration = false;

	// A file's name as the loads and saves read it: relative to the program's files, a leading `GetApplicationDirectory()` and "./"
	// taken off.
	static function normalize(path:String):String {
		#if !js
		if (Runtime.system != null) {
			var application = GetApplicationDirectory();
			if (StringTools.startsWith(path, application))
				path = path.substr(application.length);
		}
		#end
		while (StringTools.startsWith(path, "./"))
			path = path.substr(2);
		return path;
	}

	// Whether a key is held, as the keyboard has it: false for a key that isn't the platform's own number (a right-hand modifier).
	static function realKeyDown(key:Int):Bool {
		return toKey(key) == key && Runtime.keyboard().isKeyDown(cast key);
	}

	// Whether a key went down this frame, as the keyboard has it.
	static function realKeyPressed(key:Int):Bool {
		return toKey(key) == key && Runtime.keyboard().isKeyPressed(cast key);
	}

	// Whether a key went up this frame, as the keyboard has it.
	static function realKeyReleased(key:Int):Bool {
		return toKey(key) == key && Runtime.keyboard().isKeyReleased(cast key);
	}

	// raylib's KEY_* as the platform's keys: the same numbers, a right-hand modifier as the left-hand one.

	static function toKey(key:Int):Int {
		return switch key {
			case 344 | 345 | 346 | 347: key - 4;
			case k if (k > 0 && k < 349): k;
			case _: -1;
		}
	}

	// raylib's GAMEPAD_BUTTON_* as the platform's buttons, by position.

	static function toGamepadButton(button:Int):Int {
		return switch button {
			case 1: 12;
			case 2: 15;
			case 3: 13;
			case 4: 14;
			case 5: 3;
			case 6: 1;
			case 7: 0;
			case 8: 2;
			case 9: 4;
			case 10: 6;
			case 11: 5;
			case 12: 7;
			case 13: 8;
			case 14: 16;
			case 15: 9;
			case 16: 10;
			case 17: 11;
			case _: -1;
		}
	}

	static function glyph(code:Int):Int {
		return code >= 32 && code < 256 ? code - 32 : "?".code - 32;
	}

	// An immediate vertex in 2D, at z 0.

	static inline function flat(texture:Int, x:Float, y:Float, u:Float, v:Float, color:Color):Void {
		Runtime.frame.vertex(texture, helix.raylib.internal.Frame.TRIANGLES, x, y, 0, u, v, color);
	}

	// ---- 2D camera ----

	/** Draws through a 2D camera until `EndMode2D`.

		@param camera  The camera. */
	static function BeginMode2D(camera:Camera2D):Void {
		Runtime.frame.cut();
		Runtime.frame.view = camera2D(camera).computeViewMatrix(viewMatrix2D).toMatrix3D();
	}

	/** Goes back to drawing in the screen's pixels. */
	static function EndMode2D():Void {
		Runtime.frame.screen2D();
	}

	/** Returns a 2D camera's transform, from the world to the screen.

		@param camera  The camera.
		@return  The matrix. */
	static function GetCameraMatrix2D(camera:Camera2D):Matrix {
		return toMatrix(camera2D(camera).computeViewMatrix(viewMatrix2D).toMatrix3D());
	}

	/** Returns where a point in a 2D camera's world is on the screen.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = camera2D(camera).worldToView(position.x, position.y, point2D);
		return new Vector2(p.x, p.y);
	}

	/** Returns where a screen position is in a 2D camera's world.

		@param position  The screen position.
		@param camera  The camera.
		@return  The point, or NaN at zoom 0. */
	static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = camera2D(camera).viewToWorld(position.x, position.y, point2D);
		return p == null ? new Vector2(Math.NaN, Math.NaN) : new Vector2(p.x, p.y);
	}

	// raylib's Camera2D as helix-math's, reused: its target the position, its rotation in radians and negated (raylib's turns the world,
	// helix-math's the camera), its zoom and its offset.
	static final view2D = new helix.geometry.Camera2D();

	static final viewMatrix2D = new helix.math.Matrix2D();

	static final point2D = new helix.math.Vector2D();

	static function camera2D(camera:Camera2D):helix.geometry.Camera2D {
		view2D.transform.position.set(camera.target.x, camera.target.y);
		view2D.transform.rotation = -(camera.rotation * DEG2RAD);
		view2D.zoom = camera.zoom;
		view2D.offset.set(camera.offset.x, camera.offset.y);
		return view2D;
	}

	// ---- 3D camera ----

	/** Draws in 3D through a camera until `EndMode3D`, testing depth (rlgl's `rlEnableDepthTest`).

		@param camera  The camera. */
	static function BeginMode3D(camera:Camera3D):Void {
		var f = Runtime.frame;
		f.cut();
		f.depthTest = true;
		var view = camera3D(camera);
		f.view = view.computeViewMatrix();
		f.projection = view.computeProjectionMatrix(f.width / f.height);
	}

	/** Goes back to drawing in 2D, in the screen's pixels, without testing depth. */
	static function EndMode3D():Void {
		Runtime.frame.screen2D();
		Runtime.frame.depthTest = false;
	}

	/** Moves a camera by the keyboard, the mouse and the first gamepad, as one of rcamera's modes does. See `UpdateCameraPro` for moving
		it by amounts.

		`CAMERA_ORBITAL` turns the camera about its target, half a radian a second.

		`CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON`:

		- turn by the mouse, the right stick and the arrow keys, the look stopping short of straight up and down.
		- roll by Q and E.
		- move by WASD and the left stick, 5.4 units a second.

		`CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` move along the ground, and `CAMERA_THIRD_PERSON` turns about its target.

		`CAMERA_FREE` also moves up and down by space and left control, and pans while the middle button is held.

		`CAMERA_FREE`, `CAMERA_ORBITAL` and `CAMERA_THIRD_PERSON` move toward the target by the wheel and the keypad's plus and minus.

		`CAMERA_CUSTOM` leaves the camera unchanged.

		@param camera  The camera, changed.
		@param mode  The mode (`CAMERA_*`). */
	static function UpdateCamera(camera:Camera3D, mode:Int):Void {
		var mouse = GetMouseDelta();
		var moveInWorldPlane = mode == CAMERA_FIRST_PERSON || mode == CAMERA_THIRD_PERSON;
		var rotateAroundTarget = mode == CAMERA_THIRD_PERSON || mode == CAMERA_ORBITAL;
		var lockView = mode == CAMERA_FREE || mode == CAMERA_FIRST_PERSON || mode == CAMERA_THIRD_PERSON || mode == CAMERA_ORBITAL;
		var rotateUp = false;
		var dt = GetFrameTime();
		var moveSpeed = 5.4 * dt,
			rotationSpeed = .03 * dt,
			panSpeed = .2 * dt,
			orbitalSpeed = .5 * dt;
		if (mode == CAMERA_CUSTOM) {} else if (mode == CAMERA_ORBITAL) {
			var p = camera.position, t = camera.target;
			var up = cameraUp(camera);
			var view = Quaternion3D.fromAxisAngle(up.x, up.y, up.z, orbitalSpeed, turn3D).transformPoint(p.x - t.x, p.y - t.y, p.z - t.z, view3DVector);
			camera.position = new Vector3(t.x + view.x, t.y + view.y, t.z + view.z);
		} else {
			if (IsKeyDown(KEY_DOWN))
				cameraPitch(camera, -rotationSpeed, lockView, rotateAroundTarget, rotateUp);
			if (IsKeyDown(KEY_UP))
				cameraPitch(camera, rotationSpeed, lockView, rotateAroundTarget, rotateUp);
			if (IsKeyDown(KEY_RIGHT))
				cameraYaw(camera, -rotationSpeed, rotateAroundTarget);
			if (IsKeyDown(KEY_LEFT))
				cameraYaw(camera, rotationSpeed, rotateAroundTarget);
			if (IsKeyDown(KEY_Q))
				cameraRoll(camera, -rotationSpeed);
			if (IsKeyDown(KEY_E))
				cameraRoll(camera, rotationSpeed);
			if (mode == CAMERA_FREE && IsMouseButtonDown(MOUSE_BUTTON_MIDDLE)) {
				var pan = GetMouseDelta();
				if (pan.x > 0)
					cameraMoveRight(camera, panSpeed, moveInWorldPlane);
				if (pan.x < 0)
					cameraMoveRight(camera, -panSpeed, moveInWorldPlane);
				if (pan.y > 0)
					cameraMoveUp(camera, -panSpeed);
				if (pan.y < 0)
					cameraMoveUp(camera, panSpeed);
			} else {
				cameraYaw(camera, -mouse.x * .003, rotateAroundTarget);
				cameraPitch(camera, -mouse.y * .003, lockView, rotateAroundTarget, rotateUp);
			}
			if (IsKeyDown(KEY_W))
				cameraMoveForward(camera, moveSpeed, moveInWorldPlane);
			if (IsKeyDown(KEY_A))
				cameraMoveRight(camera, -moveSpeed, moveInWorldPlane);
			if (IsKeyDown(KEY_S))
				cameraMoveForward(camera, -moveSpeed, moveInWorldPlane);
			if (IsKeyDown(KEY_D))
				cameraMoveRight(camera, moveSpeed, moveInWorldPlane);
			if (IsGamepadAvailable(0)) {
				cameraYaw(camera, -(GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X) * 2) * .003, rotateAroundTarget);
				cameraPitch(camera, -(GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_Y) * 2) * .003, lockView, rotateAroundTarget, rotateUp);
				if (GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y) <= -.25)
					cameraMoveForward(camera, moveSpeed, moveInWorldPlane);
				if (GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) <= -.25)
					cameraMoveRight(camera, -moveSpeed, moveInWorldPlane);
				if (GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y) >= .25)
					cameraMoveForward(camera, -moveSpeed, moveInWorldPlane);
				if (GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) >= .25)
					cameraMoveRight(camera, moveSpeed, moveInWorldPlane);
			}
			if (mode == CAMERA_FREE) {
				if (IsKeyDown(KEY_SPACE))
					cameraMoveUp(camera, moveSpeed);
				if (IsKeyDown(KEY_LEFT_CONTROL))
					cameraMoveUp(camera, -moveSpeed);
			}
		}
		if (mode == CAMERA_THIRD_PERSON || mode == CAMERA_ORBITAL || mode == CAMERA_FREE) {
			cameraMoveToTarget(camera, -GetMouseWheelMove());
			if (IsKeyPressed(KEY_KP_SUBTRACT))
				cameraMoveToTarget(camera, 2);
			if (IsKeyPressed(KEY_KP_ADD))
				cameraMoveToTarget(camera, -2);
		}
	}

	/** Moves and turns a camera by amounts, as rcamera does. See `UpdateCamera` for moving it by input.

		Pitches first, no further up or down than straight, then yaws and rolls about the camera's own position.

		Then moves forward and right along the ground and up along the camera's up, then toward its target, the distance kept above 0.

		@param camera  The camera, changed.
		@param movement  The distances it moves: forward (x), right (y) and up (z), in world units.
		@param rotation  The angles it turns: yaw to the right (x), pitch down (y) and roll (z), in degrees.
		@param zoom  How much further from its target it moves, in world units. A negative zoom moves it closer. */
	static function UpdateCameraPro(camera:Camera, movement:Vector3, rotation:Vector3, zoom:Float):Void {
		cameraPitch(camera, -rotation.y * DEG2RAD, true, false, false);
		cameraYaw(camera, -rotation.x * DEG2RAD, false);
		cameraRoll(camera, rotation.z * DEG2RAD);
		cameraMoveForward(camera, movement.x, true);
		cameraMoveRight(camera, movement.y, true);
		cameraMoveUp(camera, movement.z);
		cameraMoveToTarget(camera, zoom);
	}

	// ---- rcamera's moves, as raylib's, on helix-math's vectors and rotations ----
	// They act on raylib's position, target and up as rcamera does, not on a Transform3D: raylib's up needn't be square to the view, and
	// the yaw, the move up and the pitch's lock use it as it is, where a Transform3D's own up is always square to the way it faces.
	// The view, from the position to the target, into a vector of its own.
	static function cameraView(camera:Camera):Vector3D {
		var p = camera.position, t = camera.target;
		return viewVector.set(t.x - p.x, t.y - p.y, t.z - p.z);
	}

	static function cameraForward(camera:Camera):Vector3D {
		return cameraView(camera).normalize(forwardVector);
	}

	static function cameraUp(camera:Camera):Vector3D {
		var u = camera.up;
		return upVector.set(u.x, u.y, u.z).normalize(upVector);
	}

	static function cameraRight(camera:Camera):Vector3D {
		return cameraForward(camera).cross(cameraUp(camera), rightVector).normalize(rightVector);
	}

	// The camera's position or target, as the other plus or minus the view.
	static function placeAlong(camera:Camera, view:Vector3D, rotateAroundTarget:Bool):Void {
		var p = camera.position, t = camera.target;
		if (rotateAroundTarget)
			camera.position = new Vector3(t.x - view.x, t.y - view.y, t.z - view.z);
		else
			camera.target = new Vector3(p.x + view.x, p.y + view.y, p.z + view.z);
	}

	// Moves the position and the target alike.
	static function cameraMove(camera:Camera, by:Vector3D):Void {
		var p = camera.position, t = camera.target;
		camera.position = new Vector3(p.x + by.x, p.y + by.y, p.z + by.z);
		camera.target = new Vector3(t.x + by.x, t.y + by.y, t.z + by.z);
	}

	// A direction in the world's plane, as raylib 6.2's: the part along the axis the camera's up is mostly along dropped (z when its
	// up's z is over 0.7071, else x when its x is, else y), then of length 1.
	static function inWorldPlane(camera:Camera, v:Vector3D):Vector3D {
		var up = camera.up;
		if (Math.abs(up.z) > 0.7071)
			v.z = 0;
		else if (Math.abs(up.x) > 0.7071)
			v.x = 0;
		else
			v.y = 0;
		return v.normalize(v);
	}

	// Moves the position and the target forward, along the ground in the world's plane.
	static function cameraMoveForward(camera:Camera, distance:Float, moveInWorldPlane:Bool):Void {
		var forward = cameraForward(camera);
		if (moveInWorldPlane)
			inWorldPlane(camera, forward);
		cameraMove(camera, forward.scale(distance, forward));
	}

	static function cameraMoveUp(camera:Camera, distance:Float):Void {
		var up = cameraUp(camera);
		cameraMove(camera, up.scale(distance, up));
	}

	static function cameraMoveRight(camera:Camera, distance:Float, moveInWorldPlane:Bool):Void {
		var right = cameraRight(camera);
		if (moveInWorldPlane)
			inWorldPlane(camera, right);
		cameraMove(camera, right.scale(distance, right));
	}

	// Moves the position along the line to the target, at least 0.001 from it.
	static function cameraMoveToTarget(camera:Camera, delta:Float):Void {
		var p = camera.position, t = camera.target;
		var distance = Math.sqrt((t.x - p.x) * (t.x - p.x) + (t.y - p.y) * (t.y - p.y) + (t.z - p.z) * (t.z - p.z)) + delta;
		if (distance <= 0)
			distance = .001;
		var forward = cameraForward(camera);
		camera.position = new Vector3(t.x - forward.x * distance, t.y - forward.y * distance, t.z - forward.z * distance);
	}

	// A vector turned around an axis, which needn't be of length 1 (one of length 0 turns nothing), in place.
	static function turnAround(vector:Vector3D, axis:Vector3D, angle:Float):Vector3D {
		return Quaternion3D.fromAxisAngle(axis.x, axis.y, axis.z, angle, turn3D).transformPoint(vector.x, vector.y, vector.z, vector);
	}

	static function cameraYaw(camera:Camera, angle:Float, rotateAroundTarget:Bool):Void {
		placeAlong(camera, turnAround(cameraView(camera), cameraUp(camera), angle), rotateAroundTarget);
	}

	// Pitches the camera; locked, no further than 0.001 radians short of straight up or down, its up's way.
	static function cameraPitch(camera:Camera, angle:Float, lockView:Bool, rotateAroundTarget:Bool, rotateUp:Bool):Void {
		if (lockView) {
			var up = cameraUp(camera), view = cameraView(camera);
			var maxAngleUp = angleBetween(up, view) - .001;
			if (angle > maxAngleUp)
				angle = maxAngleUp;
			var maxAngleDown = -angleBetween(up.negate(up), view) + .001;
			if (angle < maxAngleDown)
				angle = maxAngleDown;
		}
		var right = cameraRight(camera);
		placeAlong(camera, turnAround(cameraView(camera), right, angle), rotateAroundTarget);
		if (rotateUp) {
			var u = camera.up;
			var up = turnAround(upVector.set(u.x, u.y, u.z), right, angle);
			camera.up = new Vector3(up.x, up.y, up.z);
		}
	}

	static function cameraRoll(camera:Camera, angle:Float):Void {
		var u = camera.up;
		var up = turnAround(upVector.set(u.x, u.y, u.z), cameraForward(camera), angle);
		camera.up = new Vector3(up.x, up.y, up.z);
	}

	// The angle between two vectors, raymath's Vector3Angle: 0 when either is of length 0.
	static function angleBetween(a:Vector3D, b:Vector3D):Float {
		return Trig.atan2(a.cross(b, crossVector).length, a.dot(b));
	}

	static final viewVector = new Vector3D();

	static final forwardVector = new Vector3D();

	static final upVector = new Vector3D();

	static final rightVector = new Vector3D();

	static final crossVector = new Vector3D();

	static final turn3D = new Quaternion3D();

	/** Returns a camera's view, as `BeginMode3D` uses it.

		@param camera  The camera.
		@return  The matrix. */
	static function GetCameraMatrix(camera:Camera3D):Matrix {
		return toMatrix(camera3D(camera).computeViewMatrix(viewMatrix3D));
	}

	/** Returns the ray from a camera through a screen position, for picking. See `GetScreenToWorldRayEx` for casting through a view of
		another size.

		@param position  The screen position.
		@param camera  The camera.
		@return  The ray. */
	static function GetScreenToWorldRay(position:Vector2, camera:Camera3D):Ray {
		return GetScreenToWorldRayEx(position, camera, GetScreenWidth(), GetScreenHeight());
	}

	/** Returns the ray from a camera through a position in a view of a size, such as a render texture's.

		@param position  The position in the view.
		@param camera  The camera.
		@param width  The view's width.
		@param height  The view's height.
		@return  The ray. */
	static function GetScreenToWorldRayEx(position:Vector2, camera:Camera3D, width:Int, height:Int):Ray {
		var x = 2 * position.x / width - 1,
			y = 1 - 2 * position.y / height,
			aspect = width / height;
		var picked = camera3D(camera).computeRay(x, y, aspect, ray3D);
		var origin = picked.origin, direction = picked.direction;
		return new Ray(new Vector3(origin.x, origin.y, origin.z), new Vector3(direction.x, direction.y, direction.z));
	}

	/** Returns the ray from a camera through a screen position, under raylib's old name for `GetScreenToWorldRay`.

		@param position  The screen position.
		@param camera  The camera.
		@return  The ray. */
	static function GetMouseRay(position:Vector2, camera:Camera3D):Ray {
		return GetScreenToWorldRay(position, camera);
	}

	/** Returns where a point in the world is on the screen. See `GetWorldToScreenEx` for placing it in a view of another size.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	static function GetWorldToScreen(position:Vector3, camera:Camera3D):Vector2 {
		return GetWorldToScreenEx(position, camera, GetScreenWidth(), GetScreenHeight());
	}

	/** Returns where a point in the world is in a view of a size.

		@param position  The point.
		@param camera  The camera.
		@param width  The view's width.
		@param height  The view's height.
		@return  The position in the view, or infinite or NaN for a point level with a perspective camera's position. */
	static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2 {
		var p = camera3D(camera).project(position.x, position.y, position.z, width / height, point3D);
		return new Vector2((p.x + 1) / 2 * width, (1 - p.y) / 2 * height);
	}

	// raylib's Camera3D as helix-math's, reused: its position, turned to face its target with its up kept as near as it can be (an up
	// along the view, or a target at its position, as Quaternion3D.fromLookRotation replaces them), its fovy in radians or, orthographic,
	// the height it shows, and raylib's near and far planes, 0.01 and 1000.
	static final view3D = new helix.geometry.Camera3D();

	static final viewMatrix3D = new Matrix3D();

	static final point3D = new Vector3D();

	static final ray3D = new helix.geometry.Ray3D();

	static final view3DVector = new Vector3D();

	static function camera3D(camera:Camera3D):helix.geometry.Camera3D {
		var p = camera.position, t = camera.target, u = camera.up;
		view3D.transform.position.set(p.x, p.y, p.z);
		Quaternion3D.fromLookRotation(t.x - p.x, t.y - p.y, t.z - p.z, u.x, u.y, u.z, view3D.transform.rotation);
		view3D.orthographic = camera.projection == CAMERA_ORTHOGRAPHIC;
		view3D.fieldOfView = camera.fovy * DEG2RAD;
		view3D.orthographicHeight = camera.fovy;
		view3D.near = helix.raylib.modules.RRlgl.cullNear;
		view3D.far = helix.raylib.modules.RRlgl.cullFar;
		return view3D;
	}

	/** Returns how far the mouse moved since the last frame, in the screen's pixels times the mouse's scale (`SetMouseScale`).

		A `SetMousePosition` this frame is part of the movement.

		@return  The movement. */
	static function GetMouseDelta():Vector2 {
		var played = Runtime.played;
		if (played != null)
			return new Vector2((played.mouseX - played.previousMouseX) * mouseScaleX, (played.mouseY - played.previousMouseY) * mouseScaleY);
		// From where the mouse was last seen in an earlier frame, before SetMouseOffset.
		pointer();
		var frame = Runtime.frames;
		if (frame != deltaFrame) {
			deltaFrame = frame;
			previousX = seenX;
			previousY = seenY;
		}
		seenX = lastPointerX;
		seenY = lastPointerY;
		return new Vector2((lastPointerX - previousX) * mouseScaleX, (lastPointerY - previousY) * mouseScaleY);
	}

	// ---- VR stereo rendering ----

	/** Starts drawing for both eyes of a head-mounted display, with the config's projections and view offsets (`rlEnableStereoRender`).

		Until `EndVrStereoMode`, each flush of the batch and each mesh draws twice, into the left half of what is drawn into for the first
		eye and the right half for the second.

		Each eye's projection replaces `BeginMode3D`'s.

		raylib's VR simulator draws the eyes into a render texture, then draws that to the screen through a distortion shader.

		@param config  The config, from `LoadVrStereoConfig`. */
	static function BeginVrStereoMode(config:VrStereoConfig):Void {
		helix.raylib.modules.RRlgl.rlEnableStereoRender();
		helix.raylib.modules.RRlgl.rlSetMatrixProjectionStereo(config.projection[0], config.projection[1]);
		helix.raylib.modules.RRlgl.rlSetMatrixViewOffsetStereo(config.viewOffset[0], config.viewOffset[1]);
	}

	/** Stops drawing for both eyes (`rlDisableStereoRender`), from the next flush of the batch and the next mesh drawn.

		Shapes drawn in stereo and not flushed yet draw once. `EndMode3D` flushes them. */
	static function EndVrStereoMode():Void {
		helix.raylib.modules.RRlgl.rlDisableStereoRender();
	}

	/** Returns the stereo config of a head-mounted display, as raylib 5.5 computes it.

		The config holds:

		- each eye's projection, from the field of view the lenses' distortion widens, shifted by the lenses' offset from the eyes'
		  halves of the screen, between the clip planes (`rlSetClipPlanes`).
		- each eye's view offset, half the interpupillary distance to its side, 0.075 up and 0.045 forward.
		- the lens and screen centers and scales a distortion shader reads (raylib's `distortion330.fs`).

		@param device  The display's parameters.
		@return  The config. */
	static function LoadVrStereoConfig(device:VrDeviceInfo):VrStereoConfig {
		var config = new VrStereoConfig();
		var aspect = (device.hResolution * 0.5) / device.vResolution;
		var lensShift = (device.hScreenSize * 0.25 - device.lensSeparationDistance * 0.5) / device.hScreenSize;
		config.leftLensCenter = [0.25 + lensShift, 0.5];
		config.rightLensCenter = [0.75 - lensShift, 0.5];
		config.leftScreenCenter = [0.25, 0.5];
		config.rightScreenCenter = [0.75, 0.5];
		// The lens's radius, lensShift taken to -1 to 1.
		var lensRadius = Math.abs(-1 - 4 * lensShift);
		var lensRadiusSq = lensRadius * lensRadius;
		var k = device.lensDistortionValues;
		var distortionScale = k[0] + k[1] * lensRadiusSq + k[2] * lensRadiusSq * lensRadiusSq + k[3] * lensRadiusSq * lensRadiusSq * lensRadiusSq;
		var normScreenWidth = 0.5, normScreenHeight = 1.0;
		config.scaleIn = [2 / normScreenWidth, 2 / normScreenHeight / aspect];
		config.scale = [
			normScreenWidth * 0.5 / distortionScale,
			normScreenHeight * 0.5 * aspect / distortionScale
		];
		var fovy = 2 * Math.atan2(device.vScreenSize * 0.5 * distortionScale, device.eyeToScreenDistance);
		var projOffset = 4 * lensShift;
		var proj = MatrixPerspective(fovy, aspect, helix.raylib.modules.RRlgl.rlGetCullDistanceNear(), helix.raylib.modules.RRlgl.rlGetCullDistanceFar());
		config.projection = [
			MatrixMultiply(proj, MatrixTranslate(projOffset, 0, 0)),
			MatrixMultiply(proj, MatrixTranslate(-projOffset, 0, 0))
		];
		config.viewOffset = [
			MatrixTranslate(device.interpupillaryDistance * 0.5, 0.075, 0.045),
			MatrixTranslate(-device.interpupillaryDistance * 0.5, 0.075, 0.045)
		];
		return config;
	}

	/** Frees a stereo config.

		Has nothing to free, and logs that, as raylib 5.5 does.

		@param config  The config. */
	static function UnloadVrStereoConfig(config:VrStereoConfig):Void {
		Runtime.log(LOG_INFO, "UnloadVrStereoConfig not implemented in rcore.c");
	}

	// ---- Shaders ----

	/** Names raylib's shader load from GLSL files, and doesn't compile on any target. See `LoadCompiledShaderAsync` for loading a shader
		compiled ahead of time by `CompileShaderFile`.

		@param vsFileName  The vertex stage's file.
		@param fsFileName  The fragment stage's file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadShader: Not supported. Use LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader->Void, ?failed:String->Void) instead. It loads a shader precompiled by the CompileShaderFile(vsFileName:Null<String>, fsFileName:Null<String>, compiledShaderFileName:String) macro, typically called from the build's hxml.")
	static function LoadShader(vsFileName:String, fsFileName:String):Shader {
		throw "LoadShader is unimplemented";
	}

	/** Names raylib's shader load from GLSL text, and doesn't compile on any target. See `LoadCompiledShaderFromData` for making a shader
		from compiled data in memory.

		@param vsCode  The vertex stage's text.
		@param fsCode  The fragment stage's text.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadShaderFromMemory: Not supported. Use LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader->Void, ?failed:String->Void), or LoadCompiledShaderFromData(compiledShaderData:haxe.io.Bytes) for its bytes, instead. Each loads a shader precompiled from files by the CompileShaderFile(vsFileName:Null<String>, fsFileName:Null<String>, compiledShaderFileName:String) macro, typically called from the build's hxml.")
	static function LoadShaderFromMemory(vsCode:String, fsCode:String):Shader {
		throw "LoadShaderFromMemory is unimplemented";
	}

	/** Returns whether a shader was made.

		@param shader  The shader.
		@return  True when it was. */
	static function IsShaderValid(shader:Shader):Bool {
		return shader.id != 0;
	}

	/** Lets go of the program's hold on a shader, setting its id to 0.

		The shader is freed when no material holds it too, else when the last material holding it lets go.

		Given a material's shader (`material.shader`), lets go of one hold and leaves the material drawing with it while anything holds it.

		The default shader stays.

		@param shader  The shader. */
	static function UnloadShader(shader:Shader):Void {
		helix.raylib.internal.Models.unloadShader(shader);
	}

	/** Returns the location of a shader's uniform or texture, by its name. See `GetShaderLocationAttrib` for finding an attribute.

		@param shader  The shader.
		@param uniformName  The name.
		@return  Its location, or -1 when the shader doesn't declare it. */
	static function GetShaderLocation(shader:Shader, uniformName:String):Int {
		return shader.program == null ? -1 : shader.program.locate(uniformName);
	}

	/** Returns the location of a shader's attribute, by its name.

		@param shader  The shader.
		@param attribName  The name.
		@return  Its location, or -1 when the shader doesn't declare it. */
	static function GetShaderLocationAttrib(shader:Shader, attribName:String):Int {
		return shader.program == null ? -1 : shader.program.attributes.indexOf(attribName);
	}

	/** Sets a shader's uniform, for the models drawn after the call and the shapes in rlgl's batch when the batch is next drawn. See
		`SetShaderValueV` for setting an array's elements.

		Shapes drawn before the call but not yet flushed take the value too. `BeginShaderMode`, `EndShaderMode`, a mode changing and
		`rlDrawRenderBatchActive` flush them.

		A texture's location takes the texture unit its sampler reads. `DrawMesh` binds the material's map of that index there, as raylib's
		skybox sets its `samplerCube` to `MATERIAL_MAP_CUBEMAP`.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The value: a number, an array of numbers, or a `Vector2`, `Vector3`, `Vector4` or `Color`.
		@param uniformType  Its type (`SHADER_UNIFORM_*`). */
	static function SetShaderValue(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int):Void {
		SetShaderValueV(shader, locIndex, value, uniformType, 1);
	}

	/** Sets elements of a shader's array uniform, for the draws after the call.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The values, in order.
		@param uniformType  Each element's type (`SHADER_UNIFORM_*`).
		@param count  The elements set. */
	static function SetShaderValueV(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0) {
			// A sampler's texture unit, as GL takes an int for it: DrawMesh binds the material's map of that index there.
			var unit = numbers(value);
			if (unit.length > 0) {
				Runtime.frame.cut();
				shader.program.setUnit(slot, Std.int(unit[0]));
			}
			return;
		}
		Runtime.frame.cut();
		shader.program.write(locIndex, numbers(value, uniformType));
	}

	/** Sets a shader's matrix uniform, for the draws after the call.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param mat  The matrix. */
	static function SetShaderValueMatrix(shader:Shader, locIndex:Int, mat:Matrix):Void {
		if (shader.program == null)
			return;
		Runtime.frame.cut();
		shader.program.write(locIndex, toMatrix3D(mat).values);
	}

	/** Sets a shader's texture for the draws after the call, a `Texture2D` at a `sampler2D` or a cubemap (`LoadTextureCubemap`) at a
		`samplerCube`.

		A texture at a sampler of the other kind binds nothing.

		@param shader  The shader.
		@param locIndex  The texture's location.
		@param texture  The texture. */
	static function SetShaderValueTexture(shader:Shader, locIndex:Int, texture:Texture2D):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0) {
			Runtime.frame.cut();
			helix.raylib.internal.Program.resolve = Textures.handle;
			shader.program.setTexture(slot, texture.id);
		}
	}

	/** Draws shapes, text and textures with a shader until `EndShaderMode`.

		@param shader  The shader. */
	static function BeginShaderMode(shader:Shader):Void {
		if (shader.program == null)
			return;
		Runtime.frame.cut();
		Runtime.frame.program = shader.program;
	}

	/** Goes back to the default shader. */
	static function EndShaderMode():Void {
		Runtime.frame.cut();
		Runtime.frame.program = Runtime.frame.defaultProgram;
	}

	/** Blends what is drawn until `EndBlendMode` another way, as rlgl sets GL's blending.

		The modes:

		- `BLEND_ALPHA`, alpha blended by the same factors as the color.
		- `BLEND_ADDITIVE`, `BLEND_MULTIPLIED`, `BLEND_ADD_COLORS`, `BLEND_SUBTRACT_COLORS` and `BLEND_ALPHA_PREMULTIPLY`.
		- `BLEND_CUSTOM` and `BLEND_CUSTOM_SEPARATE`, with the factors `rlSetBlendFactors` and `rlSetBlendFactorsSeparate` last set.

		Changing the mode draws the batch first, as does setting a custom mode again after its factors changed. Setting the mode already set
		changes nothing.

		A mode raylib doesn't have changes nothing but the mode remembered.

		@param mode  The mode (`BLEND_*`). */
	static function BeginBlendMode(mode:Int):Void {
		var frame = Runtime.frame;
		if (frame.blendMode == mode && !((mode == BLEND_CUSTOM || mode == BLEND_CUSTOM_SEPARATE) && frame.customBlendChanged))
			return;
		frame.cut();
		var gl = frame.customBlend;
		frame.blend = switch mode {
			case BLEND_ALPHA: helix.raylib.internal.Frame.RAYLIB_ALPHA;
			case BLEND_ADDITIVE: new helix.platform.Blend(SourceAlpha, One);
			case BLEND_MULTIPLIED: new helix.platform.Blend(DestinationColor, OneMinusSourceAlpha);
			case BLEND_ADD_COLORS: new helix.platform.Blend(One, One);
			case BLEND_SUBTRACT_COLORS: new helix.platform.Blend(One, One, Subtract);
			case BLEND_ALPHA_PREMULTIPLY: new helix.platform.Blend(One, OneMinusSourceAlpha);
			case BLEND_CUSTOM: glBlend(frame.blend, gl[0], gl[1], gl[0], gl[1], gl[2], gl[2]);
			case BLEND_CUSTOM_SEPARATE: glBlend(frame.blend, gl[3], gl[4], gl[5], gl[6], gl[7], gl[8]);
			case _: frame.blend;
		}
		frame.blendMode = mode;
		frame.customBlendChanged = false;
	}

	/** Goes back to blending by alpha, as `BeginBlendMode(BLEND_ALPHA)` does. */
	static function EndBlendMode():Void {
		BeginBlendMode(BLEND_ALPHA);
	}

	// A blend from GL's factors and equations, as glBlendFuncSeparate and glBlendEquationSeparate set them over the current one: the factors
	// only when all four are GL's, the equations only when both are (GL refuses the call otherwise, changing nothing). The constant color
	// raylib never sets is GL's 0, 0, 0, 0, so its factors are 0 and its 1 - factors 1.
	static function glBlend(current:helix.platform.Blend, colorSource:Int, colorDestination:Int, alphaSource:Int, alphaDestination:Int, colorEquation:Int,
			alphaEquation:Int):helix.platform.Blend {
		var factors = [
			for (f in [colorSource, colorDestination, alphaSource, alphaDestination])
				glFactor(f)
		], operations = [glOperation(colorEquation), glOperation(alphaEquation)];
		var known = factors.indexOf(null) < 0,
			knownOperations = operations.indexOf(null) < 0;
		return new helix.platform.Blend(known ? factors[0] : current.colorSource, known ? factors[1] : current.colorDestination,
			knownOperations ? operations[0] : current.colorOperation, known ? factors[2] : current.alphaSource, known ? factors[3] : current.alphaDestination,
			knownOperations ? operations[1] : current.alphaOperation);
	}

	static function glFactor(gl:Int):Null<helix.platform.BlendFactor>
		return switch gl {
			case 0 | 0x8001 | 0x8003: Zero;
			case 1 | 0x8002 | 0x8004: One;
			case 0x0300: SourceColor;
			case 0x0301: OneMinusSourceColor;
			case 0x0302: SourceAlpha;
			case 0x0303: OneMinusSourceAlpha;
			case 0x0304: DestinationAlpha;
			case 0x0305: OneMinusDestinationAlpha;
			case 0x0306: DestinationColor;
			case 0x0307: OneMinusDestinationColor;
			case 0x0308: SourceAlphaSaturated;
			case _: null;
		}

	static function glOperation(gl:Int):Null<helix.platform.BlendOperation>
		return switch gl {
			case 0x8006: Add;
			case 0x800A: Subtract;
			case 0x800B: ReverseSubtract;
			case 0x8007: Min;
			case 0x8008: Max;
			case _: null;
		}

	/** Draws only within a rectangle of the screen, or of the render texture drawn into, until `EndScissorMode`.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels.
		@param width  The width.
		@param height  The height. */
	static function BeginScissorMode(x:Int, y:Int, width:Int, height:Int):Void {
		Runtime.frame.cut();
		Runtime.frame.scissor = [x, y, width, height];
	}

	/** Draws everywhere again. */
	static function EndScissorMode():Void {
		Runtime.frame.cut();
		Runtime.frame.scissor = null;
	}
	#end
}
