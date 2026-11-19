package helix.tweens;

import helix.math.Ease;

/** Represents a number moving from one value to another.

	```haxe
	var zoom = new FloatTween(1, 2, 0.3, Ease.outCubic);
	// each frame
	zoom.update(dt);
	camera.zoom = zoom.value;
	``` */
class FloatTween extends EasedTween {
	/** Gets or sets the value at the start. */
	public var from:Float;

	/** Gets or sets the value at the end: the first leg's end, where `append` added more legs. */
	public var to:Float;

	/** Gets the value now: `from` until the tween starts, and the last leg's end once the tween ends. */
	public var value(get, never):Float;

	// The values the legs after the first end at, in the order added.
	var legValues:Null<Array<Float>>;

	/** Creates a tween of a number, at its start.

		@param from  The value at the start.
		@param to  The value at the end.
		@param duration  The seconds one play lasts, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted. */
	public function new(from:Float, to:Float, duration:Float, ?ease:Ease) {
		super(duration, ease);
		this.from = from;
		this.to = to;
	}

	function get_value():Float {
		var start = legValue(legFrom), end = legValue(legTo);
		return amount == 1 ? end : start + (end - start) * amount;
	}

	/** Adds a leg: the value moves on from where the tween ended before to another value.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek treat every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// Across in 2 seconds, a second's wait, back in 2 and a second's wait, for ever.
		var x = new FloatTween(-4, 4, 2, Ease.outBounce).appendDelay(1).append(-4, 2, Ease.inOutSine).appendDelay(1);
		x.repeatCount = -1;
		// each frame
		x.update(dt);
		ball.x = x.value;
		```

		@param to  The value at the leg's end.
		@param duration  The seconds the leg lasts, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which fixed the tween's time when placed. */
	public function append(to:Float, duration:Float, ?ease:Ease):FloatTween {
		addLeg(duration, ease != null ? ease : Ease.linear);
		if (legValues == null)
			legValues = [];
		legValues.push(to);
		return this;
	}

	/** Adds a wait: the value stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which fixed the tween's time when placed. */
	public function appendDelay(seconds:Float):FloatTween {
		addLeg(seconds, null);
		return this;
	}

	// The value a leg starts or ends at, by its number: 0 is `from`, 1 is `to`, and 2 and up the ends of the legs after the first.
	inline function legValue(number:Int):Float
		return number == 0 ? from : number == 1 ? to : legValues[number - 2];
}
