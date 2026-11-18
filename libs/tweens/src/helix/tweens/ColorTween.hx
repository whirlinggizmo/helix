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

	/** Gets or sets the color at the end: the first leg's end, where `append` added more legs. */
	public var to:Int;

	/** Gets the color now, its channels rounded and kept to 0 to 255 where the easing curve overshoots. */
	public var value(get, never):Int;

	// The values the legs after the first end at, in the order added.
	var legValues:Null<Array<Int>>;

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

	function get_value():Int {
		var start = legValue(legFrom), end = legValue(legTo);
		return channel(start, end, 0) | channel(start, end, 8) | channel(start, end, 16) | channel(start, end, 24);
	}

	/** Adds a leg: the color fades on from where the tween ended before to another color.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek take every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// To red, a wait, then back to white.
		var flash = new ColorTween(0xffffffff, 0xffff0000, 0.1).appendDelay(0.2).append(0xffffffff, 0.5, Ease.outQuad);
		```

		@param to  The color at the leg's end.
		@param duration  The seconds the leg takes, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function append(to:Int, duration:Float, ?ease:Ease):ColorTween {
		addLeg(duration, ease != null ? ease : Ease.linear);
		if (legValues == null)
			legValues = [];
		legValues.push(to);
		return this;
	}

	/** Adds a wait: the color stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function appendDelay(seconds:Float):ColorTween {
		addLeg(seconds, null);
		return this;
	}

	// The byte at a shift, moved from one color's to another's, back at its shift.
	inline function channel(start:Int, end:Int, shift:Int):Int {
		var first = (start >>> shift) & 255;
		var mixed = first + (((end >>> shift) & 255) - first) * amount;
		return (mixed <= 0 ? 0 : mixed >= 255 ? 255 : Std.int(mixed + .5)) << shift;
	}

	// The value a leg starts or ends at, by its number: 0 is `from`, 1 is `to`, and 2 and up the ends of the legs after the first.
	inline function legValue(number:Int):Int
		return number == 0 ? from : number == 1 ? to : legValues[number - 2];
}
