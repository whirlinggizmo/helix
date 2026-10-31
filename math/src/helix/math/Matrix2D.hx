package helix.math;

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
		makeIdentity();
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
		this.a = real(a);
		this.b = real(b);
		this.c = real(c);
		this.d = real(d);
		this.tx = real(tx);
		this.ty = real(ty);
		return this;
	}

	/** Sets this matrix to another's numbers.

		@param other  The matrix to copy.
		@return  This matrix. */
	public function copyFrom(other:Matrix2D):Matrix2D {
		return set(other.a, other.b, other.c, other.d, other.tx, other.ty);
	}

	/** Makes this the identity.

		@return  This matrix. */
	public function makeIdentity():Matrix2D {
		return set(1, 0, 0, 1, 0, 0);
	}

	/** Returns a matrix that moves points.

		@param x  How far along x.
		@param y  How far along y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		return result(out, 1, 0, 0, 1, x, y);
	}

	/** Returns a matrix that scales points from the origin.

		@param x  The scale along x.
		@param y  The scale along y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		return result(out, x, 0, 0, y, 0, 0);
	}

	/** Returns a matrix that turns points around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function fromRotation(radians:Float, ?out:Matrix2D):Matrix2D {
		var cos = Trig.cos(radians), sin = Trig.sin(radians);
		return result(out, cos, sin, -sin, cos, 0, 0);
	}

	/** Returns one matrix followed by another.

		Either may be the out.
		@param first  The matrix applied first.
		@param second  The matrix applied after it.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public static function compose(first:Matrix2D, second:Matrix2D, ?out:Matrix2D):Matrix2D {
		var a = real(first.a),
			b = real(first.b),
			c = real(first.c),
			d = real(first.d),
			tx = real(first.tx),
			ty = real(first.ty);
		var sa = second.a, sb = second.b, sc = second.c, sd = second.d;
		return result(out, a * sa
			+ b * sc, a * sb
			+ b * sd, c * sa
			+ d * sc, c * sb
			+ d * sd, tx * sa
			+ ty * sc
			+ second.tx, tx * sb
			+ ty * sd
			+ second.ty);
	}

	/** Returns this matrix followed by another.

		@param other  The matrix applied after this one.
		@param out  Optional. The matrix to write into, which may be this one or other; a new one when omitted.
		@return  The matrix. */
	public function append(other:Matrix2D, ?out:Matrix2D):Matrix2D {
		return compose(this, other, out);
	}

	/** Returns another matrix followed by this one.

		@param other  The matrix applied before this one.
		@param out  Optional. The matrix to write into, which may be this one or other; a new one when omitted.
		@return  The matrix. */
	public function prepend(other:Matrix2D, ?out:Matrix2D):Matrix2D {
		return compose(other, this, out);
	}

	/** Returns this matrix followed by a move.

		@param x  How far along x.
		@param y  How far along y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		return result(out, a, b, c, d, tx + x, ty + y);
	}

	/** Returns this matrix followed by a scale from the origin.

		@param x  The scale along x.
		@param y  The scale along y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D {
		var a = real(this.a),
			b = real(this.b),
			c = real(this.c),
			d = real(this.d),
			tx = real(this.tx),
			ty = real(this.ty);
		return result(out, a * x, b * y, c * x, d * y, tx * x, ty * y);
	}

	/** Returns this matrix followed by a turn around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The matrix. */
	public function appendRotation(radians:Float, ?out:Matrix2D):Matrix2D {
		var cos = Trig.cos(radians), sin = Trig.sin(radians);
		var a = real(this.a),
			b = real(this.b),
			c = real(this.c),
			d = real(this.d),
			tx = real(this.tx),
			ty = real(this.ty);
		return result(out, a * cos
			- b * sin, a * sin
			+ b * cos, c * cos
			- d * sin, c * sin
			+ d * cos, tx * cos
			- ty * sin, tx * sin
			+ ty * cos);
	}

	/** Returns the matrix that undoes this one.

		@param out  Optional. The matrix to write into, which may be this one; a new one when omitted.
		@return  The inverse, or null when there is none (a matrix that flattens points onto a line), the out unchanged. */
	public function invert(?out:Matrix2D):Null<Matrix2D> {
		var a = real(this.a),
			b = real(this.b),
			c = real(this.c),
			d = real(this.d),
			tx = real(this.tx),
			ty = real(this.ty);
		var determinant = a * d - b * c;
		if (determinant == 0)
			return null;
		var inverse = 1 / determinant;
		return result(out, d * inverse, -b * inverse, -c * inverse, a * inverse, (c * ty - d * tx) * inverse, (b * tx - a * ty) * inverse);
	}

	/** Returns a point moved by this matrix.

		@param x  The point's x.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point. */
	public function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D {
		var x = real(x), y = real(y);
		var px = a * x + c * y + tx, py = b * x + d * y + ty;
		return out == null ? new Vector2D(px, py) : out.set(px, py);
	}

	/** Returns a direction turned and scaled by this matrix, its translation ignored.

		@param x  The direction's x.
		@param y  The direction's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function transformDirection(x:Float, y:Float, ?out:Vector2D):Vector2D {
		var x = real(x), y = real(y);
		var px = a * x + c * y, py = b * x + d * y;
		return out == null ? new Vector2D(px, py) : out.set(px, py);
	}

	/** Returns the matrix as a 4 x 4 one acting on x and y alone, as a shader takes a 2D view.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix3D(?out:Matrix3D):Matrix3D {
		if (out == null)
			out = new Matrix3D();
		var v = out.values;
		v[0] = a;
		v[1] = b;
		v[2] = 0;
		v[3] = 0;
		v[4] = c;
		v[5] = d;
		v[6] = 0;
		v[7] = 0;
		v[8] = 0;
		v[9] = 0;
		v[10] = 1;
		v[11] = 0;
		v[12] = tx;
		v[13] = ty;
		v[14] = 0;
		v[15] = 1;
		return out;
	}

	// The out filled with a result its inputs were read for first: a new matrix when there is none.
	static inline function result(out:Null<Matrix2D>, a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Matrix2D {
		if (out == null)
			out = new Matrix2D();
		return out.set(a, b, c, d, tx, ty);
	}

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
