package helix.jolt;

/** Represents a convex shape: a box, sphere, capsule, cylinder or hull. Its mass comes from its volume and its density: at the default
	density of 1000 kilograms a cubic meter, a box of 1 meter weighs 1000 kilograms. */
class ConvexShape extends Shape {
	function new() {
		super();
	}

	/** Returns the shape's density.

		@return  The density, in kilograms a cubic meter. */
	public function GetDensity():Float {
		throw "not built yet";
	}

	/** Sets the shape's density, for bodies made from the shape after.

		@param inDensity  The density, in kilograms a cubic meter. Defaults to 1000. */
	public function SetDensity(inDensity:Float):Void {
		throw "not built yet";
	}
}
