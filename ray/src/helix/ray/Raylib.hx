package helix.ray;

import helix.ray.internal.DefaultFont;
import helix.ray.internal.Runtime;

/** Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in
	a page and natively.

	A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a
	frame. The files under the program's directory are loaded before its `main` runs, so `LoadTexture` and `LoadSound` answer at once.
	`SaveFileText` writes are kept across runs. This is the 2D part of raylib: no 3D, shaders, fonts other than the default, or images
	on the CPU yet. */
class Raylib {
	// ---- Keys (KeyboardKey) ----

	/** Key: NULL, used for no key pressed. */
	public static inline final KEY_NULL = 0;

	/** Key: '. */
	public static inline final KEY_APOSTROPHE = 39;

	/** Key: ,. */
	public static inline final KEY_COMMA = 44;

	/** Key: -. */
	public static inline final KEY_MINUS = 45;

	/** Key: . */
	public static inline final KEY_PERIOD = 46;

	/** Key: /. */
	public static inline final KEY_SLASH = 47;

	/** Key: 0. */
	public static inline final KEY_ZERO = 48;

	/** Key: 1. */
	public static inline final KEY_ONE = 49;

	/** Key: 2. */
	public static inline final KEY_TWO = 50;

	/** Key: 3. */
	public static inline final KEY_THREE = 51;

	/** Key: 4. */
	public static inline final KEY_FOUR = 52;

	/** Key: 5. */
	public static inline final KEY_FIVE = 53;

	/** Key: 6. */
	public static inline final KEY_SIX = 54;

	/** Key: 7. */
	public static inline final KEY_SEVEN = 55;

	/** Key: 8. */
	public static inline final KEY_EIGHT = 56;

	/** Key: 9. */
	public static inline final KEY_NINE = 57;

	/** Key: ;. */
	public static inline final KEY_SEMICOLON = 59;

	/** Key: =. */
	public static inline final KEY_EQUAL = 61;

	/** Key: A | a. */
	public static inline final KEY_A = 65;

	/** Key: B | b. */
	public static inline final KEY_B = 66;

	/** Key: C | c. */
	public static inline final KEY_C = 67;

	/** Key: D | d. */
	public static inline final KEY_D = 68;

	/** Key: E | e. */
	public static inline final KEY_E = 69;

	/** Key: F | f. */
	public static inline final KEY_F = 70;

	/** Key: G | g. */
	public static inline final KEY_G = 71;

	/** Key: H | h. */
	public static inline final KEY_H = 72;

	/** Key: I | i. */
	public static inline final KEY_I = 73;

	/** Key: J | j. */
	public static inline final KEY_J = 74;

	/** Key: K | k. */
	public static inline final KEY_K = 75;

	/** Key: L | l. */
	public static inline final KEY_L = 76;

	/** Key: M | m. */
	public static inline final KEY_M = 77;

	/** Key: N | n. */
	public static inline final KEY_N = 78;

	/** Key: O | o. */
	public static inline final KEY_O = 79;

	/** Key: P | p. */
	public static inline final KEY_P = 80;

	/** Key: Q | q. */
	public static inline final KEY_Q = 81;

	/** Key: R | r. */
	public static inline final KEY_R = 82;

	/** Key: S | s. */
	public static inline final KEY_S = 83;

	/** Key: T | t. */
	public static inline final KEY_T = 84;

	/** Key: U | u. */
	public static inline final KEY_U = 85;

	/** Key: V | v. */
	public static inline final KEY_V = 86;

	/** Key: W | w. */
	public static inline final KEY_W = 87;

	/** Key: X | x. */
	public static inline final KEY_X = 88;

	/** Key: Y | y. */
	public static inline final KEY_Y = 89;

	/** Key: Z | z. */
	public static inline final KEY_Z = 90;

	/** Key: [. */
	public static inline final KEY_LEFT_BRACKET = 91;

	/** Key: '\'. */
	public static inline final KEY_BACKSLASH = 92;

	/** Key: ]. */
	public static inline final KEY_RIGHT_BRACKET = 93;

	/** Key: `. */
	public static inline final KEY_GRAVE = 96;

	/** Key: Space. */
	public static inline final KEY_SPACE = 32;

	/** Key: Esc. */
	public static inline final KEY_ESCAPE = 256;

	/** Key: Enter. */
	public static inline final KEY_ENTER = 257;

	/** Key: Tab. */
	public static inline final KEY_TAB = 258;

	/** Key: Backspace. */
	public static inline final KEY_BACKSPACE = 259;

	/** Key: Ins. */
	public static inline final KEY_INSERT = 260;

	/** Key: Del. */
	public static inline final KEY_DELETE = 261;

	/** Key: Cursor right. */
	public static inline final KEY_RIGHT = 262;

	/** Key: Cursor left. */
	public static inline final KEY_LEFT = 263;

	/** Key: Cursor down. */
	public static inline final KEY_DOWN = 264;

	/** Key: Cursor up. */
	public static inline final KEY_UP = 265;

	/** Key: Page up. */
	public static inline final KEY_PAGE_UP = 266;

	/** Key: Page down. */
	public static inline final KEY_PAGE_DOWN = 267;

	/** Key: Home. */
	public static inline final KEY_HOME = 268;

	/** Key: End. */
	public static inline final KEY_END = 269;

	/** Key: Caps lock. */
	public static inline final KEY_CAPS_LOCK = 280;

	/** Key: Scroll down. */
	public static inline final KEY_SCROLL_LOCK = 281;

	/** Key: Num lock. */
	public static inline final KEY_NUM_LOCK = 282;

	/** Key: Print screen. */
	public static inline final KEY_PRINT_SCREEN = 283;

	/** Key: Pause. */
	public static inline final KEY_PAUSE = 284;

	/** Key: F1. */
	public static inline final KEY_F1 = 290;

	/** Key: F2. */
	public static inline final KEY_F2 = 291;

	/** Key: F3. */
	public static inline final KEY_F3 = 292;

	/** Key: F4. */
	public static inline final KEY_F4 = 293;

	/** Key: F5. */
	public static inline final KEY_F5 = 294;

