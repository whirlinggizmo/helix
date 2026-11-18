package helix.tweens;

import helix.math.Ease;

/** Represents a play along an easing curve, from 0 to 1. `FloatTween`, `Vector3Tween` and the other kinds move a value by it, and a
	program moves a value of its own by `amount`.

	```haxe
	var grow = new EasedTween(0.5, Ease.outBack);
	// each frame
	grow.update(dt);
	rect.width = Interpolate.lerp(40, 200, grow.amount);
	rect.height = Interpolate.lerp(10, 60, grow.amount);
	``` */
class EasedTween extends Tween {
	/** Gets or sets the easing curve. */
	public var ease:Ease;

	/** Gets how far along the move is, by the easing curve: 0 at the start and 1 at the end. A curve that overshoots
		(`Ease.outBack`) passes 1 on the way. */
	public var amount(default, null) = 0.;

	final seconds:Float;

	/** Creates a tween at its start.

		@param duration  The seconds one play takes, 0 or more. A play of 0 seconds jumps to its end.
		@param ease  Optional. The easing curve, one of `Ease`'s (`Ease.outBounce`) or a function of the program's own (`Ease.of`);
			a straight line when omitted. */
	public function new(duration:Float, ?ease:Ease) {
		super();
		seconds = duration > 0 ? duration : 0;
		this.ease = ease != null ? ease : Ease.linear;
	}

	override function get_duration():Float
		return seconds;

	override function render(seconds:Float, fraction:Float, backward:Bool, calls:Bool):Void {
		// The ends are exact, whatever the curve rounds to there.
		amount = fraction <= 0 ? 0 : fraction >= 1 ? 1 : ease.at(fraction);
		apply();
	}

	// Moves the kind's value to `amount`.
	function apply():Void {}
}
