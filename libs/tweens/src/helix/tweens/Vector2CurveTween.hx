package helix.tweens;

import helix.math.Curve;
import helix.math.Ease;
import helix.math.Vector2;

/** Represents a point moving along a curve in 2 dimensions (`helix.math.Curve`): through points, along Bézier pieces or straight from
	point to point.

	The point moves at a steady speed along the curve's length, which the easing curve then shapes. `from` and `to` choose a part of
	the curve to move along.

	```haxe
	var swoop = new Vector2CurveTween(Curve.through([40, 300, 200, 80, 360, 300]), 1.5, Ease.inOutQuad, bird.position);
	// each frame
	swoop.update(dt); // moves bird.position along the curve
	bird.rotation = Math.atan2(swoop.direction.y, swoop.direction.x);
	``` */
class Vector2CurveTween extends EasedTween {
	/** Gets the curve the point moves along. */
	public final curve:Curve;

	/** Gets or sets where along the curve the point starts, as a fraction of the curve's length: 0 for the curve's start, 1 for its
		end. Defaults to 0. */
	public var from = 0.;

	/** Gets or sets where along the curve the point ends, as a fraction of the curve's length: the first leg's end, where `append`
		added more legs. A fraction less than `from` moves the point back along the curve. Defaults to 1. */
	public var to = 1.;

	/** Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.

		A place before the curve's start or past its end, by `from`, `to` or an easing curve that overshoots, is held at that end of
		an open curve and carries on round a closed one. */
	public final value:Vector2;

	/** Gets the way the curve heads at `value`, of length 1, which each `update` writes. It is the curve's own heading, whichever way
		the point moves. */
	public final direction:Vector2;

	// The values the legs after the first end at, in the order added.
	var legValues:Null<Array<Float>>;

	// The curve's numbers at the point, kept so that a step makes no array.
	final position:Array<Float> = [0., 0.];
	final heading:Array<Float> = [0., 0.];

	/** Creates a tween along a curve, at the curve's start.

		@param curve  The curve, in 2 dimensions. The tween keeps the curve itself.
		@param duration  The seconds one play lasts, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted.
		@param out  Optional. The vector each `update` writes; a new one when omitted.
		@throws String  A curve in 3 dimensions. */
	public function new(curve:Curve, duration:Float, ?ease:Ease, ?out:Vector2) {
		super(duration, ease);
		if (curve.dimensionCount != 2)
			throw 'A Vector2CurveTween moves along a curve in 2 dimensions, not ${curve.dimensionCount}';
		this.curve = curve;
		curve.computePosition(0, position);
		curve.computeTangent(0, heading);
		value = out != null ? out : new Vector2(position[0], position[1]);
		direction = new Vector2(heading[0], heading[1]);
	}

	/** Adds a leg: the point moves on from where the tween ended before to another place along the curve.

		The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek treat every leg as one play. `from`, `to` and
		`ease` stay the first leg's.

		```haxe
		// Half way along, a wait, then on to the end.
		var walk = new Vector2CurveTween(path, 4, guard.position);
		walk.to = 0.5;
		walk.appendDelay(2).append(1, 4);
		```

		@param to  Where along the curve the leg ends, as a fraction of the curve's length. A fraction less than the leg's start moves the
			point back along the curve.
		@param duration  The seconds the leg lasts, 0 or more.
		@param ease  Optional. The leg's easing curve; a straight line when omitted.
		@return  This tween.
		@throws String  A tween placed in a sequence, which fixed the tween's time when placed. */
	public function append(to:Float, duration:Float, ?ease:Ease):Vector2CurveTween {
		addLeg(duration, ease != null ? ease : Ease.linear);
		if (legValues == null)
			legValues = [];
		legValues.push(to);
		return this;
	}

	/** Adds a wait: the point stays where the tween ended before, for some seconds.

		@param seconds  The seconds to wait, 0 or more.
		@return  This tween.
		@throws String  A tween placed in a sequence, which fixed the tween's time when placed. */
	public function appendDelay(seconds:Float):Vector2CurveTween {
		addLeg(seconds, null);
		return this;
	}

	override function apply():Void {
		var start = legValue(legFrom), end = legValue(legTo);
		var place = amount == 1 ? end : start + (end - start) * amount;
		var t = curve.getParameterAtDistance(place * curve.length);
		curve.computePosition(t, position);
		curve.computeTangent(t, heading);
		value.set(position[0], position[1]);
		direction.set(heading[0], heading[1]);
	}

	// The value a leg starts or ends at, by its number: 0 is `from`, 1 is `to`, and 2 and up the ends of the legs after the first.
	inline function legValue(number:Int):Float
		return number == 0 ? from : number == 1 ? to : legValues[number - 2];
}
