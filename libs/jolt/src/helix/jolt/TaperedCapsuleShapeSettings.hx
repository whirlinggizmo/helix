package helix.jolt;

/** Represents what a tapered capsule is built from: a capsule along y whose ends are spheres of different radii. */
class TaperedCapsuleShapeSettings extends ConvexShapeSettings {
	/** Gets or sets half the height between the ends' centers, in meters. */
	public var mHalfHeightOfTaperedCylinder:Float;

	/** Gets or sets the top end's radius, in meters. */
	public var mTopRadius:Float;

	/** Gets or sets the bottom end's radius, in meters. */
	public var mBottomRadius:Float;

	/** Creates the settings.

		@param inHalfHeightOfTaperedCylinder  Half the height between the ends' centers, in meters.
		@param inTopRadius  The top end's radius, in meters.
		@param inBottomRadius  The bottom end's radius, in meters. */
	public function new(inHalfHeightOfTaperedCylinder:Float, inTopRadius:Float, inBottomRadius:Float) {
		super();
		throw "not built yet";
	}
}
