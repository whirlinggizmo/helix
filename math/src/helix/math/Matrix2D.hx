package helix.math;

import haxe.exceptions.NotImplementedException;

/** Represents a 2D affine matrix: moving, turning, scaling and shearing points in 2 dimensions.

	It is the 3 x 3 matrix whose last row is 0, 0, 1, kept as its six other numbers as a canvas's `setTransform` and Flash's `Matrix` keep
	them: a point (x, y) goes to (a x + c y + tx, b x + d y + ty). Its operations follow helix-math's out rule: each writes into an
	optional out, last, and returns it; omitted, it makes a new matrix; given the matrix itself, it works in place. Rotations use `Trig`,
	so a matrix comes out the same on every target. Angles are radians, a positive one turning from +x toward +y, clockwise on screen
	where y grows downward.

	```haxe
	var model = Matrix2D.fromScale(2, 2);
	model.appendRotation(angle, model).appendTranslation(x, y, model);
	var onScreen = model.transformPoint(0, 0);
	``` */
class Matrix2D {
	/** Gets or sets how x scales x: the top left. */
	public var a:Float;

	/** Gets or sets how x moves y. */
	public var b:Float;

	/** Gets or sets how y moves x. */
	public var c:Float;

	/** Gets or sets how y scales y. */
	public var d:Float;

	/** Gets or sets the translation's x. */
	public var tx:Float;

	/** Gets or sets the translation's y. */
	public var ty:Float;

	/** Creates the identity matrix. */
	public function new() {
		throw new NotImplementedException();
	}

	/** Sets the six numbers.

		@param a  How x scales x.
		@param b  How x moves y.
		@param c  How y moves x.
		@param d  How y scales y.
		@param tx  The translation's x.
		@param ty  The translation's y.
		@return  This matrix. */
	public function set(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Matrix2D {
		throw new NotImplementedException();
	}

	/** Sets this matrix to another's numbers.

		@param other  The matrix to copy.
		@return  This matrix. */
	public function copyFrom(other:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Makes this the identity.

		@return  This matrix. */
	public function makeIdentity():Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns a matrix that moves points.

		@param x  How far along x.
		@param y  How far along y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns a matrix that scales points from the origin.

		@param x  The scale along x.
		@param y  The scale along y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns a matrix that turns points around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromRotation(radians:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns one matrix followed by another.

		Either may be the out.
		@param first  The matrix applied first.
		@param second  The matrix applied after it.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function compose(first:Matrix2D, second:Matrix2D, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns this matrix followed by another.

		@param other  The matrix applied after this one.
		@param out  Optional. The matrix to write into, which may be this one or other; a new one when omitted.
		@return  The matrix. */
	public function append(other:Matrix2D, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns another matrix followed by this one.

		@param other  The matrix applied before this one.
		@param out  Optional. The matrix to write into, which may be this one or other; a new one when omitted.
		@return  The matrix. */
	public function prepend(other:Matrix2D, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns this matrix followed by a move.

		@param x  How far along x.
		@param y  How far along y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns this matrix followed by a scale from the origin.

		@param x  The scale along x.
		@param y  The scale along y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns this matrix followed by a turn around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendRotation(radians:Float, ?out:Matrix2D):Matrix2D {
		throw new NotImplementedException();
	}

	/** Returns the matrix that undoes this one.

		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The inverse, or null when there is none (a matrix that flattens points onto a line), the out unchanged. */
	public function invert(?out:Matrix2D):Null<Matrix2D> {
		throw new NotImplementedException();
	}

	/** Returns a point moved by this matrix.

		@param x  The point's x.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point. */
	public function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D {
		throw new NotImplementedException();
	}

	/** Returns a direction turned and scaled by this matrix, its translation ignored.

		@param x  The direction's x.
		@param y  The direction's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function transformDirection(x:Float, y:Float, ?out:Vector2D):Vector2D {
		throw new NotImplementedException();
	}

	/** Returns the matrix as a 4 x 4 one acting on x and y alone, as a shader takes a 2D view.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix3D(?out:Matrix3D):Matrix3D {
		throw new NotImplementedException();
	}
}
