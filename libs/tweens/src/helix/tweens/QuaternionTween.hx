package helix.tweens;

import helix.math.Ease;
import helix.math.Quaternion;

/** Represents a rotation turning from one rotation to another, the short way round (`Quaternion.slerp`).

	```haxe
	var turn = new QuaternionTween(turret.rotation, aimed, 0.8, Ease.inOutCubic, turret.rotation);
	// each frame
	turn.update(dt); // turns turret.rotation
	``` */
class QuaternionTween extends EasedTween {
	/** Gets the rotation at the start, the tween's own. Setting its components moves the start. */
	public final from:Quaternion;

	/** Gets the rotation at the end, the tween's own: the first leg's end, where `append` added more legs. Setting its components
		moves the end, as for a target that moves. */
	public final to:Quaternion;

	/** Gets the rotation each `update` writes: the `out` the tween was made with, or the tween's own. */
	public final value:Quaternion;

	// The values the legs after the first end at, in the order added.
	var legValues:Null<Array<Quaternion>>;

	/** Creates a tween of a rotation, at its start.

		@param from  The rotation at the start. The tween keeps a copy.
		@param to  The rotation at the end. The tween keeps a copy.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted.
		@param out  Optional. The rotation each `update` writes, which may be `from` or `to`; a new one when omitted. */
	public function new(from:Quaternion, to:Quaternion, duration:Float, ?ease:Ease, ?out:Quaternion) {
		super(duration, ease);
		this.from = from.copy();
		this.to = to.copy();
		value = out != null ? out : from.copy();
	}

	/** Adds a leg: the rotation moves on from where the tween ended before to another rotation.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek take every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// To one side, then to the other.
		var sweep = new QuaternionTween(ahead, left, 1, Ease.inOutSine, turret.rotation).append(right, 2, Ease.inOutSine);
		```

		@param to  The rotation at the leg's end. The tween keeps a copy.
		@param duration  The seconds the leg takes, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function append(to:Quaternion, duration:Float, ?ease:Ease):QuaternionTween {
		addLeg(duration, ease != null ? ease : Ease.linear);
		if (legValues == null)
			legValues = [];
		legValues.push(to.copy());
		return this;
	}

	/** Adds a wait: the rotation stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which took the tween's time when placed. */
	public function appendDelay(seconds:Float):QuaternionTween {
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
			Quaternion.slerp(start, end, amount, value);
	}

	// The value a leg starts or ends at, by its number: 0 is `from`, 1 is `to`, and 2 and up the ends of the legs after the first.
	inline function legValue(number:Int):Quaternion
		return number == 0 ? from : number == 1 ? to : legValues[number - 2];
}
