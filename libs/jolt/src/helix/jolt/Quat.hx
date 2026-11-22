package helix.jolt;

import helix.math.Quaternion;

/** Represents Jolt's `Quat`: a rotation. Wraps helix-math's `Quaternion`, whose fields and methods it also has, and is passed as a
	`Quaternion` without a copy.

	_Note that a `Quat` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new
	`Quat` when `out` is omitted._ */
@:forward
abstract Quat(Quaternion) from Quaternion to Quaternion {
	/** Creates a quaternion from its components.

		@param inX  The x component.
		@param inY  The y component.
		@param inZ  The z component.
		@param inW  The w component. */
	public inline function new(inX:Float, inY:Float, inZ:Float, inW:Float) {
		this = new Quaternion(inX, inY, inZ, inW);
	}

	/** Returns the rotation that turns nothing.

		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	public static function sIdentity(?out:Quat):Quat {
		return out == null ? new Quat(0, 0, 0, 1) : (out : Quaternion).set(0, 0, 0, 1);
	}

	/** Returns a rotation about an axis.

		@param inAxis  The axis, of length 1.
		@param inAngle  The angle, in radians.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	public static function sRotation(inAxis:Vec3, inAngle:Float, ?out:Quat):Quat {
		return Quaternion.fromAxisAngle(inAxis.x, inAxis.y, inAxis.z, inAngle, out);
	}

	/** Returns the shortest rotation turning one direction onto another.

		@param inFrom  The first direction.
		@param inTo  The second direction.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	public static function sFromTo(inFrom:Vec3, inTo:Vec3, ?out:Quat):Quat {
		return Quaternion.fromBetween(inFrom, inTo, out);
	}

	/** Returns the rotation of angles about x, then y, then z.

		@param inInput  The angles, in radians.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	public static function sEulerAngles(inInput:Vec3, ?out:Quat):Quat {
		return Quaternion.fromEuler(inInput.x, inInput.y, inInput.z, helix.math.EulerOrder.ZYX, out);
	}

	/** Returns the x component.

		@return  The component. */
	public function GetX():Float {
		return this.x;
	}

	/** Returns the y component.

		@return  The component. */
	public function GetY():Float {
		return this.y;
	}

	/** Returns the z component.

		@return  The component. */
	public function GetZ():Float {
		return this.z;
	}

	/** Returns the w component.

		@return  The component. */
	public function GetW():Float {
		return this.w;
	}

	/** Sets the four components.

		@param inX  The x component.
		@param inY  The y component.
		@param inZ  The z component.
		@param inW  The w component. */
	public function Set(inX:Float, inY:Float, inZ:Float, inW:Float):Void {
		this.set(inX, inY, inZ, inW);
	}

	/** Returns the angles about x, then y, then z, that make the rotation.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angles, in radians. */
	public function GetEulerAngles(?out:Vec3):Vec3 {
		return this.toEuler(helix.math.EulerOrder.ZYX, out);
	}

	/** Returns another rotation followed by this one, as Jolt's `*` does.

		@param inQ  The rotation applied first.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be either quaternion.
		@return  The product. */
	public function MulQuat(inQ:Quat, ?out:Quat):Quat {
		return this.prepend(inQ, out);
	}

	/** Returns a vector turned by the rotation.

		@param inV  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be inV.
		@return  The turned vector. */
	public function MulVec3(inV:Vec3, ?out:Vec3):Vec3 {
		return this.transformPoint(inV.x, inV.y, inV.z, out);
	}

	/** Returns the rotation scaled to a length of 1.

		@param out  Optional. The quaternion to fill; a new one when omitted. It may be this quaternion.
		@return  The quaternion. */
	public function Normalized(?out:Quat):Quat {
		return this.normalize(out);
	}

	/** Returns the opposite rotation.

		@param out  Optional. The quaternion to fill; a new one when omitted. It may be this quaternion.
		@return  The quaternion. */
	public function Conjugated(?out:Quat):Quat {
		return this.invert(out);
	}

	/** Returns the rotation a fraction of the way to another, along the sphere.

		@param inDestination  The rotation at 1.
		@param inFraction  The fraction, 0 to 1.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be either quaternion.
		@return  The rotation. */
	public function SLERP(inDestination:Quat, inFraction:Float, ?out:Quat):Quat {
		return Quaternion.slerp(this, inDestination, inFraction, out);
	}
}
