package helix.jolt;

import helix.jolt.Jolt.*;

/** Represents a contact between two bodies in a step, read from a `ContactEventQueue`: an extra of helix-jolt's. */
class ContactEvent {
	/** Gets or sets what happened. */
	public var mType:EContactEventType;

	/** Gets or sets the first body. Of a sensor and another body, the sensor is the first. Of two other bodies, the one of the lower
		index (`BodyID.GetIndex`) is the first. */
	public var mBodyID1:BodyID;

	/** Gets or sets the second body. */
	public var mBodyID2:BodyID;

	/** Gets or sets the part of the first body's shape. */
	public var mSubShapeID1:SubShapeID;

	/** Gets or sets the part of the second body's shape. */
	public var mSubShapeID2:SubShapeID;

	/** Gets or sets the normal from the first body to the second, of length 1. (0, 0, 0) when `mType` is `EContactEventType_Removed`. */
	public var mWorldSpaceNormal:Vec3;

	/** Gets or sets the middle of the contact points on the first body, in the world, in meters. (0, 0, 0) when `mType` is
		`EContactEventType_Removed`. */
	public var mContactPoint:RVec3;

	/** Gets or sets how deep the bodies overlap, in meters. 0 when `mType` is `EContactEventType_Removed`. */
	public var mPenetrationDepth:Float = 0;

	/** Creates an empty event. */
	public function new() {
		mType = EContactEventType_Added;
		mBodyID1 = new BodyID();
		mBodyID2 = new BodyID();
		mSubShapeID1 = new SubShapeID();
		mSubShapeID2 = new SubShapeID();
		mWorldSpaceNormal = new Vec3();
		mContactPoint = new RVec3();
	}
}
