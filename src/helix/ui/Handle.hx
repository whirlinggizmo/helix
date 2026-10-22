package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;

/** The round handle a widget drags along a track (a slider's, a color picker's bars): a disc theme.handleSize across in theme.handleColor
	over a ring of theme.handleShadowColor a little wider, so it shows on any color under it; centered on its position, never picked. One
	part, so every widget's handle looks alike. */
class Handle {
	var shadow:Shape2D;
	var disc:Shape2D;

	/** Makes a handle in theme's look under parent. */
	public function new(parent:Node2D, theme:Theme) {
		shadow = Shape2D.circle(1, 0);
		disc = Shape2D.circle(1, theme.handleColor);
		for (shape in [shadow, disc]) {
			shape.pickable = false;
			parent.addChild(shape);
		}
		readTheme(theme);
	}

	/** Takes its size and its ring's color from theme (its disc's color is its owner's to set: color). Its owner calls it as it reads the
		theme, every frame, so a changed theme shows at once. */
	public function readTheme(theme:Theme):Void {
		var radius = theme.handleSize / 2;
		disc.radius = radius;
		shadow.radius = radius + 1.5;
		shadow.color = theme.handleShadowColor;
	}

	/** The disc's color, 0xAARRGGBB: its owner's, by the handle's state (WidgetState.handle). */
	public var color(get, set):Int;

	function get_color():Int
		return disc.color;

	function set_color(value:Int):Int {
		disc.color = value;
		return value;
	}

	/** Whether it's drawn. */
	public var visible(get, set):Bool;

	function get_visible():Bool
		return disc.visible;

	function set_visible(value:Bool):Bool {
		shadow.visible = disc.visible = value;
		return value;
	}

	/** Centers it on x, y in its parent's units. */
	public function setPosition(x:Float, y:Float):Void {
		shadow.setPosition(x, y);
		disc.setPosition(x, y);
	}
}