	/** Key: F6. */
	public static inline final KEY_F6 = 295;

	/** Key: F7. */
	public static inline final KEY_F7 = 296;

	/** Key: F8. */
	public static inline final KEY_F8 = 297;

	/** Key: F9. */
	public static inline final KEY_F9 = 298;

	/** Key: F10. */
	public static inline final KEY_F10 = 299;

	/** Key: F11. */
	public static inline final KEY_F11 = 300;

	/** Key: F12. */
	public static inline final KEY_F12 = 301;

	/** Key: Shift left. */
	public static inline final KEY_LEFT_SHIFT = 340;

	/** Key: Control left. */
	public static inline final KEY_LEFT_CONTROL = 341;

	/** Key: Alt left. */
	public static inline final KEY_LEFT_ALT = 342;

	/** Key: Super left. */
	public static inline final KEY_LEFT_SUPER = 343;

	/** Key: Shift right. */
	public static inline final KEY_RIGHT_SHIFT = 344;

	/** Key: Control right. */
	public static inline final KEY_RIGHT_CONTROL = 345;

	/** Key: Alt right. */
	public static inline final KEY_RIGHT_ALT = 346;

	/** Key: Super right. */
	public static inline final KEY_RIGHT_SUPER = 347;

	/** Key: KB menu. */
	public static inline final KEY_KB_MENU = 348;

	/** Key: Keypad 0. */
	public static inline final KEY_KP_0 = 320;

	/** Key: Keypad 1. */
	public static inline final KEY_KP_1 = 321;

	/** Key: Keypad 2. */
	public static inline final KEY_KP_2 = 322;

	/** Key: Keypad 3. */
	public static inline final KEY_KP_3 = 323;

	/** Key: Keypad 4. */
	public static inline final KEY_KP_4 = 324;

	/** Key: Keypad 5. */
	public static inline final KEY_KP_5 = 325;

	/** Key: Keypad 6. */
	public static inline final KEY_KP_6 = 326;

	/** Key: Keypad 7. */
	public static inline final KEY_KP_7 = 327;

	/** Key: Keypad 8. */
	public static inline final KEY_KP_8 = 328;

	/** Key: Keypad 9. */
	public static inline final KEY_KP_9 = 329;

	/** Key: Keypad . */
	public static inline final KEY_KP_DECIMAL = 330;

	/** Key: Keypad /. */
	public static inline final KEY_KP_DIVIDE = 331;

	/** Key: Keypad *. */
	public static inline final KEY_KP_MULTIPLY = 332;

	/** Key: Keypad -. */
	public static inline final KEY_KP_SUBTRACT = 333;

	/** Key: Keypad +. */
	public static inline final KEY_KP_ADD = 334;

	/** Key: Keypad Enter. */
	public static inline final KEY_KP_ENTER = 335;

	/** Key: Keypad =. */
	public static inline final KEY_KP_EQUAL = 336;

	/** Key: Android back button. */
	public static inline final KEY_BACK = 4;

	/** Key: Android menu button. */
	public static inline final KEY_MENU = 5;

	/** Key: Android volume up button. */
	public static inline final KEY_VOLUME_UP = 24;

	/** Key: Android volume down button. */
	public static inline final KEY_VOLUME_DOWN = 25;

	// ---- Mouse buttons (MouseButton) ----

	/** Mouse button left. */
	public static inline final MOUSE_BUTTON_LEFT = 0;

	/** Mouse button right. */
	public static inline final MOUSE_BUTTON_RIGHT = 1;

	/** Mouse button middle (pressed wheel). */
	public static inline final MOUSE_BUTTON_MIDDLE = 2;

	/** Mouse button side (advanced mouse device). */
	public static inline final MOUSE_BUTTON_SIDE = 3;

	/** Mouse button extra (advanced mouse device). */
	public static inline final MOUSE_BUTTON_EXTRA = 4;

	/** Mouse button forward (advanced mouse device). */
	public static inline final MOUSE_BUTTON_FORWARD = 5;

	/** Mouse button back (advanced mouse device). */
	public static inline final MOUSE_BUTTON_BACK = 6;

	// ---- Gamepad buttons (GamepadButton) ----

	/** Unknown button, just for error checking. */
	public static inline final GAMEPAD_BUTTON_UNKNOWN = 0;

	/** Gamepad left DPAD up button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_UP = 1;

	/** Gamepad left DPAD right button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_RIGHT = 2;

	/** Gamepad left DPAD down button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_DOWN = 3;

	/** Gamepad left DPAD left button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_LEFT = 4;

	/** Gamepad right button up (i.e. PS3: Triangle, Xbox: Y). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_UP = 5;

	/** Gamepad right button right (i.e. PS3: Circle, Xbox: B). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_RIGHT = 6;

	/** Gamepad right button down (i.e. PS3: Cross, Xbox: A). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_DOWN = 7;

	/** Gamepad right button left (i.e. PS3: Square, Xbox: X). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_LEFT = 8;

	/** Gamepad top/back trigger left (first), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_LEFT_TRIGGER_1 = 9;

	/** Gamepad top/back trigger left (second), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_LEFT_TRIGGER_2 = 10;

	/** Gamepad top/back trigger right (first), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_RIGHT_TRIGGER_1 = 11;

	/** Gamepad top/back trigger right (second), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_RIGHT_TRIGGER_2 = 12;

	/** Gamepad center buttons, left one (i.e. PS3: Select). */
	public static inline final GAMEPAD_BUTTON_MIDDLE_LEFT = 13;

	/** Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX). */
	public static inline final GAMEPAD_BUTTON_MIDDLE = 14;

	/** Gamepad center buttons, right one (i.e. PS3: Start). */
	public static inline final GAMEPAD_BUTTON_MIDDLE_RIGHT = 15;

	/** Gamepad joystick pressed button left. */
	public static inline final GAMEPAD_BUTTON_LEFT_THUMB = 16;

	/** Gamepad joystick pressed button right. */
	public static inline final GAMEPAD_BUTTON_RIGHT_THUMB = 17;

	// ---- Gamepad axes (GamepadAxis) ----

	/** Gamepad left stick X axis. */
	public static inline final GAMEPAD_AXIS_LEFT_X = 0;

