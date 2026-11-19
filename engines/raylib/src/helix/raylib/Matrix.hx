package helix.raylib;

import helix.math.Matrix4;

/** Represents raylib's `Matrix`: 4 by 4, named by rows and stored by columns, as raylib's is. Wraps helix-math's `Matrix4` as raylib's
	`Matrix`. Operations on a `Matrix` accept an optional `out` argument that receives the result. A `Matrix` is passed as a `Matrix4`
	without a copy.

	`m0, m4, m8, m12` is the first row.

	`m0` to `m3` is the first column, stored first and sent to shaders first.

	_Note that a `Matrix` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Matrix`._ */
@:forward
abstract Matrix(Matrix4) from Matrix4 to Matrix4 {
	/** Gets or sets row 1, column 1. */
	public var m0(get, set):Float;

	/** Gets or sets row 1, column 2. */
	public var m4(get, set):Float;

	/** Gets or sets row 1, column 3. */
	public var m8(get, set):Float;

	/** Gets or sets row 1, column 4. */
	public var m12(get, set):Float;

	/** Gets or sets row 2, column 1. */
	public var m1(get, set):Float;

	/** Gets or sets row 2, column 2. */
	public var m5(get, set):Float;

	/** Gets or sets row 2, column 3. */
	public var m9(get, set):Float;

	/** Gets or sets row 2, column 4. */
	public var m13(get, set):Float;

	/** Gets or sets row 3, column 1. */
	public var m2(get, set):Float;

	/** Gets or sets row 3, column 2. */
	public var m6(get, set):Float;

	/** Gets or sets row 3, column 3. */
	public var m10(get, set):Float;

	/** Gets or sets row 3, column 4. */
	public var m14(get, set):Float;

	/** Gets or sets row 4, column 1. */
	public var m3(get, set):Float;

	/** Gets or sets row 4, column 2. */
	public var m7(get, set):Float;

	/** Gets or sets row 4, column 3. */
	public var m11(get, set):Float;

	/** Gets or sets row 4, column 4. */
	public var m15(get, set):Float;

	/** Creates a matrix from its 16 numbers, row by row. Each defaults to 0.

		@param m0  Row 1, column 1.
		@param m4  Row 1, column 2.
		@param m8  Row 1, column 3.
		@param m12  Row 1, column 4.
		@param m1  Row 2, column 1.
		@param m5  Row 2, column 2.
		@param m9  Row 2, column 3.
		@param m13  Row 2, column 4.
		@param m2  Row 3, column 1.
		@param m6  Row 3, column 2.
		@param m10  Row 3, column 3.
		@param m14  Row 3, column 4.
		@param m3  Row 4, column 1.
		@param m7  Row 4, column 2.
		@param m11  Row 4, column 3.
		@param m15  Row 4, column 4. */
	public function new(m0 = 0., m4 = 0., m8 = 0., m12 = 0., m1 = 0., m5 = 0., m9 = 0., m13 = 0., m2 = 0., m6 = 0., m10 = 0., m14 = 0., m3 = 0., m7 = 0.,
			m11 = 0., m15 = 0.) {
		this = new Matrix4();
		this.m0 = m0;
		this.m1 = m1;
		this.m2 = m2;
		this.m3 = m3;
		this.m4 = m4;
		this.m5 = m5;
		this.m6 = m6;
		this.m7 = m7;
		this.m8 = m8;
		this.m9 = m9;
		this.m10 = m10;
		this.m11 = m11;
		this.m12 = m12;
		this.m13 = m13;
		this.m14 = m14;
		this.m15 = m15;
	}

	/** Creates a matrix from an object in braces, where a matrix is expected: `var m:Matrix = {m0: 1, m5: 1, m10: 1, m15: 1};`. A
		number left out is 0.

		@param matrix  The numbers, each named as a `Matrix`'s. */
	@:from public static function fromObject(matrix:{
		?m0:Float,
		?m4:Float,
		?m8:Float,
		?m12:Float,
		?m1:Float,
		?m5:Float,
		?m9:Float,
		?m13:Float,
		?m2:Float,
		?m6:Float,
		?m10:Float,
		?m14:Float,
		?m3:Float,
		?m7:Float,
		?m11:Float,
		?m15:Float
	}):Matrix {
		inline function number(value:Null<Float>):Float
			return value == null ? 0 : value;
		return new Matrix(number(matrix.m0), number(matrix.m4), number(matrix.m8), number(matrix.m12), number(matrix.m1), number(matrix.m5),
			number(matrix.m9), number(matrix.m13), number(matrix.m2), number(matrix.m6), number(matrix.m10), number(matrix.m14), number(matrix.m3),
			number(matrix.m7), number(matrix.m11), number(matrix.m15));
	}

	/** Returns a separate copy.

		@param out  Optional. The Matrix to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public inline function copy(?out:Matrix):Matrix
		return (out == null ? new Matrix4() : (out : Matrix4)).copyFrom(this);

	inline function get_m0():Float
		return this.m0;

	inline function get_m4():Float
		return this.m4;

	inline function get_m8():Float
		return this.m8;

	inline function get_m12():Float
		return this.m12;

	inline function get_m1():Float
		return this.m1;

	inline function get_m5():Float
		return this.m5;

	inline function get_m9():Float
		return this.m9;

	inline function get_m13():Float
		return this.m13;

	inline function get_m2():Float
		return this.m2;

	inline function get_m6():Float
		return this.m6;

	inline function get_m10():Float
		return this.m10;

	inline function get_m14():Float
		return this.m14;

	inline function get_m3():Float
		return this.m3;

	inline function get_m7():Float
		return this.m7;

	inline function get_m11():Float
		return this.m11;

	inline function get_m15():Float
		return this.m15;

	inline function set_m0(value:Float):Float
		return this.m0 = value;

	inline function set_m4(value:Float):Float
		return this.m4 = value;

	inline function set_m8(value:Float):Float
		return this.m8 = value;

	inline function set_m12(value:Float):Float
		return this.m12 = value;

	inline function set_m1(value:Float):Float
		return this.m1 = value;

	inline function set_m5(value:Float):Float
		return this.m5 = value;

	inline function set_m9(value:Float):Float
		return this.m9 = value;

	inline function set_m13(value:Float):Float
		return this.m13 = value;

	inline function set_m2(value:Float):Float
		return this.m2 = value;

	inline function set_m6(value:Float):Float
		return this.m6 = value;

	inline function set_m10(value:Float):Float
		return this.m10 = value;

	inline function set_m14(value:Float):Float
		return this.m14 = value;

	inline function set_m3(value:Float):Float
		return this.m3 = value;

	inline function set_m7(value:Float):Float
		return this.m7 = value;

	inline function set_m11(value:Float):Float
		return this.m11 = value;

	inline function set_m15(value:Float):Float
		return this.m15 = value;
}
