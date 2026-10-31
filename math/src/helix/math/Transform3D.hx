package helix.math;

import haxe.exceptions.NotImplementedException;

/** Represents where an object is in 3 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

	Its own axes are its rotation's: -z is forward, +x right and +y up, as a camera looks down -z. Moving and turning are along and
	around those axes unless a method says otherwise, so a ship, a turret or a camera is steered the same way. The matrix that draws it
	scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix3D.compose`). It uses
	`Trig`, so a transform comes out the same on every target.

	```haxe
	var ship = new Transform3D();
	ship.position.set(0, 0, 10);
	ship.lookAt(0, 0, 0);
	ship.yaw(turnSpeed * dt);
	ship.moveForward(speed * dt);
	var model = ship.toMatrix(scratch);
	``` */
class Transform3D {
	/** Gets the position, in its parent's units; the origin until changed. */
	public final position = new Vector3D();

	/** Gets the rotation; the identity until changed. */
	public final rotation = new Quaternion3D();

	/** Gets the scale along its own axes; 1 on each until changed. */
	public final scale = new Vector3D(1, 1, 1);

	/** Creates a transform at the origin, facing -z, at scale 1. */
	public function new() {
		throw new NotImplementedException();
	}

	/** Sets this transform to another's position, rotation and scale.

		@param other  The transform to copy.
		@return  This transform. */
	public function copyFrom(other:Transform3D):Transform3D {
		throw new NotImplementedException();
	}

	/** Puts it back at the origin, facing -z, at scale 1.

		@return  This transform. */
	public function makeIdentity():Transform3D {
		throw new NotImplementedException();
	}

	/** Returns the transform of a matrix: its position, rotation and scale.

		A matrix that shears gives the nearest rotation and scale, the shear lost.
		@param matrix  The matrix.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public static function fromMatrix(matrix:Matrix3D, ?out:Transform3D):Transform3D {
		throw new NotImplementedException();
	}

	/** Returns the direction it faces, its -z, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeForward(?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Returns its right, its +x, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeRight(?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Returns its up, its +y, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeUp(?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Moves it along the way it faces.

		@param distance  How far, in its parent's units; less than 0 moves it back.
		@param inWorldPlane  Optional. True to move along the ground, its forward with the height taken out, as a walking camera does;
			defaults to false.
		@return  This transform. */
	public function moveForward(distance:Float, inWorldPlane = false):Transform3D {
		throw new NotImplementedException();
	}

	/** Moves it to its right.

		@param distance  How far, in its parent's units; less than 0 moves it left.
		@param inWorldPlane  Optional. True to move along the ground, its right with the height taken out; defaults to false.
		@return  This transform. */
	public function moveRight(distance:Float, inWorldPlane = false):Transform3D {
		throw new NotImplementedException();
	}

	/** Moves it along its up.

		@param distance  How far, in its parent's units; less than 0 moves it down.
		@return  This transform. */
	public function moveUp(distance:Float):Transform3D {
		throw new NotImplementedException();
	}

	/** Moves it toward a point or away from it, along the line between them, as a camera zooms on what it orbits.

		It stops short of the point rather than passing through it.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param distance  How far nearer, in its parent's units; less than 0 moves it away.
		@param nearest  Optional. The least distance it keeps from the point; defaults to 0.001.
		@return  This transform. */
	public function moveToward(x:Float, y:Float, z:Float, distance:Float, nearest = .001):Transform3D {
		throw new NotImplementedException();
	}

	/** Turns it left or right, around its own up.

		@param radians  The angle; more than 0 turns it left.
		@return  This transform. */
	public function yaw(radians:Float):Transform3D {
		throw new NotImplementedException();
	}

	/** Turns it to face higher or lower, around its own right.

		@param radians  The angle; more than 0 faces it higher.
		@param lock  Optional. True to stop short of straight up and down, as a camera's look stops, so it never turns over; defaults to
			false.
		@return  This transform. */
	public function pitch(radians:Float, lock = false):Transform3D {
		throw new NotImplementedException();
	}

	/** Tilts it around the way it faces.

		@param radians  The angle; more than 0 tilts it to the right.
		@return  This transform. */
	public function roll(radians:Float):Transform3D {
		throw new NotImplementedException();
	}

	/** Turns it to face a point.

		A point at its position leaves it as it is.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param upX  Optional. Which way up it is kept, x; defaults to 0.
		@param upY  Optional. Up's y; defaults to 1.
		@param upZ  Optional. Up's z; defaults to 0.
		@return  This transform. */
	public function lookAt(x:Float, y:Float, z:Float, upX = 0., upY = 1., upZ = 0.):Transform3D {
		throw new NotImplementedException();
	}

	/** Swings it around a point: its position and its rotation both, so whatever faced the point still does, as an orbiting camera
		moves.

		The yaw is around the world's up; the pitch around its own right.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param yaw  The swing left or right, in radians; more than 0 swings it to the left.
		@param pitch  The swing up or down, in radians; more than 0 swings it upward.
		@param lock  Optional. True to stop short of straight above and below the point, so it never turns over; defaults to false.
		@return  This transform. */
	public function orbit(x:Float, y:Float, z:Float, yaw:Float, pitch:Float, lock = false):Transform3D {
		throw new NotImplementedException();
	}

	/** Returns a point in its own space put into its parent's: scaled, rotated, then moved.

		@param x  The point's x, in its own units.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in its parent's units. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D {
		throw new NotImplementedException();
	}

	/** Returns the matrix that scales, rotates and then moves, to draw it with.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix3D):Matrix3D {
		throw new NotImplementedException();
	}
}
