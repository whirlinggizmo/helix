package helix.jolt;

/** Represents no shape: a body that collides with nothing, such as one a constraint holds others to. */
class EmptyShape extends Shape {
	/** Creates the shape.

		@param inCenterOfMass  Optional. The center of mass; defaults to (0, 0, 0). */
	public function new(?inCenterOfMass:Vec3) {
		super();
		throw "not built yet";
	}
}
