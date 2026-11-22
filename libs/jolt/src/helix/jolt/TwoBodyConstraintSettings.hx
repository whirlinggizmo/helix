package helix.jolt;

import helix.jolt.internal.Io;

/** Represents what a constraint between two bodies is made from, passed to `BodyInterface.CreateConstraint`, which returns the
	constraint as `T`. */
class TwoBodyConstraintSettings<T:TwoBodyConstraint> extends ConstraintSettings {
	/** Gets or sets the space the points and axes are in. Defaults to `EConstraintSpace_WorldSpace`. */
	public var mSpace:EConstraintSpace = EConstraintSpace_WorldSpace;

	function new() {
		super();
	}

	/** Writes the settings into the shared areas and returns the kind hj_constraint_create reads. */
	@:allow(helix.jolt) function write():Int {
		Io.setI(0, cast mSpace);
		Io.setI(1, mEnabled ? 1 : 0);
		return -1;
	}

	/** Makes the constraint object for a handle the module returned. */
	@:allow(helix.jolt) function make(world:Int, handle:Int):T {
		return null;
	}
}
