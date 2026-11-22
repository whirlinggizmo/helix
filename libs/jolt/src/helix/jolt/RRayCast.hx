package helix.jolt;

/** Represents a ray: an origin and a direction whose length is how far the ray reaches. */
class RRayCast {
	/** Gets or sets the origin, in meters. */
	public var mOrigin:RVec3;

	/** Gets or sets the direction, its length how far the ray reaches, in meters. */
	public var mDirection:Vec3;

	/** Creates a ray.

		@param inOrigin  Optional. The origin; defaults to (0, 0, 0).
		@param inDirection  Optional. The direction and reach; defaults to (0, 0, 0). */
	public function new(?inOrigin:RVec3, ?inDirection:Vec3) {
		mOrigin = inOrigin == null ? new RVec3() : inOrigin;
		mDirection = inDirection == null ? new Vec3() : inDirection;
	}

	/** Returns the point a fraction of the way along the ray, such as a hit's.

		@param inFraction  The fraction, from a result's `mFraction`.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point, in meters. */
	public function GetPointOnRay(inFraction:Float, ?out:RVec3):RVec3 {
		return (mOrigin : helix.math.Vector3).addScaled(mDirection, inFraction, out == null ? new helix.math.Vector3() : out);
	}
}
