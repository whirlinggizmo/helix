package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.internal.CallbackFiles;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds raylib's rcore (the window and the frame, the keyboard, mouse, touch and gamepads, files, the 2D and 3D cameras and shaders), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RCore {
	#if !macro
	// ---- Window and frame ----

	/** Opens the window and its graphics. In a page the canvas fills the page, and width and height are ignored.

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

	/** Closes the window, after keeping what `SaveFileText` wrote. */
	static function CloseWindow():Void {
		Runtime.close();
	}

	/** Returns whether the window should close: the exit key was pressed (Escape unless `SetExitKey` changed it) or it was asked to close.
		In a page it is always false; the loop that reads it runs once a frame there.

		@return  True once the window should close. */
	static function WindowShouldClose():Bool {
		return Runtime.shouldClose;
	}

	/** Returns whether the window is open.

		@return  True after `InitWindow`. */
	static function IsWindowReady():Bool {
		return Runtime.window != null;
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

	/** Asks for the window's size. A page's canvas follows the page instead.

		@param width  The width, in pixels.
		@param height  The height, in pixels. */
	static function SetWindowSize(width:Int, height:Int):Void {
		Runtime.window.requestSize(width, height);
	}

	/** Returns whether the window is fullscreen. In a page it tells whether the canvas is.

		@return  True while it is. */
	static function IsWindowFullscreen():Bool {
		return Runtime.window.fullscreen;
	}

	/** Returns whether the program hid the window (`FLAG_WINDOW_HIDDEN`). In a page it tells whether the canvas is hidden.

		@return  True while it is. */
	static function IsWindowHidden():Bool {
		return !Runtime.window.visible;
	}

	/** Returns whether the player can't see the window: minimized, or in a page its tab in the background.

		@return  True while it is. */
	static function IsWindowMinimized():Bool {
		return Runtime.hidden;
	}

	/** Returns whether the window has the keyboard.

		@return  True while it has. */
	static function IsWindowFocused():Bool {
		return Runtime.window.focused;
	}

	/** Asks for fullscreen, or back to the window, the size and place it had. In a page the browser grants it only soon after a key
		press, click or tap; without one, it waits for the player's next. */
	static function ToggleFullscreen():Void {
		Runtime.screen.requestFullscreen(!Runtime.screen.fullscreen);
	}

	/** Asks for the window to fill the screen without borders, or back to the window: here the same as `ToggleFullscreen`, as a
		fullscreen window natively is borderless and the size of the desktop. */
	static function ToggleBorderlessWindowed():Void {
		ToggleFullscreen();
	}

	/** Asks for the window's place on the desktop. Where the window can't be moved (in a page, or under Wayland), nothing changes.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels. */
	static function SetWindowPosition(x:Int, y:Int):Void {
		Runtime.window.requestPosition(x, y);
	}

	/** Asks for the window on another monitor.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`. */
	static function SetWindowMonitor(monitor:Int):Void {
		Runtime.window.requestMonitorIndex(monitor);
	}

	/** Returns the window's place on the desktop.

		@return  Its left and top edges, in pixels. */
	static function GetWindowPosition():Vector2 {
		return new Vector2(Runtime.window.x, Runtime.window.y);
	}

	/** Returns how many of the display's pixels a pixel drawn takes, across and down: 2 on most phones and high-density displays.

		@return  The scale. */
	static function GetWindowScaleDPI():Vector2 {
		return new Vector2(Runtime.window.pixelRatio, Runtime.window.pixelRatio);
	}

	/** Returns the number of monitors. A page sees one.

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

	/** Returns the screen's width, in the pixels drawing is in.

		@return  The width. */
	static function GetScreenWidth():Int {
		return Std.int(Runtime.window.framebufferWidth / Runtime.window.pixelRatio);
	}

	/** Returns the screen's height, in the pixels drawing is in.

		@return  The height. */
	static function GetScreenHeight():Int {
		return Std.int(Runtime.window.framebufferHeight / Runtime.window.pixelRatio);
	}

	/** Returns the framebuffer's width, in the display's pixels.

		@return  The width. */
	static function GetRenderWidth():Int {
		return Runtime.window.framebufferWidth;
	}

	/** Returns the framebuffer's height, in the display's pixels.

		@return  The height. */
	static function GetRenderHeight():Int {
		return Runtime.window.framebufferHeight;
	}

	/** Sets flags for the window before `InitWindow` (`FLAG_*`). `FLAG_MSAA_4X_HINT` asks for 4 samples a pixel, and `FLAG_VSYNC_HINT`
		for frames shown at the display's refresh; without it, frames natively show as soon as they are drawn, as raylib's do, while a
		page's always follow the display. The window is resizable here whatever they say.

		@param flags  The flags, or'd together. */
	static function SetConfigFlags(flags:Int):Void {
		configFlags = flags;
	}

	/** Sets flags on the open window (`FLAG_*`). A window here is resizable whatever they say, and the others aren't read.

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

		@param flag  The flags, or'd together.
		@return  True when all of them are. */
	static function IsWindowState(flag:Int):Bool {
		return configFlags & flag == flag;
	}

	/** Sets the most frames a second, as raylib's `EndDrawing` waits out the rest of each frame. Natively it waits; in a page, where
		frames follow the display's refresh, a frame is skipped until it is time, so a rate above the display's changes nothing.

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

	/** Stops the program for a time, drawing nothing and reading no input until it ends. In a page it spins, as raylib's web build does,
		so the page doesn't respond meanwhile.

		@param seconds  How long. */
	static function WaitTime(seconds:Float):Void {
		Runtime.sleep(seconds);
	}

	/** Returns the seconds since `InitWindow`.

		@return  The seconds. */
	static function GetTime():Float {
		return Runtime.system.getTime() - start;
	}

	/** Sets the key that closes the window natively, or `KEY_NULL` for none. It is Escape until set.

		@param key  The key. */
	static function SetExitKey(key:Int):Void {
		Runtime.exitKey = key;
	}

	/** Begins a frame's drawing. */
	static function BeginDrawing():Void {
		Runtime.frame.begin(GetScreenWidth(), GetScreenHeight());
	}

	/** Ends a frame's drawing: shows it, then reads the next frame's input. */
	static function EndDrawing():Void {
		Runtime.endFrame();
	}

	/** Clears the frame to a color, dropping what was drawn before it.

		@param color  The color. */
	static function ClearBackground(color:Color):Void {
		Runtime.frame.clear((color.a << 24) | (color.r << 16) | (color.g << 8) | color.b);
	}

	/** Returns a random whole number from min to max, both included.

		@param min  The least.
		@param max  The most.
		@return  The number. */
	static function GetRandomValue(min:Int, max:Int):Int {
		if (min > max) {
			var t = min;
			min = max;
			max = t;
		}
		seed ^= seed << 13;
		seed ^= seed >>> 17;
		seed ^= seed << 5;
		var span = max - min + 1;
		var r = (seed >>> 1) % span;
		return min + r;
	}

	/** Seeds `GetRandomValue`, so its numbers repeat from the same seed.

		@param seed  The seed. */
	static function SetRandomSeed(seed:Int):Void {
		RCore.seed = seed == 0 ? 1 : seed;
		seeded = true;
	}

	// ---- Keyboard ----

	/** Returns whether a key went down this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	static function IsKeyPressed(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyPressed(cast k);
	}

	/** Returns whether a key is held.

		@param key  The key (`KEY_*`).
		@return  True while it is down. */
	static function IsKeyDown(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyDown(cast k);
	}

	/** Returns whether a key went up this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	static function IsKeyReleased(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyReleased(cast k);
	}

	/** Returns whether a key isn't held.

		@param key  The key (`KEY_*`).
		@return  True while it is up. */
	static function IsKeyUp(key:Int):Bool {
		return !IsKeyDown(key);
	}

	/** Returns the next key pressed this frame, each once; call it until it returns `KEY_NULL`.

		@return  The key (`KEY_*`), or `KEY_NULL` when no more were pressed. */
	static function GetKeyPressed():Int {
		Runtime.keyboard();
		return Runtime.keysPressed.length == 0 ? KEY_NULL : Runtime.keysPressed.shift();
	}

	/** Returns whether the OS repeated a held key this frame, as it does after a moment, at its own rate.

		@param key  The key (`KEY_*`).
		@return  True for the frames it repeated. */
	static function IsKeyPressedRepeat(key:Int):Bool {
		Runtime.keyboard();
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyRepeated(cast k);
	}

	/** Returns the next character typed this frame, each once; call it until it returns 0. Typed text is read from the first call on, so
		on a phone its keyboard shows from then.

		@return  The character's codepoint, or 0 when no more were typed. */
	static function GetCharPressed():Int {
		Runtime.typing();
		return Runtime.charsPressed.length == 0 ? 0 : Runtime.charsPressed.shift();
	}

	// ---- Mouse and touch ----

	/** Returns whether a mouse button went down this frame. A finger touching counts as the left button, as in raylib.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsMouseButtonPressed(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT
			&& Runtime.touch().pressed.length > 0
			&& Runtime.touch().fingers.length == Runtime.touch().pressed.length)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonPressed(cast button);
	}

	/** Returns whether a mouse button is held. A finger down counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is down. */
	static function IsMouseButtonDown(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().fingers.length > 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonDown(cast button);
	}

	/** Returns whether a mouse button went up this frame. The last finger lifting counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsMouseButtonReleased(button:Int):Bool {
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

	/** Returns the mouse's x, in the screen's pixels; the first finger's while one is down.

		@return  The x. */
	static function GetMouseX():Int {
		return Std.int(GetMousePosition().x);
	}

	/** Returns the mouse's y, in the screen's pixels; the first finger's while one is down.

		@return  The y. */
	static function GetMouseY():Int {
		return Std.int(GetMousePosition().y);
	}

	/** Returns the mouse's position, in the screen's pixels; the first finger's while one is down.

		@return  The position. */
	static function GetMousePosition():Vector2 {
		var mouse = Runtime.mouse(),
			touch = Runtime.touch(),
			ratio = Runtime.window.pixelRatio;
		var fingers = touch.fingers.length > 0 ? touch.fingers : touch.released;
		if (fingers.length > 0) {
			lastPointerX = touch.getX(fingers[0]) / ratio;
			lastPointerY = touch.getY(fingers[0]) / ratio;
		} else if (mouse.x != lastMouseX || mouse.y != lastMouseY) {
			lastMouseX = mouse.x;
			lastMouseY = mouse.y;
			lastPointerX = mouse.x / ratio;
			lastPointerY = mouse.y / ratio;
		}
		return new Vector2(lastPointerX, lastPointerY);
	}

	/** Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.

		@return  The notches. */
	static function GetMouseWheelMove():Float {
		var mouse = Runtime.mouse();
		return Math.abs(mouse.wheelX) > Math.abs(mouse.wheelY) ? mouse.wheelX : mouse.wheelY;
	}

	/** Returns the number of fingers down.

		@return  The count. */
	static function GetTouchPointCount():Int {
		return Runtime.touch().fingers.length;
	}

	/** Returns a finger's position, in the screen's pixels.

		@param index  Which finger, 0 for the first down.
		@return  The position, or (0, 0) when fewer are down. */
	static function GetTouchPosition(index:Int):Vector2 {
		var touch = Runtime.touch(), ratio = Runtime.window.pixelRatio;
		if (index < 0 || index >= touch.fingers.length)
			return new Vector2();
		var id = touch.fingers[index];
		return new Vector2(touch.getX(id) / ratio, touch.getY(id) / ratio);
	}

	/** Returns the first finger's x, in the screen's pixels.

		@return  The x. */
	static function GetTouchX():Int {
		return Std.int(GetTouchPosition(0).x);
	}

	/** Returns the first finger's y, in the screen's pixels.

		@return  The y. */
	static function GetTouchY():Int {
		return Std.int(GetTouchPosition(0).y);
	}

	/** Sets which gestures are detected; all of them until it is called.

		@param flags  The gestures (`GESTURE_*`), or'd together. */
	static function SetGesturesEnabled(flags:Int):Void {
		Runtime.gestures().enabled = flags;
	}

	/** Returns whether a gesture is the one detected now. A mouse button counts as a finger, as in raylib. A tap or double tap lasts a
		frame, then becomes a hold; a swipe lasts a frame.

		@param gesture  The gesture (`GESTURE_*`).
		@return  True while it is the gesture, and enabled. */
	static function IsGestureDetected(gesture:Int):Bool {
		return Runtime.gestures().isDetected(gesture);
	}

	/** Returns the gesture detected now.

		@return  The gesture (`GESTURE_*`), or `GESTURE_NONE` when it isn't enabled. */
	static function GetGestureDetected():Int {
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

	/** Returns whether a gamepad is connected.

		@param gamepad  The gamepad, 0 to 3.
		@return  True while one is connected there. */
	static function IsGamepadAvailable(gamepad:Int):Bool {
		return gamepad >= 0 && gamepad < 4 && Runtime.gamepads().isConnected(gamepad);
	}

	/** Returns a gamepad's name.

		@param gamepad  The gamepad, 0 to 3.
		@return  Its name, or "" when none is connected. */
	static function GetGamepadName(gamepad:Int):String {
		return IsGamepadAvailable(gamepad) ? Runtime.gamepads().getName(gamepad) : "";
	}

	/** Returns whether a gamepad's button went down this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonPressed(gamepad, cast b);
	}

	/** Returns whether a gamepad's button is held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is down. */
	static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonDown(gamepad, cast b);
	}

	/** Returns whether a gamepad's button went up this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonReleased(gamepad, cast b);
	}

	/** Returns whether a gamepad's button isn't held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is up. */
	static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool {
		return !IsGamepadButtonDown(gamepad, button);
	}

	/** Returns the last button held, as raylib polls them: gamepads 0 to 3, each's buttons in the browser's order in a page (the second
		triggers among them, the middle button never), else GLFW's (the middle button among them, the second triggers never).

		@return  The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held. */
	static function GetGamepadButtonPressed():Int {
		var last = GAMEPAD_BUTTON_UNKNOWN;
		for (pad in 0...4)
			if (IsGamepadAvailable(pad))
				for (button in pollOrder)
					if (IsGamepadButtonDown(pad, button))
						last = button;
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

	/** Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1
		released to 1 pulled, as raylib's are.

		@param gamepad  The gamepad, 0 to 3.
		@param axis  The axis (`GAMEPAD_AXIS_*`).
		@return  The value. */
	static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float {
		if (axis < 0 || axis > 5 || !IsGamepadAvailable(gamepad))
			return 0;
		var value = Runtime.gamepads().getAxis(gamepad, cast axis);
		return axis >= GAMEPAD_AXIS_LEFT_TRIGGER ? value * 2 - 1 : value;
	}

	// ---- Files ----

	/** raylib's check for a file, which waits for the answer. A page can't wait, so a call doesn't compile on any target:
		`FileExistsAsync` answers it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)")
	static function FileExists(fileName:String):Bool {
		throw "FileExists is unimplemented";
	}

	/** raylib's text file read, which waits for the file. A page can't wait, so a call doesn't compile on any target:
		`LoadFileTextAsync` reads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)")
	static function LoadFileText(fileName:String):Null<String> {
		throw "LoadFileText is unimplemented";
	}

	/** Frees text `LoadFileTextAsync` gave. There is nothing to free here.

		@param text  The text. */
	static function UnloadFileText(text:Null<String>):Void {}

	/** Writes a text file: through the program's `SetSaveFileTextCallback` when it has one, else kept across runs (in a page, in its
		storage; natively, in the program's data directory), kept at the end of the frame.

		@param fileName  The file.
		@param text  Its text.
		@return  True when it was written, or will be. */
	static function SaveFileText(fileName:String, text:String):Bool {
		if (saveText != null)
			return saveText(normalize(fileName), text);
		var path = normalize(fileName);
		Runtime.keptSaves().setString(SAVED + path, text);
		return true;
	}

	/** raylib's file read, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadFileDataAsync` reads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFileData: Synchronous loading is not supported. See LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void)")
	static function LoadFileData(fileName:String):Null<haxe.io.Bytes> {
		throw "LoadFileData is unimplemented";
	}

	/** Frees bytes `LoadFileDataAsync` gave. There is nothing to free here.

		@param data  The bytes. */
	static function UnloadFileData(data:Null<haxe.io.Bytes>):Void {}

	/** Writes a file's bytes: through the program's `SetSaveFileDataCallback` when it has one, else kept across runs as
		`SaveFileText`'s are.

		@param fileName  The file.
		@param data  The bytes.
		@param dataSize  How many of them.
		@return  True when it was written, or will be. */
	static function SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool {
		var path = normalize(fileName);
		if (saveData != null)
			return saveData(path, data, dataSize);
		var encoded = haxe.crypto.Base64.encode(data.sub(0, dataSize));
		Runtime.keptSaves().setString(SAVED_DATA + path, encoded);
		return true;
	}

	// ---- File names ----

	/** Returns whether a file name ends in one of some extensions, ignoring the case of A to Z.

		@param fileName  The file name.
		@param ext  The extensions with their dots, `;` between them: ".png;.jpg".
		@return  True when its extension, from its last dot, is one of them. */
	static function IsFileExtension(fileName:String, ext:String):Bool {
		var fileExt = GetFileExtension(fileName);
		if (fileExt == null)
			return false;
		// raylib keeps 16 characters of the file's extension, and splits the list into at most 128.
		var lower = asciiLower(fileExt).substr(0, 16);
		var checks = ext.split(";");
		if (checks.length >= 128)
			checks = checks.slice(0, 127).concat([""]);
		for (check in checks)
			if (asciiLower(check) == lower)
				return true;
		return false;
	}

	/** Returns a file name's extension, from its last dot: "file.tar.gz" gives ".gz".

		@param fileName  The file name, or a path.
		@return  The extension with its dot, or null when there is no dot or the name starts with its only one. */
	static function GetFileExtension(fileName:String):String {
		var dot = fileName.lastIndexOf(".");
		return dot <= 0 ? null : fileName.substr(dot);
	}

	/** Returns a path's file name: what follows its last `/` or `\`.

		@param filePath  The path.
		@return  The file name with its extension; the path itself when it has no slash. */
	static function GetFileName(filePath:String):String {
		if (filePath == null)
			return null;
		return filePath.substr(lastSlash(filePath) + 1);
	}

	/** Returns a path's file name without its extension: up to its last dot, unless that dot is its first character.

		@param filePath  The path.
		@return  The file name; "" for null. */
	static function GetFileNameWithoutExt(filePath:String):String {
		if (filePath == null)
			return "";
		var name = GetFileName(filePath);
		var dot = name.lastIndexOf(".");
		return dot > 0 ? name.substr(0, dot) : name;
	}

	/** Returns the directory of a path: up to its last `/` or `\`. A relative path's starts "./", as raylib's does: "dir/file.png"
		gives "./dir", "file.png" gives "./", and "/file.png" gives "/".

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

	/** Returns the directory a path is in: up to its last `/` or `\`, keeping a root's ("/", "C:\").

		@param dirPath  The path.
		@return  The directory above it; the path itself when it has 3 characters or fewer, and "" when a longer one has no slash. */
	static function GetPrevDirectoryPath(dirPath:String):String {
		if (dirPath.length <= 3)
			return dirPath;
		var i = lastSlash(dirPath);
		if (i < 0)
			return "";
		if ((i == 2 && dirPath.charAt(1) == ":") || i == 0)
			i++;
		return dirPath.substr(0, i);
	}

	/** Returns whether a file name could name a file on any system: none of `< > : " / \ | ? *` or a control character, and not
		only dots.

		@param fileName  The file name, without a directory.
		@return  True when it could; true for null or "", as raylib's is. */
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

	// ---- Encoding and hashes ----

	/** Returns DEFLATE data decompressed: a raw stream with no zlib header, as raylib's `CompressData` makes. Like raylib's, it gives
		at most 64 MB.

		@param compData  The compressed bytes.
		@param compDataSize  How many of them.
		@param dataSize  Its first element is set to how many bytes it gives.
		@return  The bytes. Data that isn't DEFLATE, or stops short, gives what was read before it, perhaps nothing, and a warning. */
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

	/** Returns some bytes as Base64 text, padded with `=` to a multiple of 4 characters.

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

	/** Returns the bytes of Base64 text. It reads 4 characters at a time up to a zero byte or the end, and a character that isn't
		Base64's reads as 0, as raylib's does.

		@param data  The text's bytes.
		@param outputSize  Its first element is set to how many bytes it gives.
		@return  The bytes. */
	static function DecodeDataBase64(data:haxe.io.Bytes, outputSize:Array<Int>):haxe.io.Bytes {
		var at = (i:Int) -> i < data.length ? data.get(i) : 0;
		var value = (i:Int) -> {
			var c = at(i);
			return if (c >= "A".code && c <= "Z".code) c - "A".code; else if (c >= "a".code && c <= "z".code) c - "a".code + 26; else if (c >= "0".code
				&& c <= "9".code) c
				- "0".code + 52; else if (c == "+".code) 62; else if (c == "/".code) 63; else 0;
		}
		var size = 0, i = 0;
		while (at(4 * i) != 0) {
			size += at(4 * i + 3) != "=".code ? 3 : at(4 * i + 2) == "=".code ? 1 : 2;
			i++;
		}
		var decoded = haxe.io.Bytes.alloc(size);
		for (i in 0...Std.int((size + 2) / 3)) {
			var a = value(4 * i),
				b = value(4 * i + 1),
				c = value(4 * i + 2),
				d = value(4 * i + 3);
			var bytes = [(a << 2) | (b >> 4), (b << 4) | (c >> 2), (c << 6) | d];
			for (j in 0...3)
				if (3 * i + j < size)
					decoded.set(3 * i + j, bytes[j] & 255);
		}
		if (outputSize != null)
			outputSize[0] = size;
		return decoded;
	}

	/** Returns the CRC-32 of some bytes, as zlib and PNG compute it.

		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Its 32 bits; one above 0x7fffffff is negative. */
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

	/** Returns the SHA-1 hash of some bytes, as raylib 5.5 computes it: its padding holds only the lowest byte of the length in bits,
		so from 32 bytes on it differs from standard SHA-1.

		@param data  The bytes.
		@param dataSize  How many of them.
		@return  Its 5 words, the first the hash's first 4 bytes, the highest first; one above 0x7fffffff is negative. */
	static function ComputeSHA1(data:haxe.io.Bytes, dataSize:Int):Array<Int> {
		var hash = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
		var newDataSize = (Std.int((dataSize + 8) / 64) + 1) * 64;
		var msg = haxe.io.Bytes.alloc(newDataSize);
		msg.fill(0, msg.length, 0);
		msg.blit(0, data, 0, dataSize);
		msg.set(dataSize, 128);
		msg.set(newDataSize - 1, (8 * dataSize) & 255);
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

	// ---- Hooks ----

	/** Reads files through the program from now on: every load raylib makes of a file (textures, models, sounds, music, data) asks it
		first, and a file it doesn't have (null) is read as it would be. In a page, a texture's or model's images still decode only
		asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load those it gives.

		@param callback  Returns a file's bytes, or null; null for none. */
	static function SetLoadFileDataCallback(callback:Null<(fileName:String) -> Null<haxe.io.Bytes>>):Void {
		CallbackFiles.load = callback;
	}

	/** Writes files through the program from now on (`SaveFileData`).

		@param callback  Writes a file's bytes, returning whether it did; null for none. */
	static function SetSaveFileDataCallback(callback:Null<(fileName:String, data:haxe.io.Bytes, dataSize:Int) -> Bool>):Void {
		saveData = callback;
	}

	/** Reads text files through the program from now on (`LoadFileTextAsync`).

		@param callback  Returns a file's text, or null; null for none. */
	static function SetLoadFileTextCallback(callback:Null<(fileName:String) -> Null<String>>):Void {
		loadText = callback;
	}

	/** Writes text files through the program from now on (`SaveFileText`).

		@param callback  Writes a file's text, returning whether it did; null for none. */
	static function SetSaveFileTextCallback(callback:Null<(fileName:String, text:String) -> Bool>):Void {
		saveText = callback;
	}

	// ---- Log ----

	/** Writes a message to the log, when its level is at least `SetTraceLogLevel`'s. raylib formats its arguments as printf does;
		here the text is written as it is (Haxe's string interpolation builds it).

		@param logLevel  The level (`LOG_*`).
		@param text  The message. */
	static function TraceLog(logLevel:Int, text:String):Void {
		Runtime.log(logLevel, text);
	}

	/** Sets the least level the log writes; `LOG_INFO` until set.

		@param logLevel  The level (`LOG_*`). */
	static function SetTraceLogLevel(logLevel:Int):Void {
		Runtime.logLevel = logLevel;
	}

	/** Writes the log through the program from now on, helix-ray's own messages among it.

		@param callback  Receives each message's level and text; null for helix-ray's own log. */
	static function SetTraceLogCallback(callback:Null<(logLevel:Int, text:String) -> Void>):Void {
		Runtime.logCallback = callback;
	}

	// ---- What the functions share ----
	static inline final SAVED_DATA = "data:";
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
	static var seed = 0x2545f491;
	static var seeded = false;
	static var lastMouseX = 0.;
	static var lastMouseY = 0.;
	static var lastPointerX = 0.;
	static var lastPointerY = 0.;
	static var font:Null<Texture2D> = null;
	static var fontRecs:Array<Int> = [];

	static function normalize(path:String):String {
		while (StringTools.startsWith(path, "./"))
			path = path.substr(2);
		return path;
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

	static function toPadButton(button:Int):Int {
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

	// The default font's texture, made at its first use, and each glyph's place on it, as raylib lays them out.

	static function defaultFont():Texture2D {
		if (font != null)
			return font;
		var size = 128, pixels = haxe.io.Bytes.alloc(size * size * 4);
		for (i in 0...size * size >> 5) {
			var word = DefaultFont.BITS[i];
			for (j in 0...32) {
				var at = (i * 32 + j) * 4;
				pixels.set(at, 255);
				pixels.set(at + 1, 255);
				pixels.set(at + 2, 255);
				pixels.set(at + 3, (word >>> j) & 1 == 1 ? 255 : 0);
			}
		}
		font = new Texture2D(Textures.fromHandle(Runtime.graphics.createTexture(size, size, [pixels])), size, size);
		var line = 0, x = 1, test = 1;
		for (i in 0...DefaultFont.WIDTHS.length) {
			var w = DefaultFont.WIDTHS[i];
			var gx = x, gy = 1 + line * (DefaultFont.HEIGHT + 1);
			test += w + 1;
			if (test >= size) {
				line++;
				x = 2 + w;
				test = x;
				gx = 1;
				gy = 1 + line * (DefaultFont.HEIGHT + 1);
			} else
				x = test;
			fontRecs.push(gx);
			fontRecs.push(gy);
		}
		return font;
	}

	// An immediate vertex in 2D, at z 0.

	static inline function flat(texture:Int, x:Float, y:Float, u:Float, v:Float, color:Color):Void {
		Runtime.frame.vertex(texture, false, x, y, 0, u, v, color);
	}

	// A filled rectangle, with the shapes texture.
	static function quad(x:Float, y:Float, w:Float, h:Float, color:Color):Void {
		corner(x, y, 0, color);
		corner(x, y + h, 1, color);
		corner(x + w, y + h, 2, color);
		corner(x + w, y, 3, color);
	}

	static function line(x1:Float, y1:Float, x2:Float, y2:Float, thick:Float, color:Color):Void {
		var dx = x2 - x1, dy = y2 - y1, length = Math.sqrt(dx * dx + dy * dy);
		if (length == 0)
			return;
		var nx = -dy / length * thick / 2, ny = dx / length * thick / 2;
		var t = Runtime.frame.white;
		flat(t, x1 + nx, y1 + ny, 0, 0, color);
		flat(t, x1 - nx, y1 - ny, 0, 0, color);
		flat(t, x2 - nx, y2 - ny, 0, 0, color);
		flat(t, x1 + nx, y1 + ny, 0, 0, color);
		flat(t, x2 - nx, y2 - ny, 0, 0, color);
		flat(t, x2 + nx, y2 + ny, 0, 0, color);
	}

	static function frame(x:Float, y:Float, w:Float, h:Float, thick:Float, color:Color):Void {
		quad(x, y, w, thick, color);
		quad(x, y + h - thick, w, thick, color);
		quad(x, y + thick, thick, h - thick * 2, color);
		quad(x + w - thick, y + thick, thick, h - thick * 2, color);
	}

	// A filled circle as raylib draws one: a sector of 36 segments, or more where the radius needs them.
	static function circle(cx:Float, cy:Float, radius:Float, color:Color):Void {
		DrawCircleSector(new Vector2(cx, cy), radius, 0, 360, 36, color);
	}

	// A circle's outline as raylib draws one: 36 lines, one every 10 degrees.
	static function ring(cx:Float, cy:Float, radius:Float, color:Color):Void {
		for (i in 0...36) {
			var a0 = i * 10 * DEG2RAD, a1 = (i + 1) * 10 * DEG2RAD;
			line(cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 1, color);
		}
	}

	// ---- 2D camera ----

	/** Draws through a 2D camera until `EndMode2D`.

		@param camera  The camera. */
	static function BeginMode2D(camera:Camera2D):Void {
		Runtime.frame.cut();
		Runtime.frame.view = toMatrix3D(GetCameraMatrix2D(camera));
	}

	/** Goes back to drawing in the screen's pixels. */
	static function EndMode2D():Void {
		Runtime.frame.screen2D();
	}

	/** Returns a 2D camera's transform, from the world to the screen.

		@param camera  The camera.
		@return  The matrix. */
	static function GetCameraMatrix2D(camera:Camera2D):Matrix {
		var m = new Matrix3D().makeTranslation(-camera.target.x, -camera.target.y, 0);
		m = new Matrix3D().compose(m, new Matrix3D().makeRotation(0, 0, 1, camera.rotation * DEG2RAD));
		m = new Matrix3D().compose(m, new Matrix3D().makeScale(camera.zoom, camera.zoom, 1));
		m = new Matrix3D().compose(m, new Matrix3D().makeTranslation(camera.offset.x, camera.offset.y, 0));
		return toMatrix(m);
	}

	/** Returns where a point in a 2D camera's world is on the screen.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = toMatrix3D(GetCameraMatrix2D(camera)).transformPoint(position.x, position.y, 0);
		return new Vector2(p.x, p.y);
	}

	/** Returns where a screen position is in a 2D camera's world.

		@param position  The screen position.
		@param camera  The camera.
		@return  The point. */
	static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2 {
		var inverse = toMatrix3D(GetCameraMatrix2D(camera));
		inverse.invert();
		var p = inverse.transformPoint(position.x, position.y, 0);
		return new Vector2(p.x, p.y);
	}

	// ---- 3D camera ----

	/** Draws in 3D through a camera until `EndMode3D`, with depth.

		@param camera  The camera. */
	static function BeginMode3D(camera:Camera3D):Void {
		var f = Runtime.frame;
		f.cut();
		f.in3D = true;
		f.view = cameraView(camera);
		f.projection = cameraProjection(camera, f.width / f.height);
	}

	/** Goes back to drawing in 2D, in the screen's pixels. */
	static function EndMode3D():Void {
		Runtime.frame.screen2D();
		Runtime.frame.in3D = false;
	}

	/** Moves a camera as one of raylib's modes does: `CAMERA_ORBITAL` turns it about its target, half a radian a second, and the
		wheel moves it closer; `CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` move it by WASD, and turn it by the mouse;
		`CAMERA_CUSTOM` leaves it.

		@param camera  The camera, changed.
		@param mode  The mode (`CAMERA_*`). */
	static function UpdateCamera(camera:Camera3D, mode:Int):Void {
		var dt = GetFrameTime();
		switch mode {
			case CAMERA_ORBITAL:
				var offset = Vector3Subtract(camera.position, camera.target);
				offset = Vector3RotateByAxisAngle(offset, camera.up, .5 * dt);
				var wheel = GetMouseWheelMove();
				if (wheel != 0) {
					var d = Vector3Length(offset) - wheel;
					if (d > .1)
						offset = Vector3Scale(Vector3Normalize(offset), d);
				}
				camera.position = Vector3Add(camera.target, offset);
			case CAMERA_FREE | CAMERA_FIRST_PERSON | CAMERA_THIRD_PERSON:
				var forward = Vector3Normalize(Vector3Subtract(camera.target, camera.position));
				if (mode != CAMERA_FREE)
					forward = Vector3Normalize(new Vector3(forward.x, 0, forward.z));
				var right = Vector3Normalize(Vector3CrossProduct(forward, camera.up));
				var move = new Vector3();
				var speed = 5.4 * dt;
				if (IsKeyDown(KEY_W))
					move = Vector3Add(move, Vector3Scale(forward, speed));
				if (IsKeyDown(KEY_S))
					move = Vector3Subtract(move, Vector3Scale(forward, speed));
				if (IsKeyDown(KEY_D))
					move = Vector3Add(move, Vector3Scale(right, speed));
				if (IsKeyDown(KEY_A))
					move = Vector3Subtract(move, Vector3Scale(right, speed));
				camera.position = Vector3Add(camera.position, move);
				camera.target = Vector3Add(camera.target, move);
				var delta = GetMouseDelta();
				var look = Vector3Subtract(camera.target, camera.position);
				look = Vector3RotateByAxisAngle(look, camera.up, -delta.x * .003);
				look = Vector3RotateByAxisAngle(look, right, -delta.y * .003);
				camera.target = Vector3Add(camera.position, look);
			case _:
		}
	}

	/** Returns a camera's view, as `BeginMode3D` uses it.

		@param camera  The camera.
		@return  The matrix. */
	static function GetCameraMatrix(camera:Camera3D):Matrix {
		return toMatrix(cameraView(camera));
	}

	/** Returns the ray from a camera through a screen position, as raylib's picking uses it.

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
		var x = 2 * position.x / width - 1, y = 1 - 2 * position.y / height;
		var inverse = new Matrix3D().compose(cameraView(camera), cameraProjection(camera, width / height));
		inverse.invert();
		function unproject(z:Float):Array<Float> {
			var p = [
				inverse.values[0] * x + inverse.values[4] * y + inverse.values[8] * z + inverse.values[12],
				inverse.values[1] * x + inverse.values[5] * y + inverse.values[9] * z + inverse.values[13],
				inverse.values[2] * x + inverse.values[6] * y + inverse.values[10] * z + inverse.values[14],
				inverse.values[3] * x + inverse.values[7] * y + inverse.values[11] * z + inverse.values[15]
			];
			return [p[0] / p[3], p[1] / p[3], p[2] / p[3]];
		}
		var near = unproject(-1), far = unproject(1);
		var origin = camera.projection == CAMERA_ORTHOGRAPHIC ? new Vector3(near[0], near[1], near[2]) : camera.position;
		return new Ray(new Vector3(origin.x, origin.y, origin.z), Vector3Normalize(new Vector3(far[0] - near[0], far[1] - near[1], far[2] - near[2])));
	}

	/** Returns the ray from a camera through a screen position: raylib's old name for `GetScreenToWorldRay`.

		@param position  The screen position.
		@param camera  The camera.
		@return  The ray. */
	static function GetMouseRay(position:Vector2, camera:Camera3D):Ray {
		return GetScreenToWorldRay(position, camera);
	}

	/** Returns where a point in the world is on the screen.

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
		@return  The position in the view. */
	static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2 {
		var m = new Matrix3D().compose(cameraView(camera), cameraProjection(camera, width / height)).values;
		var x = m[0] * position.x + m[4] * position.y + m[8] * position.z + m[12];
		var y = m[1] * position.x + m[5] * position.y + m[9] * position.z + m[13];
		var w = m[3] * position.x + m[7] * position.y + m[11] * position.z + m[15];
		if (w == 0)
			w = 1;
		return new Vector2((x / w + 1) / 2 * width, (1 - y / w) / 2 * height);
	}

	/** Returns how far the mouse moved since the last frame, in the screen's pixels.

		@return  The movement. */
	static function GetMouseDelta():Vector2 {
		var now = GetMousePosition();
		var frame = Runtime.frames;
		if (frame != deltaFrame) {
			deltaFrame = frame;
			deltaX = now.x - previousX;
			deltaY = now.y - previousY;
			previousX = now.x;
			previousY = now.y;
		}
		return new Vector2(deltaX, deltaY);
	}

	// ---- Shaders ----

	/** Returns whether a shader was made.

		@param shader  The shader.
		@return  True when it was. */
	static function IsShaderValid(shader:Shader):Bool {
		return shader.id != 0;
	}

	/** Frees a shader; the default one stays.

		@param shader  The shader. */
	static function UnloadShader(shader:Shader):Void {
		if (shader.program != null && shader.program != Runtime.frame.defaultProgram) {
			shader.program.dispose();
			shader.program = null;
			shader.id = 0;
		}
	}

	/** Returns the location of a shader's uniform or texture, by its name.

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

	/** Sets a shader's uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The value: a number, an array of numbers, or a `Vector2`, `Vector3`, `Vector4` or `Color`.
		@param uniformType  Its type (`SHADER_UNIFORM_*`). */
	static function SetShaderValue(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int):Void {
		SetShaderValueV(shader, locIndex, value, uniformType, 1);
	}

	/** Sets elements of a shader's array uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The values, in order.
		@param uniformType  Each element's type (`SHADER_UNIFORM_*`).
		@param count  The elements set. */
	static function SetShaderValueV(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0)
			return;
		Runtime.frame.cut();
		shader.program.write(locIndex, numbers(value));
	}

	/** Sets a shader's matrix uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param mat  The matrix. */
	static function SetShaderValueMatrix(shader:Shader, locIndex:Int, mat:Matrix):Void {
		if (shader.program == null)
			return;
		Runtime.frame.cut();
		shader.program.write(locIndex, toMatrix3D(mat).values);
	}

	/** Sets a shader's texture, for the draws after it.

		@param shader  The shader.
		@param locIndex  The texture's location.
		@param texture  The texture. */
	static function SetShaderValueTexture(shader:Shader, locIndex:Int, texture:Texture2D):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0) {
			Runtime.frame.cut();
			shader.program.textures[slot] = Textures.handle(texture.id);
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

	/** Blends what is drawn until `EndBlendMode` another way. `BLEND_ALPHA` and `BLEND_ADDITIVE` are here; the others draw as
		`BLEND_ALPHA` does, and say so once in the log.

		@param mode  The mode (`BLEND_*`). */
	static function BeginBlendMode(mode:Int):Void {
		var blend:helix.platform.BlendMode = switch mode {
			case BLEND_ADDITIVE: Additive;
			case BLEND_ALPHA: Alpha;
			case _:
				if (!blendsWarned.exists(mode)) {
					blendsWarned.set(mode, true);
					Runtime.log(LOG_WARNING, 'BeginBlendMode: blend mode $mode isn\'t in helix-ray yet; drawing with BLEND_ALPHA');
				}
				Alpha;
		}
		Runtime.frame.cut();
		Runtime.frame.blend = blend;
	}

	/** Goes back to blending by alpha. */
	static function EndBlendMode():Void {
		Runtime.frame.cut();
		Runtime.frame.blend = Alpha;
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

	static final blendsWarned = new Map<Int, Bool>();
	#end
}
