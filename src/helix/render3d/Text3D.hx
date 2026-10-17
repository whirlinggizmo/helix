package helix.render3d;

import helix.render2d.Font2D;

/** A line of text in the world: its value, size world units tall (ascent to descent), in a font (null: the stage's built-in one), its block's
	pivot at its position (its center by default), facing the camera, in a color (0xRRGGBBAA, sRGB). Unlit and blended, as sprites are, and
	sharp at any distance (a distance-field font). Pivoted and faced as a sprite. Not pickable until setPickable(true): a label lets a pick
	through to what it's on. */
class Text3D extends Node3D {
	var text:String;
	var size:Float;
	var color:Int;
	var font:Null<Font2D>;
	var pivotX = .5;
	var pivotY = .5;
	var facing:SpriteFacing = Camera;

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
	public function getText():String
		return text;

	/** Sets its text. */
	public function setText(value:String):Void
		text = value;

	/** Its size, world units tall. */
	public function getTextSize():Float
		return size;

	/** Sets its size, world units tall. False, changing nothing, for a size of 0 or less. */
	public function setTextSize(value:Float):Bool {
		if (!(value > 0))
			return false;
		size = value;
		return true;
	}

	/** Its color, 0xRRGGBBAA (sRGB). */
	public function getColor():Int
		return color;

	/** Sets its color, 0xRRGGBBAA (sRGB). */
	public function setColor(value:Int):Void
		color = value;

	/** Its font, or null for the stage's built-in one. */
	public function getFont():Null<Font2D>
		return font;

	/** Sets its font (null: the stage's built-in one). */
	public function setFont(value:Null<Font2D>):Void
		font = value;

	/** Sets the point of its block at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its
		bottom-right (0.5, 0.5, its center, by default). */
	public function setPivot(x:Float, y:Float):Void {
		pivotX = x;
		pivotY = y;
	}

	/** Its pivot's x fraction. */
	public function getPivotX():Float
		return pivotX;

	/** Its pivot's y fraction. */
	public function getPivotY():Float
		return pivotY;

	/** How it faces. */
	public function getFacing():SpriteFacing
		return facing;

	/** Sets how it faces. */
	public function setFacing(value:SpriteFacing):Void
		facing = value;
}
