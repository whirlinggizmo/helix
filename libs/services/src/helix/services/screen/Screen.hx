package helix.services.screen;

import haxe.Json;
import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.IWindow;
import helix.services.saves.Saves;

/** Provides the window as a game draws to it: a design size fitted to the window, fullscreen asked for with the windowed size and
	place to go back to, whether the window was resized, and the window kept as it was between runs.

	The program constructs one over its `IWindow` and `IEvents`, and calls `poll` once a frame. With no design size, the design is the
	window's own logical size. With one, the design is centred in the window, and a game draws the visible area (`visibleX` to
	`visibleHeight`, design pixels) into the viewport (`viewportX` to `viewportHeight`, framebuffer pixels, for
	`IGraphics.applyViewport`). The visible area is the design itself, or more around it where the fit grows it (`visibleX` and
	`visibleY` negative), or less where `Cover` cuts its edges off. The game turns the mouse's or a finger's framebuffer position into
	design pixels with `toDesignX` and `toDesignY`. A HUD lays out inside the safe area (`safeAreaX` to `safeAreaHeight`, design pixels),
	clear of a phone's notch and bars. The sizes, scales and viewport follow the window's framebuffer as it is when read, so a page's canvas resized
	between frames is seen before the next poll.

	```haxe
	var screen = new Screen(window, events, {designWidth: 320, designHeight: 180, fit: Keep, integerScale: true});
	// each frame:
	screen.poll();
	var x = screen.toDesignX(mouse.x), y = screen.toDesignY(mouse.y);
	if (keyboard.isKeyPressed(F11)) screen.requestFullscreen(!screen.fullscreen);
	``` */
class Screen implements IPollable {
	final window:IWindow;
	final events:IEvents;
	// The window's size and place when last windowed, to go back to; and whether it was fullscreen at the last poll.
	var windowedWidth:Int;
	var windowedHeight:Int;
	var windowedX:Int;
	var windowedY:Int;
	var wasFullscreen:Bool;
	// The requests for the windowed size and place, asked for on leaving fullscreen, that haven't answered yet: what the window has
	// counts again once they have, whatever the window manager reported.
	var restoring = 0;
	// What keeps the window in the saves, set by `remember` and null until then, so a program that never remembers never links the saves;
	// and which call of `remember` is current.
	var keeping:Null<Bool->Void> = null;
	var remembering = 0;
	// The framebuffer size and pixel ratio the fit was last worked out for.
	var laidWidth = -1;
	var laidHeight = -1;
	var laidRatio = 0.0;

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
		integerScale = o.integerScale;
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

	/** Gets whether the design is scaled by a whole number (`ScreenOptions.integerScale`). */
	public var integerScale(default, null):Bool;

	/** Sets the design size and how it fits the window; 0 by 0 for none.

		@param width  The design's width, in design pixels.
		@param height  The design's height.
		@param fit  How it fits.
		@param integerScale  Optional. Whether the design is scaled by a whole number, every design pixel a square block, all alike: the
			largest that fits, or under `Cover` the smallest that covers. A window smaller than the design shows it smaller, not at a whole
			multiple. A fit growing the design grows it by whole design pixels, alike on both sides, and what is left is bars. `Stretch`
			ignores it. Defaults to false. */
	public function setDesignSize(width:Int, height:Int, fit:ScreenFit, integerScale = false):Void {
		designWidth = width > 0 ? width : 0;
		designHeight = height > 0 ? height : 0;
		this.fit = fit;
		this.integerScale = integerScale;
		layout();
	}

	/** Gets the left edge of the visible area, in design pixels: 0 with no design and under `Keep` and `Stretch`, negative where the fit
		grows the design across, positive where `Cover` cuts its left edge off. */
	@:isVar public var visibleX(get, null):Float = 0;

	function get_visibleX():Float {
		follow();
		return visibleX;
	}

	/** Gets the top edge of the visible area, in design pixels: negative where the fit grows the design down and up, positive where
		`Cover` cuts its top edge off. */
	@:isVar public var visibleY(get, null):Float = 0;

	function get_visibleY():Float {
		follow();
		return visibleY;
	}

