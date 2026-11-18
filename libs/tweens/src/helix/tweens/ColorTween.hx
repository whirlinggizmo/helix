package helix.tweens;

import helix.math.Ease;

/** Represents a color fading from one color to another, each of its four channels on its own.

	The colors are integers of four bytes in any one order (0xAARRGGBB as helix-math's `Color` holds them, or another), the same order
	for all three.

	```haxe
	var flash = new ColorTween(0xffffffff, 0xffff0000, 0.2, Ease.outQuad);
	// each frame
	flash.update(dt);
	sprite.tint = flash.value;
	``` */
class ColorTween extends EasedTween {
	/** Gets or sets the color at the start. */
	public var from:Int;

	/** Gets or sets the color at the end. */
	public var to:Int;

	/** Gets the color now, its channels rounded and kept to 0 to 255 where the easing curve overshoots. */
	public var value(get, never):Int;

	/** Creates a tween of a color, at its start.

		@param from  The color at the start.
		@param to  The color at the end.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted. */
	public function new(from:Int, to:Int, duration:Float, ?ease:Ease) {
		super(duration, ease);
		this.from = from;
		this.to = to;
	}

	function get_value():Int
		return channel(0) | channel(8) | channel(16) | channel(24);

	// The byte at a shift, moved from the start's to the end's, back at its shift.
	inline function channel(shift:Int):Int {
		var start = (from >>> shift) & 255;
		var mixed = start + (((to >>> shift) & 255) - start) * amount;
		return (mixed <= 0 ? 0 : mixed >= 255 ? 255 : Std.int(mixed + .5)) << shift;
	}
}
