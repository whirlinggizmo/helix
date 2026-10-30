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
import helix.ray.raylib.HelixRay.*;
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
		return Runtime.resized;
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

	/** Sets flags for the window before `InitWindow` (`FLAG_*`). The window is resizable here whatever they say.

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

	/** Sets the frame rate aimed for. Frames here follow the display's refresh, whatever it is set to.

		@param fps  The frames a second. */
	static function SetTargetFPS(fps:Int):Void {
		targetFps = fps;
	}

	/** Returns the frames a second, averaged over the last half second or so.

		@return  The frames a second. */
	static function GetFPS():Int {
		var delta = Runtime.time == null ? 0. : Runtime.time.realDelta;
		if (delta > 0)
			fps += (1 / delta - fps) * .1;
		return Math.round(fps);
	}

	/** Returns the seconds the last frame took.

		@return  The seconds. */
	static function GetFrameTime():Float {
		return Runtime.time == null ? 0 : Runtime.time.realDelta;
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

	/** Returns whether a gesture happened this frame. Only `GESTURE_TAP` is read here: a finger touching, or the left mouse button
		pressed, as raylib counts it.

		@param gesture  The gesture (`GESTURE_*`).
		@return  True for the frame it happened. */
	static function IsGestureDetected(gesture:Int):Bool {
		if (gesture != GESTURE_TAP)
			return false;
		return Runtime.touch().pressed.length > 0 || Runtime.mouse().isButtonPressed(Left);
	}

	/** Returns the gesture this frame: `GESTURE_TAP` for a finger touching or the left mouse button pressed, else `GESTURE_NONE`. Only
		taps are read here.

		@return  The gesture (`GESTURE_*`). */
	static function GetGestureDetected():Int {
		return IsGestureDetected(GESTURE_TAP) ? GESTURE_TAP : GESTURE_NONE;
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

	/** Returns a button held on any gamepad, as raylib's last button pressed is: set while it is held, not only as it goes down.

		@return  The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held. */
	static function GetGamepadButtonPressed():Int {
		for (pad in 0...4)
			if (IsGamepadAvailable(pad))
				for (button in 1...18)
					if (IsGamepadButtonDown(pad, button))
						return button;
		return GAMEPAD_BUTTON_UNKNOWN;
	}

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

	/** Returns whether a file exists: one the program's save callback or `SaveFileText`/`SaveFileData` wrote, or one of the program's
		loaded in memory.

		@param fileName  The file.
		@return  True when it exists. */
	static function FileExists(fileName:String):Bool {
		var path = normalize(fileName);
		return saved(path)
			|| Runtime.saves != null
			&& Runtime.saves.hasKey(SAVED_DATA + path)
			|| Runtime.files.exists(path)
			|| Runtime.images.exists(path);
	}

	/** Reads a text file: through the program's `SetLoadFileTextCallback` when it has one, else one `SaveFileText` wrote, else one of
		the program's: natively read now; in a page, one an earlier `LoadFileTextAsync` brought in.

		@param fileName  The file.
		@return  Its text, or null when it can't be read. */
	static function LoadFileText(fileName:String):Null<String> {
		var path = normalize(fileName);
		if (loadText != null) {
			var given = loadText(path);
			if (given != null)
				return given;
		}
		if (saved(path))
			return Runtime.saves.getString(SAVED + path, "");
		var bytes = Runtime.fileNow(path);
		if (bytes == null) {
			Runtime.log(4, Runtime.notLoaded("LoadFileText", path));
			return null;
		}
		return bytes.toString();
	}

	/** Frees text `LoadFileText` returned. There is nothing to free here.

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
		if (Runtime.saves == null)
			return false;
		Runtime.saves.setString(SAVED + normalize(fileName), text);
		return true;
	}

	/** raylib's file read, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadFileDataAsync` reads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unimplemented("LoadFileData: Synchronous loading is not supported. See LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void)")
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
		if (Runtime.saves == null)
			return false;
		Runtime.saves.setString(SAVED_DATA + path, haxe.crypto.Base64.encode(data.sub(0, dataSize)));
		return true;
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

	/** Reads text files through the program from now on (`LoadFileText`).

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

	// A file's bytes as they are at hand, without logging: the program's load callback's, then the saves', then the program's own (in
	// a page only as an async load brought them in).

	static function dataNow(path:String):Null<haxe.io.Bytes> {
		if (CallbackFiles.load != null) {
			var given = CallbackFiles.load(path);
			if (given != null)
				return given;
		}
		if (Runtime.saves != null && Runtime.saves.hasKey(SAVED_DATA + path))
			return haxe.crypto.Base64.decode(Runtime.saves.getString(SAVED_DATA + path, ""));
		return Runtime.fileNow(path);
	}

	// Whether a text file was written to the saves.

	static function saved(path:String):Bool
		return Runtime.saves != null && Runtime.saves.hasKey(SAVED + path);

	static inline final SAVED = "file:";
	static var start = 0.;
	static var configFlags = 0;
	static var targetFps = 0;
	static var fps = 60.;
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

	static function quad(x:Float, y:Float, w:Float, h:Float, color:Color):Void {
		var t = Runtime.frame.white;
		flat(t, x, y, 0, 0, color);
		flat(t, x, y + h, 0, 0, color);
		flat(t, x + w, y + h, 0, 0, color);
		flat(t, x, y, 0, 0, color);
		flat(t, x + w, y + h, 0, 0, color);
		flat(t, x + w, y, 0, 0, color);
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

	static function segments(radius:Float):Int {
		var n = Math.ceil(radius * Math.PI / 2);
		return n < 12 ? 12 : n > 96 ? 96 : n;
	}

	static function circle(cx:Float, cy:Float, radius:Float, color:Color):Void {
		var n = segments(radius), t = Runtime.frame.white;
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
			flat(t, cx, cy, 0, 0, color);
			flat(t, cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, 0, 0, color);
			flat(t, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 0, 0, color);
		}
	}

	static function ring(cx:Float, cy:Float, radius:Float, color:Color):Void {
		var n = segments(radius);
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
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

	/** Returns raylib's default shader.

		@return  The shader. */
	static function LoadShaderDefault():Shader {
		return defaultShader();
	}

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
	#end
}