	/** Gamepad left stick Y axis. */
	public static inline final GAMEPAD_AXIS_LEFT_Y = 1;

	/** Gamepad right stick X axis. */
	public static inline final GAMEPAD_AXIS_RIGHT_X = 2;

	/** Gamepad right stick Y axis. */
	public static inline final GAMEPAD_AXIS_RIGHT_Y = 3;

	/** Gamepad back trigger left, pressure level: [1..-1]. */
	public static inline final GAMEPAD_AXIS_LEFT_TRIGGER = 4;

	/** Gamepad back trigger right, pressure level: [1..-1]. */
	public static inline final GAMEPAD_AXIS_RIGHT_TRIGGER = 5;

	// ---- Window flags (ConfigFlags) ----

	/** Set to try enabling V-Sync on GPU. */
	public static inline final FLAG_VSYNC_HINT = 64;

	/** Set to run program in fullscreen. */
	public static inline final FLAG_FULLSCREEN_MODE = 2;

	/** Set to allow resizable window. */
	public static inline final FLAG_WINDOW_RESIZABLE = 4;

	/** Set to disable window decoration (frame and buttons). */
	public static inline final FLAG_WINDOW_UNDECORATED = 8;

	/** Set to hide window. */
	public static inline final FLAG_WINDOW_HIDDEN = 128;

	/** Set to minimize window (iconify). */
	public static inline final FLAG_WINDOW_MINIMIZED = 512;

	/** Set to maximize window (expanded to monitor). */
	public static inline final FLAG_WINDOW_MAXIMIZED = 1024;

	/** Set to window non focused. */
	public static inline final FLAG_WINDOW_UNFOCUSED = 2048;

	/** Set to window always on top. */
	public static inline final FLAG_WINDOW_TOPMOST = 4096;

	/** Set to allow windows running while minimized. */
	public static inline final FLAG_WINDOW_ALWAYS_RUN = 256;

	/** Set to allow transparent framebuffer. */
	public static inline final FLAG_WINDOW_TRANSPARENT = 16;

	/** Set to support HighDPI. */
	public static inline final FLAG_WINDOW_HIGHDPI = 8192;

	/** Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED. */
	public static inline final FLAG_WINDOW_MOUSE_PASSTHROUGH = 16384;

	/** Set to run program in borderless windowed mode. */
	public static inline final FLAG_BORDERLESS_WINDOWED_MODE = 32768;

	/** Set to try enabling MSAA 4X. */
	public static inline final FLAG_MSAA_4X_HINT = 32;

	/** Set to try enabling interlaced video format (for V3D). */
	public static inline final FLAG_INTERLACED_HINT = 65536;

	// ---- Gestures (Gesture) ----

	/** No gesture. */
	public static inline final GESTURE_NONE = 0;

	/** Tap gesture. */
	public static inline final GESTURE_TAP = 1;

	/** Double tap gesture. */
	public static inline final GESTURE_DOUBLETAP = 2;

	/** Hold gesture. */
	public static inline final GESTURE_HOLD = 4;

	/** Drag gesture. */
	public static inline final GESTURE_DRAG = 8;

	/** Swipe right gesture. */
	public static inline final GESTURE_SWIPE_RIGHT = 16;

	/** Swipe left gesture. */
	public static inline final GESTURE_SWIPE_LEFT = 32;

	/** Swipe up gesture. */
	public static inline final GESTURE_SWIPE_UP = 64;

	/** Swipe down gesture. */
	public static inline final GESTURE_SWIPE_DOWN = 128;

	/** Pinch in gesture. */
	public static inline final GESTURE_PINCH_IN = 256;

	/** Pinch out gesture. */
	public static inline final GESTURE_PINCH_OUT = 512;

	// ---- Colors ----

	/** Light Gray. */
	public static final LIGHTGRAY:Color = new Color(200, 200, 200, 255);

	/** Gray. */
	public static final GRAY:Color = new Color(130, 130, 130, 255);

	/** Dark Gray. */
	public static final DARKGRAY:Color = new Color(80, 80, 80, 255);

	/** Yellow. */
	public static final YELLOW:Color = new Color(253, 249, 0, 255);

	/** Gold. */
	public static final GOLD:Color = new Color(255, 203, 0, 255);

	/** Orange. */
	public static final ORANGE:Color = new Color(255, 161, 0, 255);

	/** Pink. */
	public static final PINK:Color = new Color(255, 109, 194, 255);

	/** Red. */
	public static final RED:Color = new Color(230, 41, 55, 255);

	/** Maroon. */
	public static final MAROON:Color = new Color(190, 33, 55, 255);

	/** Green. */
	public static final GREEN:Color = new Color(0, 228, 48, 255);

	/** Lime. */
	public static final LIME:Color = new Color(0, 158, 47, 255);

	/** Dark Green. */
	public static final DARKGREEN:Color = new Color(0, 117, 44, 255);

	/** Sky Blue. */
	public static final SKYBLUE:Color = new Color(102, 191, 255, 255);

	/** Blue. */
	public static final BLUE:Color = new Color(0, 121, 241, 255);

	/** Dark Blue. */
	public static final DARKBLUE:Color = new Color(0, 82, 172, 255);

	/** Purple. */
	public static final PURPLE:Color = new Color(200, 122, 255, 255);

	/** Violet. */
	public static final VIOLET:Color = new Color(135, 60, 190, 255);

	/** Dark Purple. */
	public static final DARKPURPLE:Color = new Color(112, 31, 126, 255);

	/** Beige. */
	public static final BEIGE:Color = new Color(211, 176, 131, 255);

	/** Brown. */
	public static final BROWN:Color = new Color(127, 106, 79, 255);

	/** Dark Brown. */
	public static final DARKBROWN:Color = new Color(76, 63, 47, 255);

	/** White. */
	public static final WHITE:Color = new Color(255, 255, 255, 255);

	/** Black. */
	public static final BLACK:Color = new Color(0, 0, 0, 255);

	/** Blank (Transparent). */
	public static final BLANK:Color = new Color(0, 0, 0, 0);

