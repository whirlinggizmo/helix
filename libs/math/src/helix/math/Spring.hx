package helix.math;

/** Represents a value that follows a target as a damped spring does: the value speeds up, slows as it nears the target, and stops at
	the target without going past (Unity's SmoothDamp).

	```haxe
	var zoom = new Spring(1);
	zoom.update(target, .25, dt);
	camera.zoom = zoom.value;
	```
 */
class Spring {
	/** Gets or sets the value. */
	public var value:Float;

	/** Gets or sets how fast the value is changing, per second. */
	public var velocity = 0.;

	/** Creates a spring at rest.

		@param value  Optional. The value the spring starts at; defaults to 0. */
	public function new(value = 0.) {
		this.value = value;
	}

	/** Moves the value toward a target over a time step, the same at any frame rate.

		A time step of 0 or less leaves the value and the velocity unchanged. A value that would pass the target stops at the target.
		@param target  The target.
		@param time  About how long the value needs to reach the target, in seconds: the value closes 3/5 of the gap in that time from
			rest, and 9/10 in twice that time. 0 or less puts the value at the target.
		@param dt  The time step, in seconds.
		@return  The value. */
	public function update(target:Float, time:Float, dt:Float):Float {
		if (!(dt > 0))
			return value;
		if (!(time > 0)) {
			velocity = 0;
			return value = target;
		}
		// A critically damped spring's own motion over the step, so two half steps are one whole step.
		var rate = 2 / time, decay = Math.exp(-rate * dt);
		var gap = value - target;
		var pull = (velocity + rate * gap) * dt;
		var next = target + (gap + pull) * decay;
		if (gap > 0 ? next < target : gap < 0 && next > target) {
			velocity = 0;
			return value = target;
		}
		velocity = (velocity - rate * pull) * decay;
		return value = next;
	}
}
