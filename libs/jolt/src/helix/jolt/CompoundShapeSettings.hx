package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

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
		parts.push({
			position: inPosition,
			rotation: inRotation,
			shape: inShape,
			userData: inUserData
		});
	}

	var parts:Array<{
		position:Vec3,
		rotation:Quat,
		shape:Shape,
		userData:Int
	}> = [];

	override function make():Int {
		var count = parts.length;
		var base = Io.bulk(count * 36);
		for (n in 0...count) {
			var part = parts[n];
			Io.setBulkF(base, n * 7, part.position.x);
			Io.setBulkF(base, n * 7 + 1, part.position.y);
			Io.setBulkF(base, n * 7 + 2, part.position.z);
			Io.setBulkF(base, n * 7 + 3, part.rotation.x);
			Io.setBulkF(base, n * 7 + 4, part.rotation.y);
			Io.setBulkF(base, n * 7 + 5, part.rotation.z);
			Io.setBulkF(base, n * 7 + 6, part.rotation.w);
			Io.setBulkI(base, count * 7 + n * 2, part.shape.handle);
			Io.setBulkI(base, count * 7 + n * 2 + 1, part.userData);
		}
		return Hj.shapeStaticCompound(count, mUserData);
	}
}
