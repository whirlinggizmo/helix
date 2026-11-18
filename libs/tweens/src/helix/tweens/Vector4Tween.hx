package helix.tweens;

import helix.math.Ease;
import helix.math.Vector4;

/** Represents four numbers moving from one vector to another, each on its own.

	```haxe
	var warm = new Vector4Tween(new Vector4(1, 1, 1, 1), new Vector4(1, 0.8, 0.6, 1), 2, Ease.inOutSine);
	// each frame
	warm.update(dt);
	material.setColor(warm.value);
	``` */
class Vector4Tween extends EasedTween {
	/** Gets the vector at the start, the tween's own. Setting its components moves the start. */
	public final from:Vector4;

	/** Gets the vector at the end, the tween's own. Setting its components moves the end, as for a target that moves. */
	public final to:Vector4;

	/** Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own. */
	public final value:Vector4;

	/** Creates a tween of a vector, at its start.

		@param from  The vector at the start. The tween keeps a copy.
		@param to  The vector at the end. The tween keeps a copy.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted.
		@param out  Optional. The vector each `update` writes, which may be `from` or `to`; a new one when omitted. */
	public function new(from:Vector4, to:Vector4, duration:Float, ?ease:Ease, ?out:Vector4) {
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
			Vector4.lerp(from, to, amount, value);
	}
}