	/** Magenta. */
	public static final MAGENTA:Color = new Color(255, 0, 255, 255);

	/** My own White (raylib logo). */
	public static final RAYWHITE:Color = new Color(245, 245, 245, 255);

	/** The pixel format of every texture loaded here: 8-bit red, green, blue and alpha. */
	public static inline final PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 = 7;

	/** Pi. */
	public static inline final PI = 3.14159265358979323846;

	/** Degrees to radians. */
	public static inline final DEG2RAD = PI / 180;

	/** Radians to degrees. */
	public static inline final RAD2DEG = 180 / PI;

	// ---- Window and frame ----

	/** Opens the window and its graphics. In a page the canvas fills the page, and width and height are ignored.

		@param width  The window's width, in pixels.
		@param height  The window's height, in pixels.
		@param title  The window's title. */
	public static function InitWindow(width:Int, height:Int, title:String):Void {
		Runtime.open(width, height, title);
		start = Runtime.system.getTime();
	}

	/** Closes the window, after keeping what `SaveFileText` wrote. */
	public static function CloseWindow():Void {
		Runtime.close();
	}

	/** Returns whether the window should close: the exit key was pressed (Escape unless `SetExitKey` changed it) or it was asked to close.
		In a page it is always false; the loop that reads it runs once a frame there.

		@return  True once the window should close. */
	public static function WindowShouldClose():Bool {
		return Runtime.shouldClose;
	}

	/** Returns whether the window is open.

		@return  True after `InitWindow`. */
	public static function IsWindowReady():Bool {
		return Runtime.window != null;
	}

	/** Returns whether the window changed size since the last frame.

		@return  True for the frame after a resize. */
	public static function IsWindowResized():Bool {
		return Runtime.resized;
	}

	/** Sets the window's title.

		@param title  The title. */
	public static function SetWindowTitle(title:String):Void {
		Runtime.window.title = title;
	}

	/** Asks for the window's size. A page's canvas follows the page instead.

		@param width  The width, in pixels.
		@param height  The height, in pixels. */
	public static function SetWindowSize(width:Int, height:Int):Void {
		Runtime.window.requestSize(width, height);
	}

	/** Returns the screen's width, in the pixels drawing is in.

		@return  The width. */
	public static function GetScreenWidth():Int {
		return Std.int(Runtime.window.framebufferWidth / Runtime.window.pixelRatio);
	}

	/** Returns the screen's height, in the pixels drawing is in.

		@return  The height. */
	public static function GetScreenHeight():Int {
		return Std.int(Runtime.window.framebufferHeight / Runtime.window.pixelRatio);
	}

	/** Returns the framebuffer's width, in the display's pixels.

		@return  The width. */
	public static function GetRenderWidth():Int {
		return Runtime.window.framebufferWidth;
	}

	/** Returns the framebuffer's height, in the display's pixels.

		@return  The height. */
	public static function GetRenderHeight():Int {
		return Runtime.window.framebufferHeight;
	}

	/** Sets flags for the window before `InitWindow` (`FLAG_*`). The window is resizable here whatever they say.

		@param flags  The flags, or'd together. */
	public static function SetConfigFlags(flags:Int):Void {
		configFlags = flags;
	}

	/** Sets the frame rate aimed for. Frames here follow the display's refresh, whatever it is set to.

		@param fps  The frames a second. */
	public static function SetTargetFPS(fps:Int):Void {
		targetFps = fps;
	}

	/** Returns the frames a second, averaged over the last half second or so.

		@return  The frames a second. */
	public static function GetFPS():Int {
		var delta = Runtime.time == null ? 0. : Runtime.time.realDelta;
		if (delta > 0)
			fps += (1 / delta - fps) * .1;
		return Math.round(fps);
	}

	/** Returns the seconds the last frame took.

		@return  The seconds. */
	public static function GetFrameTime():Float {
		return Runtime.time == null ? 0 : Runtime.time.realDelta;
	}

	/** Returns the seconds since `InitWindow`.

		@return  The seconds. */
	public static function GetTime():Float {
		return Runtime.system.getTime() - start;
	}

	/** Sets the key that closes the window natively, or `KEY_NULL` for none. It is Escape until set.

		@param key  The key. */
	public static function SetExitKey(key:Int):Void {
		Runtime.exitKey = key;
	}

	/** Begins a frame's drawing. */
	public static function BeginDrawing():Void {}

	/** Ends a frame's drawing: shows it, then reads the next frame's input. */
	public static function EndDrawing():Void {
		Runtime.endFrame();
	}

	/** Clears the frame to a color, dropping what was drawn before it.

		@param color  The color. */
	public static function ClearBackground(color:Color):Void {
		Runtime.batch.clear();
		Runtime.clearColor = (color.a << 24) | (color.r << 16) | (color.g << 8) | color.b;
	}

