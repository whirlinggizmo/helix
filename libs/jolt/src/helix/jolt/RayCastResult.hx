package helix.jolt;

/** Represents a ray cast's hit. */
class RayCastResult {
	/** Gets or sets the body hit. */
	public var mBodyID:BodyID;

	/** Gets or sets how far along the ray the hit is, 0 to 1: `RRayCast.GetPointOnRay` returns the point. */
	public var mFraction:Float = 1 + 1e-4;

	/** Gets or sets the part of the body's shape hit, for the normal there:
		`physicsSystem.GetBodyLockInterfaceNoLock().TryGetBody(hit.mBodyID).GetWorldSpaceSurfaceNormal(hit.mSubShapeID2, point)`. */
	public var mSubShapeID2:SubShapeID;

	/** Creates a result of no hit. */
	public function new() {
		throw "not built yet";
	}
}
