package helix.jolt;

import helix.math.Vector3;

/** Represents Jolt's `Vec3`: a direction, a velocity or a size. Wraps helix-math's `Vector3`, whose fields and methods it also has,
	and is passed as a `Vector3` without a copy.

	Jolt reads each component as a 32-bit float, so a value set here is rounded to the nearest 32-bit float as Jolt reads it.

	_Note that a `Vec3` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new
	`Vec3` when `out` is omitted._ */
@:forward
abstract Vec3(Vector3) from Vector3 to Vector3 {
	/** Creates a vector.

		@param inX  Optional. The x component; defaults to 0.
		@param inY  Optional. The y component; defaults to 0.
		@param inZ  Optional. The z component; defaults to 0. */
	public inline function new(inX = 0., inY = 0., inZ = 0.) {
		this = new Vector3(inX, inY, inZ);
	}

	/** Returns (0, 0, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sZero(?out:Vec3):Vec3 {
		return out == null ? new Vec3() : (out : Vector3).set(0, 0, 0);
	}

	/** Returns (1, 1, 1).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sOne(?out:Vec3):Vec3 {
		return out == null ? new Vec3(1, 1, 1) : (out : Vector3).set(1, 1, 1);
	}

	/** Returns (1, 0, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sAxisX(?out:Vec3):Vec3 {
		return out == null ? new Vec3(1, 0, 0) : (out : Vector3).set(1, 0, 0);
	}

	/** Returns (0, 1, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sAxisY(?out:Vec3):Vec3 {
		return out == null ? new Vec3(0, 1, 0) : (out : Vector3).set(0, 1, 0);
	}

	/** Returns (0, 0, 1).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sAxisZ(?out:Vec3):Vec3 {
		return out == null ? new Vec3(0, 0, 1) : (out : Vector3).set(0, 0, 1);
	}

	/** Returns a vector with one value in each component.

		@param inValue  The value.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function sReplicate(inValue:Float, ?out:Vec3):Vec3 {
		return out == null ? new Vec3(inValue, inValue, inValue) : (out : Vector3).set(inValue, inValue, inValue);
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

	/** Sets the x component.

		@param inX  The component. */
	public function SetX(inX:Float):Void {
		this.x = inX;
	}

	/** Sets the y component.

		@param inY  The component. */
	public function SetY(inY:Float):Void {
		this.y = inY;
	}

	/** Sets the z component.

		@param inZ  The component. */
	public function SetZ(inZ:Float):Void {
		this.z = inZ;
	}

	/** Sets the three components.

		@param inX  The x component.
		@param inY  The y component.
		@param inZ  The z component. */
	public function Set(inX:Float, inY:Float, inZ:Float):Void {
		this.set(inX, inY, inZ);
	}

	/** Returns the vector's length.

		@return  The length. */
	public function Length():Float {
		return this.length;
	}

	/** Returns the square of the vector's length.

		@return  The length squared. */
	public function LengthSq():Float {
		return this.lengthSquared;
	}

	/** Returns the vector scaled to a length of 1.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector. */
	public function Normalized(?out:Vec3):Vec3 {
		return this.normalize(out);
	}

	/** Returns the dot product with another vector.

		@param inRHS  The other vector.
		@return  The dot product. */
	public function Dot(inRHS:Vec3):Float {
		return this.dot(inRHS);
	}

	/** Returns the cross product with another vector.

		@param inRHS  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be either vector.
		@return  The cross product. */
	public function Cross(inRHS:Vec3, ?out:Vec3):Vec3 {
		return this.cross(inRHS, out);
	}

	/** Returns the sum with another vector.

		@param inV  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be either vector.
		@return  The sum. */
	public function AddVec3(inV:Vec3, ?out:Vec3):Vec3 {
		return this.add(inV, out);
	}

	/** Returns the difference from another vector.

		@param inV  The vector subtracted.
		@param out  Optional. The vector to fill; a new one when omitted. It may be either vector.
		@return  The difference. */
	public function SubVec3(inV:Vec3, ?out:Vec3):Vec3 {
		return this.subtract(inV, out);
	}

	/** Returns the vector multiplied by a number.

		@param inV  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The product. */
	public function MulFloat(inV:Float, ?out:Vec3):Vec3 {
		return this.scale(inV, out);
	}

	/** Returns whether the vector is within a distance of (0, 0, 0).

		@param inMaxDistSq  Optional. The square of the distance; defaults to 1e-12.
		@return  True when the vector is that close. */
	public function IsNearZero(inMaxDistSq = 1e-12):Bool {
		return this.lengthSquared <= inMaxDistSq;
	}

	/** Returns whether the vector is within a distance of another.

		@param inV  The other vector.
		@param inMaxDistSq  Optional. The square of the distance; defaults to 1e-12.
		@return  True when the vectors are that close. */
	public function IsClose(inV:Vec3, inMaxDistSq = 1e-12):Bool {
		return this.distanceSquared(inV) <= inMaxDistSq;
	}
}