	/** Returns a random whole number from min to max, both included.

		@param min  The least.
		@param max  The most.
		@return  The number. */
	public static function GetRandomValue(min:Int, max:Int):Int {
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
	public static function SetRandomSeed(seed:Int):Void {
		Raylib.seed = seed == 0 ? 1 : seed;
	}

	// ---- Keyboard ----

	/** Returns whether a key went down this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	public static function IsKeyPressed(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyPressed(cast k);
	}

	/** Returns whether a key is held.

		@param key  The key (`KEY_*`).
		@return  True while it is down. */
	public static function IsKeyDown(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyDown(cast k);
	}

	/** Returns whether a key went up this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	public static function IsKeyReleased(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyReleased(cast k);
	}

	/** Returns whether a key isn't held.

		@param key  The key (`KEY_*`).
		@return  True while it is up. */
	public static function IsKeyUp(key:Int):Bool {
		return !IsKeyDown(key);
	}

	/** Returns the next key pressed this frame, each once; call it until it returns `KEY_NULL`.

		@return  The key (`KEY_*`), or `KEY_NULL` when no more were pressed. */
	public static function GetKeyPressed():Int {
		Runtime.keyboard();
		return Runtime.keysPressed.length == 0 ? KEY_NULL : Runtime.keysPressed.shift();
	}

	// ---- Mouse and touch ----

	/** Returns whether a mouse button went down this frame. A finger touching counts as the left button, as in raylib.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsMouseButtonPressed(button:Int):Bool {
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
	public static function IsMouseButtonDown(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().fingers.length > 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonDown(cast button);
	}

	/** Returns whether a mouse button went up this frame. The last finger lifting counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsMouseButtonReleased(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().released.length > 0 && Runtime.touch().fingers.length == 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonReleased(cast button);
	}

	/** Returns whether a mouse button isn't held.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is up. */
	public static function IsMouseButtonUp(button:Int):Bool {
		return !IsMouseButtonDown(button);
	}

	/** Returns the mouse's x, in the screen's pixels; the first finger's while one is down.

		@return  The x. */
	public static function GetMouseX():Int {
		return Std.int(GetMousePosition().x);
	}

	/** Returns the mouse's y, in the screen's pixels; the first finger's while one is down.

		@return  The y. */
	public static function GetMouseY():Int {
		return Std.int(GetMousePosition().y);
	}

	/** Returns the mouse's position, in the screen's pixels; the first finger's while one is down.

		@return  The position. */
	public static function GetMousePosition():Vector2 {
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
	public static function GetMouseWheelMove():Float {
		var mouse = Runtime.mouse();
		return Math.abs(mouse.wheelX) > Math.abs(mouse.wheelY) ? mouse.wheelX : mouse.wheelY;
	}

	/** Returns the number of fingers down.

		@return  The count. */
	public static function GetTouchPointCount():Int {
		return Runtime.touch().fingers.length;
	}

	/** Returns a finger's position, in the screen's pixels.

		@param index  Which finger, 0 for the first down.
		@return  The position, or (0, 0) when fewer are down. */
	public static function GetTouchPosition(index:Int):Vector2 {
		var touch = Runtime.touch(), ratio = Runtime.window.pixelRatio;
		if (index < 0 || index >= touch.fingers.length)
			return new Vector2();
		var id = touch.fingers[index];
		return new Vector2(touch.getX(id) / ratio, touch.getY(id) / ratio);
	}

	/** Returns the first finger's x, in the screen's pixels.

		@return  The x. */
	public static function GetTouchX():Int {
		return Std.int(GetTouchPosition(0).x);
	}

	/** Returns the first finger's y, in the screen's pixels.

		@return  The y. */
	public static function GetTouchY():Int {
		return Std.int(GetTouchPosition(0).y);
	}

	/** Returns whether a gesture happened this frame. Only `GESTURE_TAP` is read here: a finger touching, or the left mouse button
		pressed, as raylib counts it.

		@param gesture  The gesture (`GESTURE_*`).
		@return  True for the frame it happened. */
	public static function IsGestureDetected(gesture:Int):Bool {
		if (gesture != GESTURE_TAP)
			return false;
		return Runtime.touch().pressed.length > 0 || Runtime.mouse().isButtonPressed(Left);
	}

	// ---- Gamepads ----

	/** Returns whether a gamepad is connected.

		@param gamepad  The gamepad, 0 to 3.
		@return  True while one is connected there. */
	public static function IsGamepadAvailable(gamepad:Int):Bool {
		return gamepad >= 0 && gamepad < 4 && Runtime.gamepads().isConnected(gamepad);
	}

	/** Returns a gamepad's name.

		@param gamepad  The gamepad, 0 to 3.
		@return  Its name, or "" when none is connected. */
	public static function GetGamepadName(gamepad:Int):String {
		return IsGamepadAvailable(gamepad) ? Runtime.gamepads().getName(gamepad) : "";
	}

	/** Returns whether a gamepad's button went down this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonPressed(gamepad, cast b);
	}

	/** Returns whether a gamepad's button is held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is down. */
	public static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonDown(gamepad, cast b);
	}

	/** Returns whether a gamepad's button went up this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonReleased(gamepad, cast b);
	}

	/** Returns whether a gamepad's button isn't held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is up. */
	public static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool {
		return !IsGamepadButtonDown(gamepad, button);
	}

	/** Returns a button held on any gamepad, as raylib's last button pressed is: set while it is held, not only as it goes down.

		@return  The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held. */
	public static function GetGamepadButtonPressed():Int {
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
	public static function GetGamepadAxisCount(gamepad:Int):Int {
		return IsGamepadAvailable(gamepad) ? 6 : 0;
	}

	/** Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1
		released to 1 pulled, as raylib's are.

		@param gamepad  The gamepad, 0 to 3.
		@param axis  The axis (`GAMEPAD_AXIS_*`).
		@return  The value. */
	public static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float {
		if (axis < 0 || axis > 5 || !IsGamepadAvailable(gamepad))
			return 0;
		var value = Runtime.gamepads().getAxis(gamepad, cast axis);
		return axis >= GAMEPAD_AXIS_LEFT_TRIGGER ? value * 2 - 1 : value;
	}

	// ---- Shapes ----

	/** Draws one pixel.

		@param posX  The x.
		@param posY  The y.
		@param color  The color. */
	public static function DrawPixel(posX:Int, posY:Int, color:Color):Void {
		quad(posX, posY, 1, 1, color);
	}

	/** Draws one pixel.

		@param position  The position.
		@param color  The color. */
	public static function DrawPixelV(position:Vector2, color:Color):Void {
		quad(position.x, position.y, 1, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPosX  The start's x.
		@param startPosY  The start's y.
		@param endPosX  The end's x.
		@param endPosY  The end's y.
		@param color  The color. */
	public static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void {
		line(startPosX + .5, startPosY + .5, endPosX + .5, endPosY + .5, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	public static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, 1, color);
	}

	/** Draws a line of a thickness.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	public static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, thick, color);
	}

	/** Draws a filled circle.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		circle(centerX, centerY, radius, color);
	}

	/** Draws a filled circle.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void {
		circle(center.x, center.y, radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		ring(centerX, centerY, radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void {
		ring(center.x, center.y, radius, color);
	}

	/** Draws a filled rectangle.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		quad(posX, posY, width, height, color);
	}

	/** Draws a filled rectangle.

		@param position  The top-left corner.
		@param size  The width and height.
		@param color  The color. */
	public static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void {
		quad(position.x, position.y, size.x, size.y, color);
	}

	/** Draws a filled rectangle.

		@param rec  The rectangle.
		@param color  The color. */
	public static function DrawRectangleRec(rec:Rectangle, color:Color):Void {
		quad(rec.x, rec.y, rec.width, rec.height, color);
	}

	/** Draws a rectangle's outline, one pixel wide.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		frame(posX, posY, width, height, 1, color);
	}

	/** Draws a rectangle's outline, its lines inside it.

		@param rec  The rectangle.
		@param lineThick  The lines' thickness.
		@param color  The color. */
	public static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void {
		frame(rec.x, rec.y, rec.width, rec.height, lineThick, color);
	}

	/** Draws a filled triangle; its points go counterclockwise, as raylib's do.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	public static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		var w = Runtime.batch.white;
		Runtime.batch.vertex(w, v1.x, v1.y, 0, 0, color);
		Runtime.batch.vertex(w, v2.x, v2.y, 0, 0, color);
		Runtime.batch.vertex(w, v3.x, v3.y, 0, 0, color);
	}

	/** Returns whether two rectangles overlap.

		@param rec1  One rectangle.
		@param rec2  The other.
		@return  True when they overlap. */
	public static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool {
		return rec1.x < rec2.x + rec2.width && rec1.x + rec1.width > rec2.x && rec1.y < rec2.y + rec2.height && rec1.y + rec1.height > rec2.y;
	}

	/** Returns whether two circles overlap.

		@param center1  One circle's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	public static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool {
		var dx = center2.x - center1.x, dy = center2.y - center1.y;
		return dx * dx + dy * dy <= (radius1 + radius2) * (radius1 + radius2);
	}

	/** Returns whether a circle and a rectangle overlap.

		@param center  The circle's center.
		@param radius  Its radius.
		@param rec  The rectangle.
		@return  True when they overlap. */
	public static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool {
		var x = Math.max(rec.x, Math.min(center.x, rec.x + rec.width)),
			y = Math.max(rec.y, Math.min(center.y, rec.y + rec.height));
		var dx = center.x - x, dy = center.y - y;
		return dx * dx + dy * dy <= radius * radius;
	}

	/** Returns whether a point is inside a rectangle.

		@param point  The point.
		@param rec  The rectangle.
		@return  True when it is inside. */
	public static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool {
		return point.x >= rec.x && point.x < rec.x + rec.width && point.y >= rec.y && point.y < rec.y + rec.height;
	}

	/** Returns whether a point is inside a circle.

		@param point  The point.
		@param center  The circle's center.
		@param radius  Its radius.
		@return  True when it is inside. */
	public static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool {
		return CheckCollisionCircles(point, 0, center, radius);
	}

	// ---- Textures ----

	/** Loads an image file as a texture. The program's files are loaded before `main`, so it is ready at once.

		@param fileName  The file, as the program names it, such as "assets/player.png".
		@return  The texture; its `id` is 0 when the file couldn't be read. */
	public static function LoadTexture(fileName:String):Texture2D {
		var image = Runtime.images.get(normalize(fileName));
		if (image == null) {
			trace('LoadTexture: $fileName was not loaded');
			return new Texture2D();
		}
		return new Texture2D(Runtime.graphics.createTexture(image.width, image.height, [image.pixels]), image.width, image.height);
	}

	/** Frees a texture.

		@param texture  The texture. */
	public static function UnloadTexture(texture:Texture2D):Void {
		if (texture.id != 0)
			Runtime.graphics.disposeTexture(texture.id);
		texture.id = 0;
	}

	/** Returns whether a texture was loaded.

		@param texture  The texture.
		@return  True when it holds an image. */
	public static function IsTextureValid(texture:Texture2D):Bool {
		return texture.id != 0;
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param posX  The x.
		@param posY  The y.
		@param tint  The color it is multiplied by; `WHITE` keeps it as it is. */
	public static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(posX, posY, texture.width, texture.height), new Vector2(),
			0, tint);
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param position  The point.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(position.x, position.y, texture.width, texture.height),
			new Vector2(), 0, tint);
	}

	/** Draws a texture turned about its top-left corner and scaled.

		@param texture  The texture.
		@param position  The top-left corner.
		@param rotation  Clockwise, in degrees.
		@param scale  The scale.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height),
			new Rectangle(position.x, position.y, texture.width * scale, texture.height * scale), new Vector2(), rotation, tint);
	}

	/** Draws part of a texture. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param position  Where its top-left corner goes.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, source, new Rectangle(position.x, position.y, Math.abs(source.width), Math.abs(source.height)), new Vector2(), 0, tint);
	}

	/** Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param dest  Where it goes; its x and y are where the origin lands.
		@param origin  The point it turns about, from dest's top-left corner.
		@param rotation  Clockwise, in degrees.
		@param tint  The color it is multiplied by. */
	public static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var u0 = source.x / texture.width, v0 = source.y / texture.height;
		var u1 = (source.x + Math.abs(source.width)) / texture.width,
			v1 = (source.y + Math.abs(source.height)) / texture.height;
		if (source.width < 0) {
			var t = u0;
			u0 = u1;
			u1 = t;
		}
		if (source.height < 0) {
			var t = v0;
			v0 = v1;
			v1 = t;
		}
		var angle = rotation * Math.PI / 180,
			c = Math.cos(angle),
			s = Math.sin(angle);
		var xs = [-origin.x, dest.width - origin.x],
			ys = [-origin.y, dest.height - origin.y];
		var corner = (i:Int, j:Int, u:Float,
			v:Float) -> Runtime.batch.vertex(texture.id, dest.x + xs[i] * c - ys[j] * s, dest.y + xs[i] * s + ys[j] * c, u, v, tint);
		corner(0, 0, u0, v0);
		corner(0, 1, u0, v1);
		corner(1, 1, u1, v1);
		corner(0, 0, u0, v0);
		corner(1, 1, u1, v1);
		corner(1, 0, u1, v0);
	}

	// ---- Text ----

	/** Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.

		@param text  The text; "\n" starts a line.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	public static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var font = defaultFont();
		var x = 0., y = 0.;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			if (code == "\n".code) {
				y += fontSize + 2;
				x = 0;
				continue;
			}
			var index = glyph(code);
			var w = DefaultFont.WIDTHS[index];
			if (code != " ".code && code != "\t".code) {
				var gx = fontRecs[index * 2], gy = fontRecs[index * 2 + 1];
				DrawTexturePro(font, new Rectangle(gx, gy, w, DefaultFont.HEIGHT), new Rectangle(posX + x, posY + y, w * scale, fontSize), new Vector2(), 0,
					color);
			}
			x += w * scale + spacing;
		}
	}

	/** Returns the width text is drawn at by `DrawText`, its widest line's.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@return  The width, in pixels. */
	public static function MeasureText(text:String, fontSize:Int):Int {
		if (text.length == 0)
			return 0;
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var width = 0., widest = 0., count = 0, most = 0;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			if (code == "\n".code) {
				if (width > widest)
					widest = width;
				width = 0;
				count = 0;
			} else
				width += DefaultFont.WIDTHS[glyph(code)];
			if (count > most)
				most = count;
		}
		if (width > widest)
			widest = width;
		return Std.int(widest * scale + (most - 1) * spacing);
	}

