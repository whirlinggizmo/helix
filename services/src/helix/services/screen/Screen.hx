package helix.services.screen;

import haxe.Json;
import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.IWindow;
import helix.services.saves.Saves;

/** Provides the window as a game draws to it: a design size fitted to the window, fullscreen asked for with the windowed size and
	place to go back to, whether the window was resized, and the window kept as it was between runs.

	The program constructs one over its `IWindow` and `IEvents`, and calls `poll` once a frame. With no design size, the design is the
	window's own logical size. With one, a game draws in design pixels into the viewport (`viewportX` to `viewportHeight`, framebuffer
	pixels, for `IGraphics.applyViewport`), and turns the mouse's or a finger's framebuffer position into design pixels with `toDesignX`
	and `toDesignY`.

	```haxe
	var screen = new Screen(window, events, {designWidth: 320, designHeight: 180, fit: PixelPerfect});
	// each frame:
	screen.poll();
	var x = screen.toDesignX(mouse.x), y = screen.toDesignY(mouse.y);
	if (keyboard.isKeyPressed(F11)) screen.requestFullscreen(!screen.fullscreen);
	``` */
class Screen implements IPollable {
	static inline final RESTORE_FRAMES = 30;

	final window:IWindow;
	final events:IEvents;
	// The window's size and place when last windowed, to go back to; and whether it was fullscreen at the last poll.
	var windowedWidth:Int;
	var windowedHeight:Int;
	var windowedX:Int;
	var windowedY:Int;
	var wasFullscreen:Bool;
	// Frames left to wait for the windowed size asked for on leaving fullscreen, before what the window has counts again.
	var restoring = 0;
	// Where the window is kept between runs, and what was last kept there.
	var saves:Null<Saves> = null;
	var key = "";
	var kept = "";

	/** Creates the screen over the window, its design and fit as the options say.

		@param window  The window.
		@param events  The platform's events, whose last `poll` this one reads.
		@param options  Optional. The design size and how it fits; none by default. */
	public function new(window:IWindow, events:IEvents, ?options:ScreenOptions) {
		this.window = window;
		this.events = events;
		var o:ScreenOptions = options != null ? options : {};
		designWidth = o.designWidth;
		designHeight = o.designHeight;
		fit = o.fit;
		windowedWidth = window.width;
		windowedHeight = window.height;
		windowedX = window.x;
		windowedY = window.y;
		wasFullscreen = window.fullscreen;
		layout();
	}

	/** Gets the design's width, in design pixels; 0 for none. */
	public var designWidth(default, null):Int;

	/** Gets the design's height, in design pixels; 0 for none. */
	public var designHeight(default, null):Int;

	/** Gets how the design fits the window. */
	public var fit(default, null):ScreenFit;

	/** Sets the design size and how it fits the window; 0 by 0 for none.

		@param width  The design's width, in design pixels.
		@param height  The design's height.
		@param fit  How it fits. */
	public function setDesignSize(width:Int, height:Int, fit:ScreenFit):Void {
		designWidth = width > 0 ? width : 0;
		designHeight = height > 0 ? height : 0;
		this.fit = fit;
		layout();
	}

	/** Gets the width drawn in, in design pixels: the design's, wider under `Expand` on a wider window, or the window's logical width
		with no design. */
	public var width(default, null):Float = 0;

	/** Gets the height drawn in, in design pixels: the design's, taller under `Expand` on a taller window, or the window's logical
		height with no design. */
	public var height(default, null):Float = 0;

	/** Gets the framebuffer pixels a design pixel takes across. */
	public var scaleX(default, null):Float = 1;

	/** Gets the framebuffer pixels a design pixel takes down; `scaleX` unless the fit is `Stretch`. */
	public var scaleY(default, null):Float = 1;

	/** Gets the left edge of the area drawn in, in framebuffer pixels. */
	public var viewportX(default, null):Int = 0;

	/** Gets the top edge of the area drawn in, in framebuffer pixels from the top. */
	public var viewportY(default, null):Int = 0;

	/** Gets the width of the area drawn in, in framebuffer pixels. */
	public var viewportWidth(default, null):Int = 0;

	/** Gets the height of the area drawn in, in framebuffer pixels. */
	public var viewportHeight(default, null):Int = 0;

	/** Returns where a framebuffer position across is in design pixels, as the mouse's or a finger's.

		@param x  The position, in framebuffer pixels from the left.
		@return  The position in design pixels; outside 0 to `width` on a bar. */
	public function toDesignX(x:Float):Float
		return (x - viewportX) / scaleX;

	/** Returns where a framebuffer position down is in design pixels.

		@param y  The position, in framebuffer pixels from the top.
		@return  The position in design pixels; outside 0 to `height` on a bar. */
	public function toDesignY(y:Float):Float
		return (y - viewportY) / scaleY;

