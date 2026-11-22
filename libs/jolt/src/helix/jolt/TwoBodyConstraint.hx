package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a constraint between two bodies. `BodyInterface.CreateConstraint` returns the kind its settings make. */
class TwoBodyConstraint extends Constraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Returns the first body.

		@return  The body's id. */
	public function GetBody1():BodyID {
		return new BodyID(Hj.constraintGetBody(world, handle, 0));
	}

	/** Returns the second body.

		@return  The body's id. */
	public function GetBody2():BodyID {
		return new BodyID(Hj.constraintGetBody(world, handle, 1));
	}
}
