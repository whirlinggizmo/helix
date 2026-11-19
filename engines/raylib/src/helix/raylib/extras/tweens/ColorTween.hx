package helix.raylib.extras.tweens;

import helix.raylib.Color;

/** Represents a `Color` fading from one color to another, each of its four channels on its own. Wraps helix-tweens' `ColorTween`,
	accepting raylib's `Color`. It is placed in a sequence or added to a set like any tween.

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

	/** Gets or sets the color at the end: the first leg's end, where `append` added more legs. */
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

	/** Adds a leg: the color fades on from where the tween ended before to another color.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek take every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// To red, a wait, then back to white.
		var flash = new ColorTween(WHITE, RED, 0.1).appendDelay(0.2).append(WHITE, 0.5, Ease.outQuad);
		```

		@param to  The color at the leg's end.
		@param duration  The seconds the leg takes, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public inline function append(to:Color, duration:Float, ?ease:Ease):ColorTween {
		this.append(cast to, duration, ease);
		return cast this;
	}

	/** Adds a wait: the color stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public inline function appendDelay(seconds:Float):ColorTween {
		this.appendDelay(seconds);
		return cast this;
	}

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
