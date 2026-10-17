package helix.host;

import helix.render2d.Camera2D;

/** How a game's design is fitted to the window (Godot's stretch modes and aspects). */
enum PresentationMode {
	/** The default: a unit is a logical pixel (a framebuffer pixel over the pixel ratio), and the visible area is the window. */
	None;

	/** The design scaled to the window on each axis apart, its aspect lost. */
	Stretch;

	/** Scaled alike on both axes, as large as it fits whole, centered; the framebuffer around it is bars, nothing drawn in them. */
	Fit;

	/** Scaled alike, as small as covers the window, centered; what's past the window's edges is cropped. */
	Fill;

	/** Scaled as Fit is, but the visible area grows past the design to the window's edges, centered on it: the design is the least the game
		shows, and a layout arranged into the visible area keeps to the window's edges. */
	Expand;

	/** As Fit, at a whole number of framebuffer pixels to a unit (at least 1), for pixel art; bars around it. */
	Integer;
}

/** The app's design fitted to its window, one setting for the whole program: a game is written for a design size, its units stay the
	design's at any window size, on a phone or in fullscreen, and what's visible of them (the visible area) is known each frame. The runner
	refits it to the window before every frame. A 2D camera shows it (apply), a layout is arranged into the visible area (Box.arrange), and
	the pointer comes back in units through the camera (Pointer), or through toUnitsX and toUnitsY. A 3D camera draws into the area it covers
	(areaX and the rest, Camera3D.setViewportArea) to keep out of the bars. */
@:build(helix.macro.Facade.record())
class Presentation {
	var designWidth = 0.;
	var designHeight = 0.;
	var framebufferWidth = 1;
	var framebufferHeight = 1;
	var pixelRatio = 1.;

	/** None, fitted to a 1 x 1 framebuffer until the runner's first refit. */
	public function new() {}

	/** Fits the design, width x height units, to the window by mode, from the next frame (None takes no size: give 0, 0). False, changing
		nothing, for a size under 1 but for None. */
	public function set(mode:PresentationMode, width:Float, height:Float):Bool {
		if (mode != None && !(width >= 1 && height >= 1))
			return false;
		this.mode = mode;
		designWidth = mode == None ? 0 : width;
		designHeight = mode == None ? 0 : height;
		refit(framebufferWidth, framebufferHeight, pixelRatio);
		return true;
	}

	/** How the design is fitted. */
	public var mode(default, null):PresentationMode = None;

	/** The design's width in units: the window's logical width under None. */
	public var width(get, never):Float;

	function get_width():Float
		return mode == None ? visibleWidth : designWidth;

	/** The design's height in units: the window's logical height under None. */
	public var height(get, never):Float;

	function get_height():Float
		return mode == None ? visibleHeight : designHeight;

	/** Framebuffer pixels to a unit, across (under Stretch, each axis has its own). */
	public var scaleX(default, null):Float = 1.;

	/** Framebuffer pixels to a unit, down. */
	public var scaleY(default, null):Float = 1.;

	/** The visible area's left edge in units: 0 under None, Stretch, Fit and Integer; more under Fill, which crops; less under Expand, which
		grows. A HUD anchored to an edge places itself from the visible area. */
	public var visibleX(default, null):Float = 0.;

	/** The visible area's top edge in units. */
	public var visibleY(default, null):Float = 0.;

	/** The visible area's width in units. */
	public var visibleWidth(default, null):Float = 1.;

	/** The visible area's height in units. */
	public var visibleHeight(default, null):Float = 1.;

	/** Whether the visible area is taller than wide: a phone held upright, for a game with a layout for each. */
	public var portrait(get, never):Bool;

	function get_portrait():Bool
		return visibleHeight > visibleWidth;

	/** The visible area's left edge in framebuffer pixels: past 0 where Fit and Integer have bars. */
	public var areaX(default, null):Int = 0;

	/** The visible area's top edge in framebuffer pixels, from the framebuffer's top. */
	public var areaY(default, null):Int = 0;

	/** The visible area's width in framebuffer pixels. */
	public var areaWidth(default, null):Int = 1;

	/** The visible area's height in framebuffer pixels. */
	public var areaHeight(default, null):Int = 1;

	/** The unit across at framebuffer pixel x (input's pointer and touches are framebuffer pixels). */
	public function toUnitsX(x:Float):Float
		return visibleX + (x - areaX) / scaleX;

	/** The unit down at framebuffer pixel y. */
	public function toUnitsY(y:Float):Float
		return visibleY + (y - areaY) / scaleY;

	/** Sets camera to show the visible area on the framebuffer pixels it covers: its viewport the area, a unit its zoom. */
	public function apply(camera:Camera2D):Void {
		camera.setViewport(framebufferWidth, framebufferHeight);
		camera.setViewportArea(areaX, areaY, areaWidth, areaHeight);
		camera.zoom = scaleX;
		camera.zoomY = scaleY;
		camera.setPosition(visibleX + visibleWidth / 2, visibleY + visibleHeight / 2);
	}

	/** Fits the design to a framebuffer of width x height pixels at ratio framebuffer pixels to a logical one (the runner's, each frame). */
	@:allow(helix.host.Runner)
	function refit(width:Int, height:Int, ratio:Float):Void {
		framebufferWidth = width < 1 ? 1 : width;
		framebufferHeight = height < 1 ? 1 : height;
		pixelRatio = ratio > 0 ? ratio : 1;
		var fw:Float = framebufferWidth, fh:Float = framebufferHeight;
		if (mode == None) {
			scaleX = scaleY = pixelRatio;
			visibleX = visibleY = 0;
			visibleWidth = fw / pixelRatio;
			visibleHeight = fh / pixelRatio;
			areaX = areaY = 0;
			areaWidth = framebufferWidth;
			areaHeight = framebufferHeight;
			return;
		}
		var w = designWidth, h = designHeight;
		var across = fw / w, down = fh / h;
		switch mode {
			case Stretch:
				scaleX = across;
				scaleY = down;
			case Fill:
				scaleX = scaleY = Math.max(across, down);
			case Integer:
				scaleX = scaleY = Math.max(1, Math.ffloor(Math.min(across, down)));
			default:
				scaleX = scaleY = Math.min(across, down);
		}
		if (mode == Expand) {
			// All the framebuffer, the design centered in it.
			visibleWidth = fw / scaleX;
			visibleHeight = fh / scaleY;
			visibleX = (w - visibleWidth) / 2;
			visibleY = (h - visibleHeight) / 2;
			areaX = areaY = 0;
			areaWidth = framebufferWidth;
			areaHeight = framebufferHeight;
			return;
		}
		// The design centered on the framebuffer, whole pixels at its edges; what's visible of it is where the two meet (Fill crops, Integer
		// at 1 crops a window smaller than the design, Fit and Integer leave bars).
		var left = Math.round((fw - w * scaleX) / 2),
			top = Math.round((fh - h * scaleY) / 2);
		var right = left + Math.round(w * scaleX),
			bottom = top + Math.round(h * scaleY);
		areaX = left < 0 ? 0 : left;
		areaY = top < 0 ? 0 : top;
		areaWidth = (right > framebufferWidth ? framebufferWidth : right) - areaX;
		areaHeight = (bottom > framebufferHeight ? framebufferHeight : bottom) - areaY;
		visibleX = (areaX - left) / scaleX;
		visibleY = (areaY - top) / scaleY;
		visibleWidth = areaWidth / scaleX;
		visibleHeight = areaHeight / scaleY;
	}
}