	/** Gets the visible area's width, in design pixels: the design's, wider where the fit grows it across, narrower where `Cover` cuts
		it, or the window's logical width with no design. */
	@:isVar public var visibleWidth(get, null):Float = 0;

	function get_visibleWidth():Float {
		follow();
		return visibleWidth;
	}

	/** Gets the visible area's height, in design pixels: the design's, taller where the fit grows it, shorter where `Cover` cuts it, or
		the window's logical height with no design. */
	@:isVar public var visibleHeight(get, null):Float = 0;

	function get_visibleHeight():Float {
		follow();
		return visibleHeight;
	}

	/** Gets the framebuffer pixels a design pixel spans across. */
	@:isVar public var scaleX(get, null):Float = 1;

	function get_scaleX():Float {
		follow();
		return scaleX;
	}

	/** Gets the framebuffer pixels a design pixel spans down; `scaleX` unless the fit is `Stretch`. */
	@:isVar public var scaleY(get, null):Float = 1;

	function get_scaleY():Float {
		follow();
		return scaleY;
	}

	/** Gets the left edge of the viewport, where the visible area is shown, in framebuffer pixels. */
	@:isVar public var viewportX(get, null):Int = 0;

	function get_viewportX():Int {
		follow();
		return viewportX;
	}

	/** Gets the top edge of the viewport, in framebuffer pixels from the top. */
	@:isVar public var viewportY(get, null):Int = 0;

	function get_viewportY():Int {
		follow();
		return viewportY;
	}

	/** Gets the viewport's width, in framebuffer pixels. */
	@:isVar public var viewportWidth(get, null):Int = 0;

	function get_viewportWidth():Int {
		follow();
		return viewportWidth;
	}

	/** Gets the viewport's height, in framebuffer pixels. */
	@:isVar public var viewportHeight(get, null):Int = 0;

	function get_viewportHeight():Int {
		follow();
		return viewportHeight;
	}

	/** Gets the left edge of the safe area, in design pixels: where a HUD's left edge goes.

		The safe area is the part of the window that no notch, rounded corner or system bar covers (`IWindow.safeAreaX`), here the part of
		it inside the visible area. On a desktop it is the whole visible area. */
	public var safeAreaX(get, never):Float;

	function get_safeAreaX():Float
		return clampX(toDesignX(window.safeAreaX * window.pixelRatio));

	/** Gets the top edge of the safe area, in design pixels. `safeAreaX` says what the safe area is. */
	public var safeAreaY(get, never):Float;

	function get_safeAreaY():Float
		return clampY(toDesignY(window.safeAreaY * window.pixelRatio));

	/** Gets the safe area's width, in design pixels. `safeAreaX` says what the safe area is. */
	public var safeAreaWidth(get, never):Float;

	function get_safeAreaWidth():Float
		return clampX(toDesignX((window.safeAreaX + window.safeAreaWidth) * window.pixelRatio)) - safeAreaX;

	/** Gets the safe area's height, in design pixels. `safeAreaX` says what the safe area is. */
	public var safeAreaHeight(get, never):Float;

	function get_safeAreaHeight():Float
		return clampY(toDesignY((window.safeAreaY + window.safeAreaHeight) * window.pixelRatio)) - safeAreaY;

	// A design position held to the visible area.
	function clampX(x:Float):Float
		return x < visibleX ? visibleX : x > visibleX + visibleWidth ? visibleX + visibleWidth : x;

	function clampY(y:Float):Float
		return y < visibleY ? visibleY : y > visibleY + visibleHeight ? visibleY + visibleHeight : y;

	/** Returns where a framebuffer position across is in design pixels, as the mouse's or a finger's.

		@param x  The position, in framebuffer pixels from the left.
		@return  The position in design pixels; outside the visible area on a bar. */
	public function toDesignX(x:Float):Float
		return visibleX + (x - viewportX) / scaleX;

	/** Returns where a framebuffer position down is in design pixels.

		@param y  The position, in framebuffer pixels from the top.
		@return  The position in design pixels; outside the visible area on a bar. */
	public function toDesignY(y:Float):Float
		return visibleY + (y - viewportY) / scaleY;

