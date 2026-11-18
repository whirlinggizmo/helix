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

	/** Gets or sets the value at the end. */
	public var to:Float;

	/** Gets the value now: `from` until the tween starts, `to` once it ends. */
	public var value(get, never):Float;

	/** Creates a tween of a number, at its start.

		@param from  The value at the start.
		@param to  The value at the end.
		@param duration  The seconds one play takes, 0 or more.
		@param ease  Optional. The easing curve; a straight line when omitted. */
	public function new(from:Float, to:Float, duration:Float, ?ease:Ease) {
		super(duration, ease);
		this.from = from;
		this.to = to;
	}

	function get_value():Float
		return amount == 1 ? to : from + (to - from) * amount;
}
