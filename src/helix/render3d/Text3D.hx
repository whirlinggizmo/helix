package helix.render3d;

import helix.render2d.Font2D;

/** A line of text in the world: its value, size world units tall (ascent to descent), in a font (null: the stage's built-in one), its block's
	pivot at its position (its center by default), facing the camera, in a color (0xRRGGBBAA, sRGB). Unlit and blended, as sprites are, and
	sharp at any distance (a distance-field font). Pivoted and faced as a sprite. Not pickable until pickable is set: a label lets a pick
	through to what it's on. */
class Text3D extends Node3D {
	var size:Float;

	/** value, size world units tall (a size of 0 or less is 0.5), in color, in font (null: the stage's built-in one). */
	public function new(value:String, size = .5, color = 0xffffffff, ?font:Font2D) {
		super();
		text = value;
		this.size = size > 0 ? size : .5;
		this.color = color;
		this.font = font;
		pickable = false;
	}

	/** Its text. */
	public var text:String;

	/** Its size, world units tall. At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var textSize(get, set):Float;

	function get_textSize():Float
		return size;

	function set_textSize(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		size = value;
		return value;
	}

	/** Its color, 0xRRGGBBAA (sRGB). */
	public var color:Int;

	/** Its font, or null for the stage's built-in one. */
	public var font:Null<Font2D>;

	/** Sets the point of its block at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its
		bottom-right (0.5, 0.5, its center, by default). */
	public function setPivot(x:Float, y:Float):Void {
		pivotX = x;
		pivotY = y;
	}

	/** Its pivot's x fraction. */
	public var pivotX(default, null):Float = .5;

	/** Its pivot's y fraction. */
	public var pivotY(default, null):Float = .5;

	/** How it faces. */
	public var facing:SpriteFacing = Camera;
}