	/** Returns where a design position across is on the framebuffer.

		@param x  The position, in design pixels.
		@return  The position, in framebuffer pixels from the left. */
	public function toScreenX(x:Float):Float
		return viewportX + (x - visibleX) * scaleX;

	/** Returns where a design position down is on the framebuffer.

		@param y  The position, in design pixels.
		@return  The position, in framebuffer pixels from the top. */
	public function toScreenY(y:Float):Float
		return viewportY + (y - visibleY) * scaleY;

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
		var mine = ++remembering, kept = "";
		keeping = full -> {
			if (!saves.loaded)
				return;
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
		saves.load(() -> {
			if (mine != remembering || !saves.hasKey(key))
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
			restore(answered -> window.requestSize(windowedWidth, windowedHeight, answered, _ -> answered()));
			if (window.canMove())
				restore(answered -> window.requestPosition(windowedX, windowedY, answered, _ -> answered()));
		} else if (!full && restoring == 0) {
			windowedWidth = window.width;
			windowedHeight = window.height;
			windowedX = window.x;
			windowedY = window.y;
		}
		wasFullscreen = full;
		layout();
		if (keeping != null)
			keeping(full);
	}

	// Asks for part of the windowed size and place back, counted until it answers, granted or not.
	function restore(ask:(answered:Void->Void)->Bool):Void {
		restoring++;
		if (!ask(() -> restoring--))
			restoring--;
	}

	// The fit worked out again when the window's framebuffer or pixel ratio changed since it last was: a page's canvas is resized
	// between frames, before the poll.
	function follow():Void {
		if (window.framebufferWidth != laidWidth || window.framebufferHeight != laidHeight || window.pixelRatio != laidRatio)
			layout();
	}

	// Where the design goes in the framebuffer, as the fit says: its scale, the visible area around it, centred, and the viewport showing
	// that area.
	function layout():Void {
		var fw = window.framebufferWidth, fh = window.framebufferHeight;
		laidWidth = fw;
		laidHeight = fh;
		laidRatio = window.pixelRatio;
		if (designWidth == 0 || designHeight == 0) {
			scaleX = scaleY = window.pixelRatio;
			visibleX = visibleY = 0;
			visibleWidth = fw / scaleX;
			visibleHeight = fh / scaleY;
			viewportX = viewportY = 0;
			viewportWidth = fw;
			viewportHeight = fh;
			return;
		}
		if (fit == Stretch) {
			scaleX = fw / designWidth;
			scaleY = fh / designHeight;
			visibleX = visibleY = 0;
			visibleWidth = designWidth;
			visibleHeight = designHeight;
			viewportX = viewportY = 0;
			viewportWidth = fw;
			viewportHeight = fh;
			return;
		}
		var across = fw / designWidth, down = fh / designHeight;
		var scale = fit == Cover ? Math.max(across, down) : Math.min(across, down);
		// A whole scale from 1 up; a window smaller than the design shows it smaller.
		if (integerScale && scale >= 1)
			scale = fit == Cover ? Math.fceil(scale) : Math.ffloor(scale);
		scaleX = scaleY = scale;
		visibleWidth = span(designWidth, fw / scale, fit == KeepHeight || fit == Expand);
		visibleHeight = span(designHeight, fh / scale, fit == KeepWidth || fit == Expand);
		visibleX = (designWidth - visibleWidth) / 2;
		visibleY = (designHeight - visibleHeight) / 2;
		viewportWidth = Std.int(Math.min(fw, Math.round(visibleWidth * scale)));
		viewportHeight = Std.int(Math.min(fh, Math.round(visibleHeight * scale)));
		viewportX = Std.int((fw - viewportWidth) / 2);
		viewportY = Std.int((fh - viewportHeight) / 2);
	}

	// The visible area's extent on one axis, in design pixels, from the window's (room): the design's, grown to the window's where the fit grows it (by whole
	// design pixels, alike on both sides, at a whole scale), and cut to the window's where the window shows less.
	function span(design:Int, room:Float, grows:Bool):Float {
		if (grows && room > design)
			return integerScale ? design + 2 * Math.ffloor((room - design) / 2) : room;
		return Math.min(design, room);
	}
}