	/** Draws the frames a second, as "60 FPS", in green.

		@param posX  The left edge.
		@param posY  The top edge. */
	public static function DrawFPS(posX:Int, posY:Int):Void {
		var fps = GetFPS();
		var color = fps < 15 ? RED : fps < 30 ? ORANGE : LIME;
		DrawText('${fps < 10 ? " " : ""}$fps FPS', posX, posY, 20, color);
	}

	// ---- Audio ----

	/** Opens the audio output. In a page it plays once the player's first press lets it. */
	public static function InitAudioDevice():Void {
		if (Runtime.output != null)
			return;
		#if js
		Runtime.output = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		Runtime.audioDecoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
		#else
		Runtime.output = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		Runtime.audioDecoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
		#end
		Runtime.polled.push(Runtime.output);
		Runtime.polled.push(Runtime.audioDecoder);
	}

	/** Closes the audio output, stopping every sound. */
	public static function CloseAudioDevice():Void {
		if (Runtime.output == null)
			return;
		Runtime.polled.remove(Runtime.output);
		Runtime.polled.remove(Runtime.audioDecoder);
		Runtime.audioDecoder.dispose();
		Runtime.output.dispose();
		Runtime.output = null;
		Runtime.audioDecoder = null;
	}

	/** Returns whether the audio output is open.

		@return  True after `InitAudioDevice`. */
	public static function IsAudioDeviceReady():Bool {
		return Runtime.output != null && Runtime.output.available;
	}