	/** Returns where a design position across is on the framebuffer.

		@param x  The position, in design pixels.
		@return  The position, in framebuffer pixels from the left. */
	public function toScreenX(x:Float):Float
		return viewportX + x * scaleX;

	/** Returns where a design position down is on the framebuffer.

		@param y  The position, in design pixels.
		@return  The position, in framebuffer pixels from the top. */
	public function toScreenY(y:Float):Float
		return viewportY + y * scaleY;

	/** Gets whether the window was resized this frame, by the player, the OS or a request. */
	public var resized(default, null):Bool = false;

	/** Gets whether the window is fullscreen now. */
	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return window.fullscreen;

	/** Asks for fullscreen or a window. Leaving fullscreen goes back to the size and place the window last had.

		The result comes later, to the lambdas, and `fullscreen` reflects it once the request completes.
		@param enabled  True for fullscreen, false for a window.
		@param done  Optional. Called once it is granted.
		@param failed  Optional. Receives the reason when it is refused.
		@return  Whether it asked: false where the window can't be fullscreen. */
	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return window.requestFullscreen(enabled, done, failed);

	/** Keeps the window's size, place and fullscreen between runs, in the saves under a key: what was kept is asked for now, and what
		changes is kept as it does. The saves need not have been read: what was kept is asked for once they are.

		@param saves  The saves.
		@param key  Optional. The key it is kept under. Defaults to "screen". */
	public function remember(saves:Saves, key = "screen"):Void {
		this.saves = saves;
		this.key = key;
		saves.load(() -> {
			if (this.saves != saves || !saves.hasKey(key))
				return;
			kept = saves.getString(key, "");
			var was:Dynamic = try Json.parse(kept) catch (_:Dynamic) null;
			if (was == null)
				return;
			windowedWidth = was.width;
			windowedHeight = was.height;
			windowedX = was.x;
			windowedY = was.y;
			window.requestSize(windowedWidth, windowedHeight);
			if (window.canMove())
				window.requestPosition(windowedX, windowedY);
			if (was.fullscreen == true && window.canFullscreen())
				window.requestFullscreen(true);
		}, _ -> {});
	}

	/** Reads the events the last `IEvents.poll` delivered: whether the window was resized; the size and place it has while windowed,
		and going back to them as it leaves fullscreen; the fit; and what `remember` keeps. Call it once a frame. */
	public function poll():Void {
		resized = false;
		for (event in events.events)
			switch event {
				case Resized(_, _):
					resized = true;
				case _:
			}
		var full = window.fullscreen;
		if (!full && wasFullscreen && (window.width != windowedWidth || window.height != windowedHeight)) {
			window.requestSize(windowedWidth, windowedHeight);
			if (window.canMove())
				window.requestPosition(windowedX, windowedY);
			restoring = RESTORE_FRAMES;
		} else if (!full && restoring > 0 && (window.width != windowedWidth || window.height != windowedHeight)) {
			// Still on its way back; a window manager that refuses is believed after RESTORE_FRAMES frames.
			restoring--;
		} else if (!full) {
			restoring = 0;
			windowedWidth = window.width;
			windowedHeight = window.height;
			windowedX = window.x;
			windowedY = window.y;
		}
		wasFullscreen = full;
		layout();
		if (saves != null && saves.loaded) {
			var now = Json.stringify({
				width: windowedWidth,
				height: windowedHeight,
				x: windowedX,
				y: windowedY,
				fullscreen: full
			});
			if (now != kept) {
				kept = now;
				saves.setString(key, now);
			}
		}
	}

	// Where the design goes in the framebuffer, as the fit says.
	function layout():Void {
		var fw = window.framebufferWidth, fh = window.framebufferHeight;
		if (designWidth == 0 || designHeight == 0) {
			scaleX = scaleY = window.pixelRatio;
			width = fw / scaleX;
			height = fh / scaleY;
			viewportX = viewportY = 0;
			viewportWidth = fw;
			viewportHeight = fh;
			return;
		}
		var fitted = Math.min(fw / designWidth, fh / designHeight);
		switch fit {
			case Stretch:
				scaleX = fw / designWidth;
				scaleY = fh / designHeight;
			case PixelPerfect:
				scaleX = scaleY = Math.max(1, Math.floor(fitted));
			case _:
				scaleX = scaleY = fitted;
		}
		if (fit == Expand) {
			width = fw / scaleX;
			height = fh / scaleY;
			viewportX = viewportY = 0;
			viewportWidth = fw;
			viewportHeight = fh;
			return;
		}
		width = designWidth;
		height = designHeight;
		viewportWidth = Math.round(designWidth * scaleX);
		viewportHeight = Math.round(designHeight * scaleY);
		viewportX = Std.int((fw - viewportWidth) / 2);
		viewportY = Std.int((fh - viewportHeight) / 2);
	}
}
