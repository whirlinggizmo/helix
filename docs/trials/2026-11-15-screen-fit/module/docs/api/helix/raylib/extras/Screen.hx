package helix.raylib.extras;

import helix.raylib.*;

/** Provides a design size for the screen, fitted to the window: a program draws in the design's pixels whatever the window's size, as
	Godot's stretch aspect modes fit a game. Imported apart, with its constants: `import helix.raylib.extras.Screen.*;`.

	```haxe
	InitWindow(1280, 720, "fitted");
	SetScreenFit(640, 360, SCREEN_STRETCH_VIEWPORT, SCREEN_FIT_KEEP, true);
	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(BLACK);
		DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), DARKBLUE); // the whole design, 640 x 360
		EndDrawing();
	}
	```

	With a fit set, `GetScreenWidth` and `GetScreenHeight` give the design's size, as the fit grows it, and everything drawn between
	`BeginDrawing` and `EndDrawing` is drawn in the design's pixels and shown in the fitted area. The mouse and touch positions
	(`GetMousePosition`, `GetTouchPosition`) and raygui's controls read in the design's pixels. Bars where the design doesn't cover the
	window are drawn black. Without a fit, the screen is the window, in its own pixels, as in raylib.

	`TakeScreenshot` saves the window, bars and all, at its own size, whatever the fit.

	- **3D:** `BeginMode3D` projects at the screen's shape, the design as the fit grows it. Under `SCREEN_FIT_KEEP`,
	  `SCREEN_FIT_KEEP_HEIGHT` and `SCREEN_FIT_STRETCH` a camera keeps its framing as it is. Under `SCREEN_FIT_KEEP_WIDTH` and
	  `SCREEN_FIT_EXPAND` a window taller than the design shows less above and below unless the program sets
	  `camera.fovy = GetScreenFitFovy(fovy)`, each frame or when `IsWindowResized` is true.
	- **High DPI:** the design is fitted to the framebuffer, in its pixels (`GetRenderWidth`), which a high-DPI window has more of than
	  its logical size (`GetWindowScaleDPI`). The mouse and touch positions are mapped from the window's logical size through that
	  scale, so the design pixel under the pointer is the one read, on any display.
	- **Render textures:** between `BeginTextureMode` and `EndTextureMode`, drawing is in the render texture's own pixels, as in raylib,
	  untouched by the fit. The fit applies to drawing on the screen. */
class Screen {
	/** A stretch drawing in the design's coordinates at the window's resolution: lines, text and edges sharp at any size, a texture
		scaled as drawn. Godot's `canvas_items`. */
	public static inline final SCREEN_STRETCH_CANVAS:Int = 0;

	/** A stretch drawing the frame at the design's size, then showing that picture scaled up: every pixel a block, a sprite turned or
		placed between pixels kept on the design's grid, as pixel art wants. Godot's `viewport`. */
	public static inline final SCREEN_STRETCH_VIEWPORT:Int = 1;

	/** A fit keeping the design's shape, as large as it fits, bars above and below or beside it: Godot's `keep`. */
	public static inline final SCREEN_FIT_KEEP:Int = 0;

	/** A fit keeping the design's width: a window taller than the design shows more above and below, a wider one has bars beside it:
		Godot's `keep_width`. */
	public static inline final SCREEN_FIT_KEEP_WIDTH:Int = 1;

	/** A fit keeping the design's height: a window wider than the design shows more beside it, a taller one has bars above and below:
		Godot's `keep_height`. */
	public static inline final SCREEN_FIT_KEEP_HEIGHT:Int = 2;

	/** A fit with no bars: the design shown whole, and more of the world on the window's longer side: Godot's `expand`. */
	public static inline final SCREEN_FIT_EXPAND:Int = 3;

	/** A fit filling the window, the design stretched to its shape: Godot's `ignore`. */
	public static inline final SCREEN_FIT_STRETCH:Int = 4;

	/** Sets the screen's design size and how it fits the window, until `ClearScreenFit`.

		@param designWidth  The design's width, in its pixels.
		@param designHeight  The design's height, in its pixels.
		@param stretch  How it is drawn (`SCREEN_STRETCH_*`).
		@param fit  How it fits (`SCREEN_FIT_*`).
		@param integerScale  Whether the design is shown at a whole multiple of its size: the largest whole number at which the design
			fits the window. Under `SCREEN_STRETCH_VIEWPORT` every design pixel is then a square block, all alike: pixel art, sprites
			turned or scaled included. Under `SCREEN_STRETCH_CANVAS` it scales the coordinates by a whole number, and what is drawn is
			still drawn at the window's resolution, a turned sprite's edges finer than a design pixel. A fit growing the design (`SCREEN_FIT_KEEP_WIDTH`,
			`SCREEN_FIT_KEEP_HEIGHT`, `SCREEN_FIT_EXPAND`) grows it by whole design pixels at that scale, and what is left, less than one,
			is bars. A window smaller than the design shows it smaller, not at a whole multiple. `SCREEN_FIT_STRETCH` ignores it. */
	public static function SetScreenFit(designWidth:Int, designHeight:Int, stretch:Int, fit:Int, integerScale:Bool):Void {
		throw "not built yet";
	}

	/** Clears the design size: the screen is the window again, in its own pixels. */
	public static function ClearScreenFit():Void {
		throw "not built yet";
	}

	/** Returns where the design is shown in the window, in the window's pixels as `GetRenderWidth` measures them: the whole window
		without a fit.

		@param out  Optional. The rectangle filled; a new one when omitted.
		@return  out, or the new rectangle. */
	public static function GetScreenFitRectangle(?out:Rectangle):Rectangle {
		throw "not built yet";
	}

	/** Returns the vertical field of view that keeps a 3D view framed under the fit: given the `fovy` a camera was framed with at the
		design's shape, the `fovy` showing the same at the screen's shape now. Under `SCREEN_FIT_KEEP`, `SCREEN_FIT_KEEP_HEIGHT` and
		`SCREEN_FIT_STRETCH` it is `fovy` itself; under `SCREEN_FIT_KEEP_WIDTH` and `SCREEN_FIT_EXPAND` it is wider on a screen taller
		than the design. Without a fit, the design's shape is the window's when the call is first made.

		```haxe
		camera.fovy = GetScreenFitFovy(36);
		```

		@param fovy  The vertical field of view at the design's shape, in degrees.
		@return  The vertical field of view at the screen's shape now, in degrees. */
	public static function GetScreenFitFovy(fovy:Float):Float {
		throw "not built yet";
	}

	/** Returns the part of the screen no notch, rounded corner or system bar covers, in the screen's coordinates as `GetScreenWidth`
		measures them: the design's pixels under a fit. A HUD lays out inside it.

		@param out  Optional. The rectangle filled; a new one when omitted.
		@return  out, or the new rectangle. */
	public static function GetScreenSafeArea(?out:Rectangle):Rectangle {
		throw "not built yet";
	}
}
