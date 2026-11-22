package helix.jolt;

import helix.math.Matrix4;

/** Represents Jolt's `Mat44`: a transform. Wraps helix-math's `Matrix4`, whose fields and methods it also has, and is passed as a
	`Matrix4` without a copy, as helix-raylib's `Matrix` and its `DrawMeshInstanced` accept it.

	_Note that a `Mat44` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new
	`Mat44` when `out` is omitted._ */
@:forward
abstract Mat44(Matrix4) from Matrix4 to Matrix4 {
	/** Creates the identity transform. */
	public inline function new() {
		this = new Matrix4();
	}

	/** Returns the transform that rotates, then moves.

		@param inR  The rotation.
		@param inT  The translation.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public static function sRotationTranslation(inR:Quat, inT:Vec3, ?out:Mat44):Mat44 {
		var m:Matrix4 = Matrix4.fromQuaternion(inR.x, inR.y, inR.z, inR.w, out);
		m.m12 = inT.x;
		m.m13 = inT.y;
		m.m14 = inT.z;
		return m;
	}

	/** Returns the transform that moves.

		@param inV  The translation.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public static function sTranslation(inV:Vec3, ?out:Mat44):Mat44 {
		return Matrix4.fromTranslation(inV.x, inV.y, inV.z, out);
	}

	/** Returns the transform's translation.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The translation. */
	public function GetTranslation(?out:Vec3):Vec3 {
		return this.getTranslation(out);
	}

	/** Returns the transform's rotation.

		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The rotation. */
	public function GetQuaternion(?out:Quat):Quat {
		return this.getRotation(out);
	}
}
