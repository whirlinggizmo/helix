package helix.raylib.extras.tweens;

import helix.raylib.Color;

/** Represents a `Color` fading from one color to another, each of its four channels on its own. It is helix-tweens' `ColorTween`
	taking and giving raylib's `Color`, so it has that type's members too, and is placed in a sequence or added to a set as one.

	```haxe
	var flash = new ColorTween(WHITE, RED, 0.2, Ease.outQuad);
	// each frame
	flash.update(GetFrameTime());
	DrawCircle(200, 200, 40, flash.value);
	``` */
@:forward
abstract ColorTween(helix.tweens.ColorTween) to helix.tweens.ColorTween to helix.tweens.EasedTween to helix.tweens.Tween {
	/** Gets or sets the color at the start. */
	public var from(get, set):Color;

	/** Gets or sets the color at the end. */
	public var to(get, set):Color;

	/** Gets the color now, its channels rounded and kept to 0 to 255 where the easing curve overshoots. */
	public var value(get, never):Color;

	/** Creates a tween of a color, at its start.

		@param from  The color at the start.
		@param to  The color at the end.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted. */
	public inline function new(from:Color, to:Color, duration:Float, ?ease:Ease)
		this = new helix.tweens.ColorTween(cast from, cast to, duration, ease);

	inline function get_from():Color
		return cast this.from;

	inline function set_from(color:Color):Color {
		this.from = cast color;
		return color;
	}

	inline function get_to():Color
		return cast this.to;

	inline function set_to(color:Color):Color {
		this.to = cast color;
		return color;
	}

	inline function get_value():Color
		return cast this.value;
}
