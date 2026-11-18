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

	/** Gets the vector at the end, the tween's own. Setting its components moves the end, as for a target that moves. */
	public final to:Vector3;

	/** Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own. */
	public final value:Vector3;

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

	override function apply():Void {
		// Each end is the end's own numbers, where the sum between them would round.
		if (amount == 0)
			value.copyFrom(from);
		else if (amount == 1)
			value.copyFrom(to);
		else
			Vector3.lerp(from, to, amount, value);
	}
}
