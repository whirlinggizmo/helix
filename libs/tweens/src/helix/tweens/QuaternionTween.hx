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

	/** Gets the rotation at the end, the tween's own. Setting its components moves the end, as for a target that moves. */
	public final to:Quaternion;

	/** Gets the rotation each `update` writes: the `out` the tween was made with, or the tween's own. */
	public final value:Quaternion;

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

	override function apply():Void {
		// Each end is the end's own numbers, where the sum between them would round.
		if (amount == 0)
			value.copyFrom(from);
		else if (amount == 1)
			value.copyFrom(to);
		else
			Quaternion.slerp(from, to, amount, value);
	}
}
