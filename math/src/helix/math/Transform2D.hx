package helix.math;

import haxe.exceptions.NotImplementedException;

/** Represents where an object is in 2 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

	It faces along its own +x, so a rotation of 0 faces +x and a positive one turns toward +y, clockwise on screen where y grows downward.
	Moving and turning are along and around its own axes unless a method says otherwise, so a sprite, a turret or a 2D camera is steered
	the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's
	(`Matrix2D.compose`). It uses `Trig`, so a transform comes out the same on every target.

	```haxe
	var ship = new Transform2D();
	ship.position.set(100, 50);
	ship.lookAt(mouseX, mouseY);
	ship.moveForward(speed * dt);
	var model = ship.toMatrix(scratch);
	``` */
class Transform2D {
	/** Gets the position, in its parent's units; the origin until changed. */
	public final position = new Vector2D();

	/** Gets or sets the rotation in radians; 0, facing +x, until set. */
	public var rotation = 0.;

	/** Gets the scale along its own axes; 1 on each until changed. */
	public final scale = new Vector2D(1, 1);

	/** Creates a transform at the origin, facing +x, at scale 1. */
	public function new() {
		throw new NotImplementedException();
	}

	/** Sets this transform to another's position, rotation and scale.

		@param other  The transform to copy.
		@return  This transform. */
	public function copyFrom(other:Transform2D):Transform2D {
		throw new NotImplementedException();
	}

	/** Puts it back at the origin, facing +x, at scale 1.

		@return  This transform. */
	public function makeIdentity():Transform2D {
		throw new NotImplementedException();
	}

	/** Returns the transform a matrix places, scales and turns by.

		A matrix that shears gives the nearest rotation and scale, the shear lost.
		@param matrix  The matrix.
		@param out  Optional. The transform to write into; a new one when omitted.
		@return  The transform. */
	public static function fromMatrix(matrix:Matrix2D, ?out:Transform2D):Transform2D {
		throw new NotImplementedException();
	}

	/** Returns the direction it faces, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeForward(?out:Vector2D):Vector2D {
		throw new NotImplementedException();
	}

	/** Returns its right, a quarter turn from forward toward +y, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeRight(?out:Vector2D):Vector2D {
		throw new NotImplementedException();
	}

	/** Moves it along the way it faces.

		@param distance  How far, in its parent's units; less than 0 moves it back.
		@return  This transform. */
	public function moveForward(distance:Float):Transform2D {
		throw new NotImplementedException();
	}

	/** Moves it to its right.

		@param distance  How far, in its parent's units; less than 0 moves it left.
		@return  This transform. */
	public function moveRight(distance:Float):Transform2D {
		throw new NotImplementedException();
	}

	/** Moves it toward a point or away from it, along the line between them.

		It stops short of the point rather than passing through it.
		@param x  The point's x.
		@param y  The point's y.
		@param distance  How far nearer, in its parent's units; less than 0 moves it away.
		@param nearest  Optional. The least distance it keeps from the point; defaults to 0.001.
		@return  This transform. */
	public function moveToward(x:Float, y:Float, distance:Float, nearest = .001):Transform2D {
		throw new NotImplementedException();
	}

	/** Turns it.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@return  This transform. */
	public function rotate(radians:Float):Transform2D {
		throw new NotImplementedException();
	}

	/** Turns it to face a point.

		A point at its position leaves it as it is.
		@param x  The point's x.
		@param y  The point's y.
		@return  This transform. */
	public function lookAt(x:Float, y:Float):Transform2D {
		throw new NotImplementedException();
	}

	/** Swings it around a point: its position and its rotation both, so whatever faced the point still does.

		@param x  The point's x.
		@param y  The point's y.
		@param radians  The swing; more than 0 swings it from +x toward +y.
		@return  This transform. */
	public function orbit(x:Float, y:Float, radians:Float):Transform2D {
		throw new NotImplementedException();
	}

	/** Returns a point in its own space put into its parent's: scaled, rotated, then moved.

		@param x  The point's x, in its own units.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in its parent's units. */
	public function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D {
		throw new NotImplementedException();
	}

	/** Returns the matrix that scales, rotates and then moves, to draw it with.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}
}
