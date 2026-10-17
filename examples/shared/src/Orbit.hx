import helix.render3d.Camera3D;

/** The examples' circling camera: a point going round a target at a radius and a height, looking at the target. `update` advances it, `apply`
	places a camera there. At an angle of 0 the camera is on the target's +z side, and the angle grows toward +x. A game moves its cameras its
	own way; this is the examples' choice. */
class Orbit {
	/** Where round the circle it is, in radians: 0 on the target's +z side, a quarter turn on its +x side. */
	public var angle:Float;

	/** How fast it goes round, in radians a second; under 0 the other way. */
	public var speed:Float;

	/** How far out from the target, across the ground, in world units. */
	public var radius:Float;

	/** How high the camera is, in world units: its y, not its height over the target. */
	public var height:Float;

	/** The point the camera looks at, in world units. */
	public var targetX:Float;

	/** The point the camera looks at, in world units. */
	public var targetY:Float;

	/** The point the camera looks at, in world units. */
	public var targetZ:Float;

	/** Whether `update` goes round; false holds the camera where it is. */
	public var running = true;

	/** A circle of radius at height, going round at speed radians a second from angle, looking at (0, targetY, 0); targetX and targetZ move
		the point looked at. */
	public function new(radius:Float, height:Float, speed = .25, targetY = 0., angle = 0.) {
		this.radius = radius;
		this.height = height;
		this.speed = speed;
		targetX = 0;
		this.targetY = targetY;
		targetZ = 0;
		this.angle = angle;
	}

	/** Goes round for dt seconds, if running. */
	public function update(dt:Float):Void {
		if (running)
			angle += speed * dt;
	}

	/** Places camera on the circle at the angle, looking at the target (its setView). */
	public function apply(camera:Camera3D):Void
		camera.setView(targetX + radius * Math.sin(angle), height, targetZ + radius * Math.cos(angle), targetX, targetY, targetZ);
}
