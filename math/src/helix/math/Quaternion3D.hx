package helix.math;

import haxe.exceptions.NotImplementedException;

/** Represents a rotation in 3 dimensions, as a unit quaternion.

	Two rotations blend along the shortest arc (`slerp`), which matrices can't do, so an animation's rotations are kept as these and
	turned into a matrix to draw. A static `fromX` makes a rotation, and `slerp`, `nlerp` and `compose` make one from others. Each of
	those, and each operation on a rotation (`append`, `invert`, `normalize`, `transformPoint`, `toMatrix`), writes its result into an
	optional out, the last argument, and returns it. Without one it makes a new result and leaves this rotation unchanged; given this
	rotation, it changes it in place (`q.normalize(q)`). The out may be this rotation or any other argument, and calls chain through what
	each returns. `set`, `copyFrom` and `makeIdentity` change this rotation and return it. It uses `Trig`, so a rotation comes out the
	same on every target. Space is right-handed with +y up, as every 3D type here.

	```haxe
	var turn = Quaternion3D.fromAxisAngle(0, 1, 0, Math.PI / 2);
	var halfway = Quaternion3D.slerp(from, turn, .5);
	var facing = turn.transformPoint(0, 0, -1);
	``` */
class Quaternion3D {
	/** Gets or sets the quaternion's x, the axis's x scaled by the sine of half the angle. */
	public var x:Float;

	/** Gets or sets the quaternion's y. */
	public var y:Float;

	/** Gets or sets the quaternion's z. */
	public var z:Float;

	/** Gets or sets the quaternion's w, the cosine of half the angle. */
	public var w:Float;

	/** Creates a rotation, the identity unless the quaternion is provided.

		@param x  Optional. The quaternion's x; defaults to 0.
		@param y  Optional. The quaternion's y; defaults to 0.
		@param z  Optional. The quaternion's z; defaults to 0.
		@param w  Optional. The quaternion's w; defaults to 1. */
	public function new(x = 0., y = 0., z = 0., w = 1.) {
		throw new NotImplementedException();
	}

	/** Returns a turn around an axis.

		An axis of length 0 makes the identity.
		@param axisX  The axis's x; it needn't be of length 1.
		@param axisY  The axis's y.
		@param axisZ  The axis's z.
		@param radians  The angle, counterclockwise looking down the axis toward the origin.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromAxisAngle(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation of three turns, around x, then y, then z, each around the world's axes.

		@param pitch  The turn around x, in radians.
		@param yaw  The turn around y, in radians.
		@param roll  The turn around z, in radians.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromEuler(pitch:Float, yaw:Float, roll:Float, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation that turns -z to face a direction, +y kept as near to up as it can be.

		A direction of length 0 makes the identity; an up along the direction is replaced by another axis.
		@param forwardX  The direction to face's x; it needn't be of length 1.
		@param forwardY  The direction's y.
		@param forwardZ  The direction's z.
		@param upX  Optional. Up's x; defaults to 0.
		@param upY  Optional. Up's y; defaults to 1.
		@param upZ  Optional. Up's z; defaults to 0.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromLookRotation(forwardX:Float, forwardY:Float, forwardZ:Float, upX = 0., upY = 1., upZ = 0., ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the shortest turn from one direction to another.

		@param from  The first direction; it needn't be of length 1.
		@param to  The second direction.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromBetween(from:Vector3D, to:Vector3D, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation of a matrix, its scale ignored.

		@param matrix  The matrix: a rotation, scale and translation.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromMatrix(matrix:Matrix3D, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation part way from one rotation to another along the shortest arc, at an even speed (slerp).

		@param from  The rotation at 0.
		@param to  The rotation at 1.
		@param amount  How far, 0 to 1; outside it the turn goes on past either end.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be from or to.
		@return  The rotation. */
	public static function slerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation part way from one rotation to another along the shortest arc, faster than `slerp` but at an uneven speed
		(nlerp).

		@param from  The rotation at 0.
		@param to  The rotation at 1.
		@param amount  How far, 0 to 1.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be from or to.
		@return  The rotation. */
	public static function nlerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns one rotation followed by another.

		@param first  The rotation applied first.
		@param second  The rotation applied after it.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be first or second.
		@return  The rotation. */
	public static function compose(first:Quaternion3D, second:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Sets the quaternion's four numbers, as they are; `normalize` makes them a rotation if they aren't one.

		@param x  The x.
		@param y  The y.
		@param z  The z.
		@param w  The w.
		@return  This rotation. */
	public function set(x:Float, y:Float, z:Float, w:Float):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Sets this rotation to another's.

		@param other  The rotation to copy.
		@return  This rotation. */
	public function copyFrom(other:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Makes this the rotation that turns nothing.

		@return  This rotation. */
	public function makeIdentity():Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns this rotation followed by another.

		@param other  The rotation applied after this one.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
		@return  The rotation. */
	public function append(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns another rotation followed by this one.

		@param other  The rotation applied before this one.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
		@return  The rotation. */
	public function prepend(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the rotation that undoes this one.

		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation.
		@return  The inverse. */
	public function invert(?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns the quaternion scaled to length 1, so it is a rotation again after numbers set by hand or many compositions.

		A quaternion of length 0 gives the identity.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation.
		@return  The rotation. */
	public function normalize(?out:Quaternion3D):Quaternion3D {
		throw new NotImplementedException();
	}

	/** Returns a point turned by this rotation.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The turned point. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Returns the turns around x, y and z that `fromEuler` would make this from.

		Near straight up or down, where two turns do the same thing, the roll is 0.
		@param out  Optional. The vector to write into: pitch in x, yaw in y, roll in z, in radians; a new one when omitted.
		@return  The angles. */
	public function toEuler(?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Gets the angle this rotation turns by, around whatever axis, in radians, 0 to pi. */
	public var angle(get, never):Float;

	function get_angle():Float {
		throw new NotImplementedException();
	}

	/** Returns the rotation as a matrix.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix3D):Matrix3D {
		throw new NotImplementedException();
	}
}