	/** Sets the volume of every sound.

		@param volume  0 (silent) to 1. */
	public static function SetMasterVolume(volume:Float):Void {
		masterVolume = volume;
	}

	/** Loads a sound file whole. It decodes in the background; played before then, it starts once decoded.

		@param fileName  The file, as the program names it, such as "assets/coin.wav".
		@return  The sound. */
	public static function LoadSound(fileName:String):Sound {
		var sound = new Sound();
		var bytes = Runtime.files.get(normalize(fileName));
		if (bytes == null || Runtime.audioDecoder == null) {
			trace(bytes == null ? 'LoadSound: $fileName was not loaded' : 'LoadSound: InitAudioDevice first');
			return sound;
		}
		Runtime.audioDecoder.decode(bytes, samples -> {
			if (sound.unloaded || Runtime.output == null)
				return;
			sound.clip = Runtime.output.createClip(samples);
			sound.frameCount = Std.int(samples.length / 8);
			for (_ in 0...sound.waiting)
				PlaySound(sound);
			sound.waiting = 0;
		}, error -> trace('LoadSound: $fileName: $error'));
		return sound;
	}

	/** Frees a sound, stopping it.

		@param sound  The sound. */
	public static function UnloadSound(sound:Sound):Void {
		StopSound(sound);
		if (sound.clip != 0 && Runtime.output != null)
			Runtime.output.disposeClip(sound.clip);
		sound.clip = 0;
		sound.unloaded = true;
	}

	/** Returns whether a sound was loaded.

		@param sound  The sound.
		@return  True once it is decoded. */
	public static function IsSoundValid(sound:Sound):Bool {
		return sound.clip != 0;
	}

	/** Plays a sound from its start, restarting it when it is already playing.

		@param sound  The sound. */
	public static function PlaySound(sound:Sound):Void {
		if (Runtime.output == null || sound.unloaded)
			return;
		if (sound.clip == 0) {
			sound.waiting++;
			return;
		}
		StopSound(sound);
		sound.voice = Runtime.output.playClip(sound.clip, false, sound.volume * masterVolume);
	}

	/** Stops a sound.

		@param sound  The sound. */
	public static function StopSound(sound:Sound):Void {
		if (sound.voice != 0 && Runtime.output != null)
			Runtime.output.stop(sound.voice);
		sound.voice = 0;
	}

	/** Returns whether a sound is playing.

		@param sound  The sound.
		@return  True while it plays. */
	public static function IsSoundPlaying(sound:Sound):Bool {
		return sound.voice != 0 && Runtime.output != null && Runtime.output.isPlaying(sound.voice);
	}

	/** Sets a sound's volume, for its next play and the one playing.

		@param sound  The sound.
		@param volume  0 (silent) to 1. */
	public static function SetSoundVolume(sound:Sound, volume:Float):Void {
		sound.volume = volume;
		if (sound.voice != 0 && Runtime.output != null)
			Runtime.output.setVolume(sound.voice, volume * masterVolume);
	}

	// ---- Files ----

	/** Returns whether a file exists: one `SaveFileText` wrote, or one of the program's.

		@param fileName  The file.
		@return  True when it exists. */
	public static function FileExists(fileName:String):Bool {
		var path = normalize(fileName);
		return Runtime.saves != null && Runtime.saves.hasKey(SAVED + path) || Runtime.files.exists(path) || Runtime.images.exists(path);
	}

