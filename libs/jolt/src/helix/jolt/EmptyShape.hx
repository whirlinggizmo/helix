package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents no shape: a body that collides with nothing, such as one a constraint holds others to. */
class EmptyShape extends Shape {
	/** Creates the shape.

		@param inCenterOfMass  Optional. The center of mass; defaults to (0, 0, 0). */
	public function new(?inCenterOfMass:Vec3) {
		super();
		register(inCenterOfMass == null ? Hj.shapeEmpty(0, 0, 0) : Hj.shapeEmpty(inCenterOfMass.x, inCenterOfMass.y, inCenterOfMass.z));
	}
}
