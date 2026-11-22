package helix.jolt;

/** Represents a constraint between two bodies. `BodyInterface.CreateConstraint` returns the kind its settings make. */
class TwoBodyConstraint extends Constraint {
	function new() {
		super();
	}

	/** Returns the first body.

		@return  The body's id. */
	public function GetBody1():BodyID {
		throw "not built yet";
	}

	/** Returns the second body.

		@return  The body's id. */
	public function GetBody2():BodyID {
		throw "not built yet";
	}
}
