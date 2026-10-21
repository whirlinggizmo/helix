package helix.render2d;

/** A 2D view: the world point at the viewport's center and how many pixels a world unit covers (across and down alike, but under a
	Presentation that stretches). Y grows downward. The viewport is the whole framebuffer, or an area of it (setViewportArea). A camera
	never sized (setViewport) is the whole framebuffer as it is at each use: a Batch2D beginning with it, fit and pixels size it to Screen's
	framebuffer then (the window's, refitted by the runner before each frame), so it follows a resize; one the app sized keeps its size. */
class Camera2D {
	/** A camera at world 0, 0, zoom 1, unsized: the whole framebuffer once used under a runner, a 1 x 1 viewport until then. */
	public function new() {}

	/** Whether setViewport or setViewportArea sized it. Unsized, it takes the framebuffer's size at each use (the class doc). */
	public var sized(default, null):Bool = false;

	// An unsized camera takes Screen's framebuffer, the window's as the runner last refitted it; outside a runner (a test with no Screen
	// bound) it stays as it is.

	@:allow(helix.render2d.Batch2D)
	function fitFramebuffer():Void {
		if (sized)
			return;
		var screen = helix.host.Screen.instance;
		if (screen != null)
			fill(screen.framebufferWidth, screen.framebufferHeight);
	}

	function fill(width:Int, height:Int):Void {
		framebufferWidth = viewportWidth = width < 1 ? 1 : width;
		framebufferHeight = viewportHeight = height < 1 ? 1 : height;
		viewportX = viewportY = 0;
	}

	/** The world X at the viewport's center. */
	public var x(default, null):Float = 0.;

	/** The world Y at the viewport's center. */
	public var y(default, null):Float = 0.;

	/** Puts the world point x, y at the viewport's center. */
	public function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	/** Framebuffer pixels per world unit across; assigning it sets the zoom down too (zoomY). At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var zoom(default, set):Float = 1.;

	function set_zoom(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		zoom = zoomY = value;
		return value;
	}

	/** Framebuffer pixels per world unit down: zoom's, unless assigned apart after it (a stretched view: Presentation's Stretch). At least
		1e-6 (0 or less, or NaN, is 1e-6). */
	public var zoomY(default, set):Float = 1.;

	function set_zoomY(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		zoomY = value;
		return value;
	}

	/** The framebuffer width in pixels, from setViewport. */
	public var framebufferWidth(default, null):Int = 1;

	/** The framebuffer height in pixels, from setViewport. */
	public var framebufferHeight(default, null):Int = 1;

	/** The viewport's left edge in framebuffer pixels from the framebuffer's left. */
	public var viewportX(default, null):Int = 0;

	/** The viewport's top edge in framebuffer pixels from the framebuffer's top. */
	public var viewportY(default, null):Int = 0;

	/** The viewport width in framebuffer pixels. */
	public var viewportWidth(default, null):Int = 1;

	/** The viewport height in framebuffer pixels. */
	public var viewportHeight(default, null):Int = 1;

	/** The framebuffer it draws to, width x height pixels, all of it the viewport; a size under 1 clamps to 1. From then on it's sized:
		it keeps this size rather than the framebuffer's. */
	public function setViewport(width:Int, height:Int):Void {
		fill(width, height);
		sized = true;
	}

	/** Narrows the viewport to an area of the framebuffer last given to setViewport: x, y is its top-left in framebuffer pixels from the
		framebuffer's top-left. The next setViewport takes the whole framebuffer again. False, changing nothing, for a width or height under 1 or an
		area not inside the framebuffer. */
	public function setViewportArea(x:Int, y:Int, width:Int, height:Int):Bool {
		if (width < 1 || height < 1 || x < 0 || y < 0 || x + width > framebufferWidth || y + height > framebufferHeight)
			return false;
		sized = true;
		viewportX = x;
		viewportY = y;
		viewportWidth = width;
		viewportHeight = height;
		return true;
	}

	/** Show a world rectangle whole and centered; the longer screen side shows extra world (an unsized camera takes the framebuffer first).
		False for a width or height of 0 or less. */
	public function fit(left:Float, top:Float, width:Float, height:Float):Bool {
		if (!(width > 0 && height > 0))
			return false;
		fitFramebuffer();
		zoom = zoomY = Math.min(viewportWidth / width, viewportHeight / height);
		x = left + width / 2;
		y = top + height / 2;
		return true;
	}

	/** World units are logical pixels from the viewport's top-left: scale is the pixel ratio (framebuffer pixels per logical pixel); an
		unsized camera takes the framebuffer first. False for a scale of 0 or less. */
	public function pixels(scale:Float):Bool {
		if (!(scale > 0))
			return false;
		fitFramebuffer();
		zoom = zoomY = scale;
		x = viewportWidth / 2 / scale;
		y = viewportHeight / 2 / scale;
		return true;
	}

	/** The world X under framebuffer pixel X px, from the framebuffer's left edge. */
	public function screenToWorldX(px:Float):Float
		return x + (px - viewportX - viewportWidth / 2) / zoom;

	/** The world Y under framebuffer pixel Y py, from the framebuffer's top edge. */
	public function screenToWorldY(py:Float):Float
		return y + (py - viewportY - viewportHeight / 2) / zoomY;

	/** The framebuffer pixel X, from the framebuffer's left edge, of world X wx. */
	public function worldToScreenX(wx:Float):Float
		return (wx - x) * zoom + viewportX + viewportWidth / 2;

	/** The framebuffer pixel Y, from the framebuffer's top edge, of world Y wy. */
	public function worldToScreenY(wy:Float):Float
		return (wy - y) * zoomY + viewportY + viewportHeight / 2;

	/** Clip-space X (-1 left to 1 right) of world X wx. */
	public inline function clipX(wx:Float):Float
		return (wx - x) * zoom * 2 / viewportWidth;

	/** Clip-space Y (1 top to -1 bottom) of world Y wy; the flip makes world Y grow downward. */
	public inline function clipY(wy:Float):Float
		return -(wy - y) * zoomY * 2 / viewportHeight;
}
