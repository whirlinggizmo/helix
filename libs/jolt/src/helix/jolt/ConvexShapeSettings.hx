package helix.jolt;

/** Represents what a convex shape is built from. */
class ConvexShapeSettings extends ShapeSettings {
	/** Gets or sets the density, in kilograms a cubic meter. Defaults to 1000. */
	public var mDensity:Float = 1000;

	function new() {
		super();
	}
}
