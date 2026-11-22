package helix.jolt;

/** Represents a shape swept along a line: a sphere for a thick ray, a character's capsule for where it would stop. */
class RShapeCast {
	/** Gets the shape. */
	public var mShape(default, null):Shape;

	/** Gets the shape's scale. */
	public var mScale(default, null):Vec3;

	/** Gets the transform of the shape's center of mass at the start. */
	public var mCenterOfMassStart(default, null):RMat44;

	/** Gets the direction, its length how far the shape is swept, in meters. */
	public var mDirection(default, null):Vec3;

	/** Creates a shape cast.

		@param inShape  The shape.
		@param inScale  The shape's scale.
		@param inCenterOfMassStart  The transform of the shape's center of mass at the start.
		@param inDirection  The direction, its length how far the shape is swept, in meters. */
	public function new(inShape:Shape, inScale:Vec3, inCenterOfMassStart:RMat44, inDirection:Vec3) {
		mShape = inShape;
		mScale = inScale;
		mCenterOfMassStart = inCenterOfMassStart;
		mDirection = inDirection;
	}

	/** Returns where the shape's center of mass is a fraction of the way along the cast.

		@param inFraction  The fraction, from a result's `mFraction`.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point, in meters. */
	public function GetPointOnRay(inFraction:Float, ?out:RVec3):RVec3 {
		var start = mCenterOfMassStart.GetTranslation(out);
		return (start : helix.math.Vector3).addScaled(mDirection, inFraction, start);
	}
}
