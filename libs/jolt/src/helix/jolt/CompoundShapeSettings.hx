package helix.jolt;

/** Represents what a compound shape is built from: shapes put together, each moved and turned. */
class CompoundShapeSettings extends ShapeSettings {
	function new() {
		super();
	}

	/** Adds a shape.

		@param inPosition  Where the part is, from the compound's origin, in meters.
		@param inRotation  How the part is turned.
		@param inShape  The part.
		@param inUserData  Optional. A number the part keeps for the program; defaults to 0. */
	public function AddShape(inPosition:Vec3, inRotation:Quat, inShape:Shape, inUserData = 0):Void {
		throw "not built yet";
	}
}
