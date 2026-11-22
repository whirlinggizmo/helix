package helix.box2d;

/** Joint type enumeration. */
enum abstract B2JointType(Int) to Int {
	/** Constrain the distance between two points. */
	var b2_distanceJoint = 0;

	/** Filter collision between two bodies. */
	var b2_filterJoint = 1;

	/** Fully control the movement of a body. */
	var b2_motorJoint = 2;

	/** Control the movement of the dynamic character mover. */
	var b2_moverJoint = 3;

	/** Ground interaction for the dynamic character mover. */
	var b2_pogoJoint = 4;

	/** Slide along an axis. */
	var b2_prismaticJoint = 5;

	/** Rotate around a pivot. */
	var b2_revoluteJoint = 6;

	/** Bring two bodies together with some flex. */
	var b2_weldJoint = 7;

	/** Wheel spins with shock absorber. */
	var b2_wheelJoint = 8;
}
