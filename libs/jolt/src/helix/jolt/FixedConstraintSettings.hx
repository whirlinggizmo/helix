package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint holding two bodies together, as if welded. */
class FixedConstraintSettings extends TwoBodyConstraintSettings<TwoBodyConstraint> {
	/** Gets or sets a value indicating whether the weld is where the bodies are when the constraint is made, the points and axes
		ignored. Defaults to false. */
	public var mAutoDetectPoint:Bool = false;

	/** Gets or sets the weld's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the weld's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mPoint2 = new RVec3();
	}

	override function write():Int {
		super.write();
		Io.setI(2, mAutoDetectPoint ? 1 : 0);
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, 1);
		Io.setF(4, 0);
		Io.setF(5, 0);
		Io.setF(6, 0);
		Io.setF(7, 1);
		Io.setF(8, 0);
		Io.setF(9, mPoint2.x);
		Io.setF(10, mPoint2.y);
		Io.setF(11, mPoint2.z);
		Io.setF(12, 1);
		Io.setF(13, 0);
		Io.setF(14, 0);
		Io.setF(15, 0);
		Io.setF(16, 1);
		Io.setF(17, 0);
		return 0;
	}

	override function make(world:Int, handle:Int):TwoBodyConstraint {
		return new TwoBodyConstraint(world, handle);
	}
}
