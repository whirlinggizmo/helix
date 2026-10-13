package helix.render2d;

/** A 2D view: the world point at the viewport's center and how many pixels a world unit covers. Y grows downward. */
class Camera2D {
	var x = 0.;
	var y = 0.;
	var zoom = 1.;
	var viewportWidth = 1;
	var viewportHeight = 1;

	/** A camera at world 0, 0, zoom 1, on a 1 x 1 viewport. */
	public function new() {}

	/** The world X at the viewport's center. */
	public function getX():Float
		return x;

	/** The world Y at the viewport's center. */
	public function getY():Float
		return y;

	/** Puts the world point x, y at the viewport's center. */
	public function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	/** Framebuffer pixels per world unit. */
	public function getZoom():Float
		return zoom;

	/** False for a zoom of 0 or less. */
	public function setZoom(value:Float):Bool {
		if (!(value > 0))
			return false;
		zoom = value;
		return true;
	}

	/** The viewport width in framebuffer pixels. */
	public function getViewportWidth():Int
		return viewportWidth;

	/** The viewport height in framebuffer pixels. */
	public function getViewportHeight():Int
		return viewportHeight;

	/** The framebuffer area it draws to; a size under 1 clamps to 1. */
	public function setViewport(width:Int, height:Int):Void {
		viewportWidth = width < 1 ? 1 : width;
		viewportHeight = height < 1 ? 1 : height;
	}

	/** Show a world rectangle whole and centered; the longer screen side shows extra world. False for a width or height of 0 or less. */
	public function fit(left:Float, top:Float, width:Float, height:Float):Bool {
		if (!(width > 0 && height > 0))
			return false;
		zoom = Math.min(viewportWidth / width, viewportHeight / height);
		x = left + width / 2;
		y = top + height / 2;
		return true;
	}

	/** World units are logical pixels from the viewport's top-left: scale is the pixel ratio (framebuffer pixels per logical pixel). False for a scale of 0 or less. */
	public function pixels(scale:Float):Bool {
		if (!(scale > 0))
			return false;
		zoom = scale;
		x = viewportWidth / 2 / scale;
		y = viewportHeight / 2 / scale;
		return true;
	}

	/** The world X under framebuffer pixel X px, from the viewport's left edge. */
	public function screenToWorldX(px:Float):Float
		return x + (px - viewportWidth / 2) / zoom;

	/** The world Y under framebuffer pixel Y py, from the viewport's top edge. */
	public function screenToWorldY(py:Float):Float
		return y + (py - viewportHeight / 2) / zoom;

	/** The framebuffer pixel X, from the viewport's left edge, of world X wx. */
	public function worldToScreenX(wx:Float):Float
		return (wx - x) * zoom + viewportWidth / 2;

	/** The framebuffer pixel Y, from the viewport's top edge, of world Y wy. */
	public function worldToScreenY(wy:Float):Float
		return (wy - y) * zoom + viewportHeight / 2;

	/** Clip-space X (-1 left to 1 right) of world X wx. */
	public inline function clipX(wx:Float):Float
		return (wx - x) * zoom * 2 / viewportWidth;

	/** Clip-space Y (1 top to -1 bottom) of world Y wy; the flip makes world Y grow downward. */
	public inline function clipY(wy:Float):Float
		return -(wy - y) * zoom * 2 / viewportHeight;
}
