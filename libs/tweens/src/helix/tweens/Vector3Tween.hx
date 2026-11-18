package helix.tweens;

import helix.math.Ease;
import helix.math.Vector3;

/** Represents a point or a direction moving from one vector to another, in a straight line. `Vector2Tween` and `Vector4Tween` are the
	same for their vectors.

	```haxe
	var slide = new Vector3Tween(door.position, open, 1.5, Ease.inOutQuad, door.position);
	// each frame
	slide.update(dt); // moves door.position
	``` */
class Vector3Tween extends EasedTween {
	/** Gets the vector at the start, the tween's own. Setting its components moves the start. */
	public final from:Vector3;

	/** Gets the vector at the end, the tween's own: the first leg's end, where `append` added more legs. Setting its components
		moves the end, as for a target that moves. */
	public final to:Vector3;

	/** Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own. */
	public final value:Vector3;

	// The values the legs after the first end at, in the order added.
	var legValues:Null<Array<Vector3>>;

	/** Creates a tween of a vector, at its start.

		@param from  The vector at the start. The tween keeps a copy.
		@param to  The vector at the end. The tween keeps a copy.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted.
		@param out  Optional. The vector each `update` writes, which may be `from` or `to`; a new one when omitted. */
	public function new(from:Vector3, to:Vector3, duration:Float, ?ease:Ease, ?out:Vector3) {
		super(duration, ease);
		this.from = from.copy();
		this.to = to.copy();
		value = out != null ? out : from.copy();
	}

	/** Adds a leg: the vector moves on from where the tween ended before to another vector.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek take every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// Up, a wait at the top, then down again.
		var lift = new Vector3Tween(bottom, top, 3, Ease.inOutSine, platform.position).appendDelay(1).append(bottom, 3, Ease.inOutSine);
		```

		@param to  The vector at the leg's end. The tween keeps a copy.
		@param duration  The seconds the leg takes, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function append(to:Vector3, duration:Float, ?ease:Ease):Vector3Tween {
		addLeg(duration, ease != null ? ease : Ease.linear);
		if (legValues == null)
			legValues = [];
		legValues.push(to.copy());
		return this;
	}

	/** Adds a wait: the vector stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function appendDelay(seconds:Float):Vector3Tween {
		addLeg(seconds, null);
		return this;
	}

	override function apply():Void {
		var start = legValue(legFrom), end = legValue(legTo);
		// Each end is the end's own numbers, where the sum between them would round.
		if (amount == 0)
			value.copyFrom(start);
		else if (amount == 1)
			value.copyFrom(end);
		else
			Vector3.lerp(start, end, amount, value);
	}

	// The value a leg starts or ends at, by its number: 0 is `from`, 1 is `to`, and 2 and up the ends of the legs after the first.
	inline function legValue(number:Int):Vector3
		return number == 0 ? from : number == 1 ? to : legValues[number - 2];
}