	/** Reads a text file: one `SaveFileText` wrote, or one of the program's.

		@param fileName  The file.
		@return  Its text, or null when it doesn't exist. */
	public static function LoadFileText(fileName:String):Null<String> {
		var path = normalize(fileName);
		if (Runtime.saves != null && Runtime.saves.hasKey(SAVED + path))
			return Runtime.saves.getString(SAVED + path, "");
		var bytes = Runtime.files.get(path);
		return bytes == null ? null : bytes.toString();
	}

	/** Frees text `LoadFileText` returned. There is nothing to free here.

		@param text  The text. */
	public static function UnloadFileText(text:Null<String>):Void {}

	/** Writes a text file, kept across runs: in a page, in the page's storage; natively, in the program's data directory. It is kept at
		the end of the frame.

		@param fileName  The file.
		@param text  Its text.
		@return  True, or false when the saves weren't read. */
	public static function SaveFileText(fileName:String, text:String):Bool {
		if (Runtime.saves == null)
			return false;
		Runtime.saves.setString(SAVED + normalize(fileName), text);
		return true;
	}

	// ---- Colors ----

	/** Returns a color with its alpha scaled.

		@param color  The color.
		@param alpha  0 (clear) to 1 (as it is).
		@return  The new color. */
	public static function Fade(color:Color, alpha:Float):Color {
		return ColorAlpha(color, alpha);
	}

	/** Returns a color with an alpha.

		@param color  The color.
		@param alpha  0 (clear) to 1 (opaque).
		@return  The new color. */
	public static function ColorAlpha(color:Color, alpha:Float):Color {
		var a = alpha < 0 ? 0. : alpha > 1 ? 1. : alpha;
		return new Color(color.r, color.g, color.b, Std.int(255 * a));
	}

	// ---- raymath ----

	/** Returns a value kept between two others.

		@param value  The value.
		@param min  The least.
		@param max  The most.
		@return  The value, at least min and at most max. */
	public static function Clamp(value:Float, min:Float, max:Float):Float {
		var r = value < min ? min : value;
		return r > max ? max : r;
	}

	/** Returns a value part of the way from one to another.

		@param start  The start.
		@param end  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The value. */
	public static function Lerp(start:Float, end:Float, amount:Float):Float {
		return start + amount * (end - start);
	}

	/** Returns a value moved from one range to another.

		@param value  The value.
		@param inputStart  The first range's start.
		@param inputEnd  Its end.
		@param outputStart  The second range's start.
		@param outputEnd  Its end.
		@return  The value in the second range. */
	public static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float {
		return (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart;
	}

	/** Returns (0, 0).

		@return  The vector. */
	public static function Vector2Zero():Vector2 {
		return new Vector2(0, 0);
	}

	/** Returns (1, 1).

		@return  The vector. */
	public static function Vector2One():Vector2 {
		return new Vector2(1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	public static function Vector2Add(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x + v2.x, v1.y + v2.y);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	public static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x - v2.x, v1.y - v2.y);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@return  The scaled vector. */
	public static function Vector2Scale(v:Vector2, scale:Float):Vector2 {
		return new Vector2(v.x * scale, v.y * scale);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	public static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x * v2.x, v1.y * v2.y);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	public static function Vector2Length(v:Vector2):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	public static function Vector2LengthSqr(v:Vector2):Float {
		return v.x * v.x + v.y * v.y;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	public static function Vector2Distance(v1:Vector2, v2:Vector2):Float {
		var dx = v2.x - v1.x, dy = v2.y - v1.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).

		@param v  The vector.
		@return  The direction. */
	public static function Vector2Normalize(v:Vector2):Vector2 {
		var length = Vector2Length(v);
		return length > 0 ? new Vector2(v.x / length, v.y / length) : new Vector2(0, 0);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	public static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2 {
		return new Vector2(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y));
	}

	/** Returns a vector with its length kept between two values.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@return  The vector. */
	public static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2 {
		var length = Vector2Length(v);
		if (length == 0)
			return new Vector2(0, 0);
		var clamped = Clamp(length, min, max);
		return Vector2Scale(v, clamped / length);
	}

	// ---- What the functions share ----
	static inline final SAVED = "file:";
	static var start = 0.;
	static var configFlags = 0;
	static var targetFps = 0;
	static var fps = 60.;
	static var masterVolume = 1.;
	static var seed = 0x2545f491;
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
		font = new Texture2D(Runtime.graphics.createTexture(size, size, [pixels]), size, size);
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

	static function quad(x:Float, y:Float, w:Float, h:Float, color:Color):Void {
		var b = Runtime.batch, t = b.white;
		b.vertex(t, x, y, 0, 0, color);
		b.vertex(t, x, y + h, 0, 0, color);
		b.vertex(t, x + w, y + h, 0, 0, color);
		b.vertex(t, x, y, 0, 0, color);
		b.vertex(t, x + w, y + h, 0, 0, color);
		b.vertex(t, x + w, y, 0, 0, color);
	}

	static function line(x1:Float, y1:Float, x2:Float, y2:Float, thick:Float, color:Color):Void {
		var dx = x2 - x1, dy = y2 - y1, length = Math.sqrt(dx * dx + dy * dy);
		if (length == 0)
			return;
		var nx = -dy / length * thick / 2, ny = dx / length * thick / 2;
		var b = Runtime.batch, t = b.white;
		b.vertex(t, x1 + nx, y1 + ny, 0, 0, color);
		b.vertex(t, x1 - nx, y1 - ny, 0, 0, color);
		b.vertex(t, x2 - nx, y2 - ny, 0, 0, color);
		b.vertex(t, x1 + nx, y1 + ny, 0, 0, color);
		b.vertex(t, x2 - nx, y2 - ny, 0, 0, color);
		b.vertex(t, x2 + nx, y2 + ny, 0, 0, color);
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
		var n = segments(radius), b = Runtime.batch, t = b.white;
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
			b.vertex(t, cx, cy, 0, 0, color);
			b.vertex(t, cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, 0, 0, color);
			b.vertex(t, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 0, 0, color);
		}
	}

	static function ring(cx:Float, cy:Float, radius:Float, color:Color):Void {
		var n = segments(radius);
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
			line(cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 1, color);
		}
	}
}
