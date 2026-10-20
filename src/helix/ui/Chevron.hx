package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;

/** A chevron drawn on a widget's face, pointing up or down (a color picker's format button, a dropdown's face): two arms meeting at its
	point, sized for the face's height, never picked. One part, so every widget's chevron looks alike. Its place is in its parent's units. */
class Chevron {
	var shape:Shape2D;
	var up:Bool;
	// The height it was shaped for.
	var shaped = -1.;

	/** Makes a chevron under parent, pointing up (up) or down, shaped by setSize. */
	public function new(parent:Node2D, up:Bool) {
		this.up = up;
		shape = Shape2D.polygon([0, 0, 1, 0, 0, 1]);
		shape.pickable = false;
		parent.addChild(shape);
	}

	/** How far it reaches from its point toward its open end, in units, as last shaped: its arms' reach and their thickness. */
	public var depth(default, null):Float = 0.;

	/** Its color, 0xRRGGBBAA. */
	public var color(get, set):Int;

	function get_color():Int
		return shape.color;

	function set_color(value:Int):Int {
		shape.color = value;
		return value;
	}

	/** Whether it's drawn. */
	public var visible(get, set):Bool;

	function get_visible():Bool
		return shape.visible;

	function set_visible(value:Bool):Bool {
		shape.visible = value;
		return value;
	}

	/** Shapes it for a face height units tall: its arms reaching .18 of it out to each side and back from its point, .08 of it thick (at least
		1.5 units). Made again only when height changed. */
	public function setSize(height:Float):Void {
		if (height == shaped)
			return;
		shaped = height;
		var a = height * .18, k = Math.max(1.5, height * .08), s = up ? 1 : -1;
		shape.setPoints([-a, a * s, 0, 0, a, a * s, a, (a + k) * s, 0, k * s, -a, (a + k) * s]);
		depth = a + k;
	}

	/** Puts its point at x, y, in its parent's units. */
	public function setPosition(x:Float, y:Float):Void
		shape.setPosition(x, y);
}
