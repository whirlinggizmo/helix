package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.internal.Frame.FrameFit;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.ScreenText;
import helix.services.screen.ScreenFit;
#end

/** Provides the screen's design size, fitted to the window, that raylib 5.5 has no call for.

	`helix.raylib.extras.Screen` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RScreen {
	#if !macro
	/** Sets the screen's design size and how it fits the window, until `ClearScreenFit`. A size under 1, or a stretch or fit that isn't
		one of the constants, `SCREEN_FIT_NONE` included, is refused with a warning, changing nothing.

		@param designWidth  The design's width, in its pixels.
		@param designHeight  The design's height, in its pixels.
		@param stretch  How it is drawn (`SCREEN_STRETCH_*`).
		@param fit  How it fits (`SCREEN_FIT_*`).
		@param integerScale  Whether the design is shown at a whole multiple of its size: the largest at which it fits, or under
			`SCREEN_FIT_COVER` the smallest at which it covers. Under `SCREEN_STRETCH_VIEWPORT` every design pixel is then a square block,
			all alike. A window smaller than the design shows it smaller, not at a whole multiple. Under `SCREEN_STRETCH_CANVAS` the coordinates are scaled by a whole number, and drawing is still at
			the window's resolution. A fit showing more than the design shows more by whole design pixels, and what is left is bars.
			`SCREEN_FIT_STRETCH` ignores it. Godot's `integer` scale mode. */
	static function SetScreenFit(designWidth:Int, designHeight:Int, stretch:Int, fit:Int, integerScale:Bool):Void {
		if (designWidth < 1 || designHeight < 1) {
			Runtime.log(LOG_WARNING, 'SCREEN: SetScreenFit refused a design of $designWidth x $designHeight: each side must be 1 or more');
			return;
		}
		if (stretch != SCREEN_STRETCH_CANVAS && stretch != SCREEN_STRETCH_VIEWPORT) {
			Runtime.log(LOG_WARNING, 'SCREEN: SetScreenFit refused stretch $stretch: use a SCREEN_STRETCH_* constant');
			return;
		}
		if (fit < SCREEN_FIT_KEEP || fit > SCREEN_FIT_STRETCH) {
			Runtime.log(LOG_WARNING, 'SCREEN: SetScreenFit refused fit $fit: use a SCREEN_FIT_* constant other than SCREEN_FIT_NONE, or ClearScreenFit');
			return;
		}
		Runtime.screen.setDesignSize(designWidth, designHeight, cast(fit - SCREEN_FIT_KEEP), integerScale);
		screenStretch = stretch;
		FrameFit.atDesignSize = stretch == SCREEN_STRETCH_VIEWPORT;
		FrameFit.use(Runtime.frame);
		ScreenText.link();
	}

	// The stretch SetScreenFit last set, SCREEN_STRETCH_CANVAS without a fit.
	static var screenStretch = 0;

	/** Clears the design size: the screen is the window again, in its own pixels. */
	static function ClearScreenFit():Void {
		var screen = Runtime.screen;
		if (screen.designWidth == 0)
			return;
		screen.setDesignSize(0, 0, Keep);
		screenStretch = SCREEN_STRETCH_CANVAS;
		FrameFit.release();
	}

	/** Sets the color of the bars where the window shows nothing of the screen, under every fit from the next frame. Black until set.
		Its alpha shows what is behind the window only in a transparent window (`FLAG_WINDOW_TRANSPARENT`): `BLANK` there shows the page
		or the desktop through the bars. Elsewhere the bars are opaque.

		@param color  The color. */
	static function SetScreenFitBarColor(color:Color):Void {
		FrameFit.barColor = (color.a << 24) | (color.r << 16) | (color.g << 8) | color.b;
	}

	/** Returns the color of the bars (`SetScreenFitBarColor`).

		@return  The color: `BLACK` until set. */
	static function GetScreenFitBarColor():Color {
		var c = FrameFit.barColor;
		return new Color((c >> 16) & 255, (c >> 8) & 255, c & 255, (c >>> 24) & 255);
	}

	/** Returns how the screen fits the window.

		@return  A `SCREEN_FIT_*`: `SCREEN_FIT_NONE` without a fit. */
	static function GetScreenFit():Int {
		var screen = Runtime.screen;
		return screen.designWidth == 0 ? SCREEN_FIT_NONE : SCREEN_FIT_KEEP + (cast screen.fit : Int);
	}

	/** Returns how the design is drawn.

		@return  A `SCREEN_STRETCH_*`: `SCREEN_STRETCH_CANVAS` without a fit. */
	static function GetScreenStretch():Int {
		return Runtime.screen.designWidth == 0 ? SCREEN_STRETCH_CANVAS : screenStretch;
	}

	/** Returns whether the design is shown at a whole multiple of its size (`SetScreenFit`'s `integerScale`): false without a fit.

		@return  True at a whole multiple. */
	static function IsScreenFitIntegerScale():Bool {
		var screen = Runtime.screen;
		return screen.designWidth > 0 && screen.integerScale;
	}

	/** Returns how many framebuffer pixels show one design pixel, across and down: alike but under `SCREEN_FIT_STRETCH`, and a whole
		number under integer scale. Without a fit, the window's DPI scale.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The scale. */
	static function GetScreenFitScale(?out:Vector2):Vector2 {
		var screen = Runtime.screen;
		return out == null ? new Vector2(screen.scaleX, screen.scaleY) : out.set(screen.scaleX, screen.scaleY);
	}

	/** Returns what the window shows, in the design's pixels: the design itself under `SCREEN_FIT_KEEP` and `SCREEN_FIT_STRETCH`, more
		around it under `SCREEN_FIT_KEEP_WIDTH`, `SCREEN_FIT_KEEP_HEIGHT` and `SCREEN_FIT_EXPAND` (its `x` or `y` negative), less under
		`SCREEN_FIT_COVER`. A HUD anchored to the window's edges lays out in it. Without a fit, the whole screen.

		@param out  Optional. The rectangle to fill; a new one when omitted.
		@return  The visible area. */
	static function GetScreenVisibleArea(?out:Rectangle):Rectangle {
		var s = Runtime.screen;
		if (out == null)
			return new Rectangle(s.visibleX, s.visibleY, s.visibleWidth, s.visibleHeight);
		out.x = s.visibleX;
		out.y = s.visibleY;
		out.width = s.visibleWidth;
		out.height = s.visibleHeight;
		return out;
	}

	/** Returns where the visible area is shown in the window, in framebuffer pixels as `GetRenderWidth` measures them: the window less
		its bars. Without a fit, the whole window.

		@param out  Optional. The rectangle to fill; a new one when omitted.
		@return  The rectangle. */
	static function GetScreenFitRectangle(?out:Rectangle):Rectangle {
		var s = Runtime.screen;
		if (out == null)
			return new Rectangle(s.viewportX, s.viewportY, s.viewportWidth, s.viewportHeight);
		out.x = s.viewportX;
		out.y = s.viewportY;
		out.width = s.viewportWidth;
		out.height = s.viewportHeight;
		return out;
	}

	/** Returns the vertical field of view that keeps a 3D view framed under the fit: from the `fovy` a camera was framed with at the
		design's shape, the `fovy` showing the same at the visible area's shape now. It is wider where the visible area is taller than the
		design, under `SCREEN_FIT_KEEP_WIDTH` and `SCREEN_FIT_EXPAND`, narrower where `SCREEN_FIT_COVER` cuts the design's top and bottom
		off, and `fovy` itself otherwise and without a fit.

		```haxe
		camera.fovy = GetScreenFitFovy(36);
		```

		@param fovy  The vertical field of view at the design's shape, in degrees.
		@return  The vertical field of view at the visible area's shape now, in degrees. */
	static function GetScreenFitFovy(fovy:Float):Float {
		var screen = Runtime.screen;
		if (screen.designHeight == 0 || screen.visibleHeight == screen.designHeight)
			return fovy;
		return 2 * Math.atan(Math.tan(fovy * DEG2RAD / 2) * screen.visibleHeight / screen.designHeight) * RAD2DEG;
	}
	#end
}
