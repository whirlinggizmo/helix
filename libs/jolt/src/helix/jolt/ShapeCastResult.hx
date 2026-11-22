package helix.jolt;

/** Represents a shape cast's hit: where the swept shape first touches a body. */
class ShapeCastResult extends CollideShapeResult {
	/** Gets or sets how far along the cast the hit is, 0 to 1. */
	public var mFraction:Float = 0;

	/** Gets or sets a value indicating whether a face was hit from behind. */
	public var mIsBackFaceHit:Bool = false;

	/** Creates an empty result. */
	public function new() {
		super();
		// The vectors are the collide shape result's.
	}
}
