package helix.render2d;

/** A sprite: a texture (or a region of it) drawn as a rectangle, its region's size in texels unless sized, its pivot at its position (its
	center by default), tinted (0xRRGGBBAA). Its scale scales it and its rotation turns it, about its pivot; a nine-slice frame keeps its
	corners' size as it's sized (setNineSlice). */
@:allow(helix.render2d.Stage2D)
class Sprite2D extends Node2D {
	var sliceLeft = 0.;
	var sliceTop = 0.;
	var sliceRight = 0.;
	var sliceBottom = 0.;
	var sourceX = 0.;
	var sourceY = 0.;
	var sourceWidth = 0.;
	var sourceHeight = 0.;
	var givenWidth = 0.;
	var givenHeight = 0.;

	/** A sprite of texture (null for none yet: it draws nothing), the whole texture at its size in texels, turning about its center, tinted
		(0xRRGGBBAA, white for none). */
	public function new(texture:Null<Texture2D>, tint = 0xffffffff) {
		super();
		this.texture = texture;
		this.tint = tint;
	}

	/** Its texture, or null: it draws nothing. */
	public var texture:Null<Texture2D>;

	/** What its texels are multiplied by, 0xRRGGBBAA: white leaves them as they are. */
	public var tint:Int = 0xffffffff;

	/** Its region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture. */
	public function setRegion(x:Float, y:Float, width:Float, height:Float):Void {
		sourceX = x;
		sourceY = y;
		sourceWidth = width;
		sourceHeight = height;
	}

	/** Its region's left, in texels. */
	public var regionX(get, never):Float;

	function get_regionX():Float
		return sourceX;

	/** Its region's top, in texels. */
	public var regionY(get, never):Float;

	function get_regionY():Float
		return sourceY;

	/** Its region's width in texels: what was set, or else its texture's (0 without one). */
	public var regionWidth(get, never):Float;

	function get_regionWidth():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceWidth : texture == null ? 0 : texture.width;

	/** Its region's height in texels: what was set, or else its texture's (0 without one). */
	public var regionHeight(get, never):Float;

	function get_regionHeight():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceHeight : texture == null ? 0 : texture.height;

	// Its region's left and top as drawn: 0, 0 for the whole texture.
	function drawnRegionX():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceX : 0.;

	function drawnRegionY():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceY : 0.;

	/** The width it draws at, in its own units: as sized, else its region's in texels. */
	public var width(get, never):Float;

	function get_width():Float
		return givenWidth > 0 && givenHeight > 0 ? givenWidth : regionWidth;

	/** The height it draws at, in its own units: as sized, else its region's in texels. */
	public var height(get, never):Float;

	function get_height():Float
		return givenWidth > 0 && givenHeight > 0 ? givenHeight : regionHeight;

	/** Sizes it, in its own units; a width or height of 0 or less goes back to its region's size. */
	public function setSize(width:Float, height:Float):Void {
		givenWidth = width;
		givenHeight = height;
	}

	/** Sets the point at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its bottom-right
		(0.5, 0.5, its center, by default). */
	public function setPivot(x:Float, y:Float):Void {
		pivotX = x;
		pivotY = y;
	}

	/** Its pivot's x fraction. */
	public var pivotX(default, null):Float = .5;

	/** Its pivot's y fraction. */
	public var pivotY(default, null):Float = .5;

	/** Draws it as a nine-slice frame (Batch2D.nineSlice): its region's corners left, top, right and bottom texels in from its edges keep their
		size as it's sized, its edges and middle stretch. All 0 (the start) draws it stretched whole. False, changing nothing, for an inset
		below 0. */
	public function setNineSlice(left:Float, top:Float, right:Float, bottom:Float):Bool {
		if (!(left >= 0 && top >= 0 && right >= 0 && bottom >= 0))
			return false;
		sliceLeft = left;
		sliceTop = top;
		sliceRight = right;
		sliceBottom = bottom;
		return true;
	}

	/** Its nine-slice's left inset, texels. */
	public var nineSliceLeft(get, never):Float;

	function get_nineSliceLeft():Float
		return sliceLeft;

	/** Its nine-slice's top inset, texels. */
	public var nineSliceTop(get, never):Float;

	function get_nineSliceTop():Float
		return sliceTop;

	/** Its nine-slice's right inset, texels. */
	public var nineSliceRight(get, never):Float;

	function get_nineSliceRight():Float
		return sliceRight;

	/** Its nine-slice's bottom inset, texels. */
	public var nineSliceBottom(get, never):Float;

	function get_nineSliceBottom():Float
		return sliceBottom;

	/** Whether it draws as a nine-slice frame. */
	public var nineSlice(get, never):Bool;

	function get_nineSlice():Bool
		return sliceLeft > 0 || sliceTop > 0 || sliceRight > 0 || sliceBottom > 0;
}
