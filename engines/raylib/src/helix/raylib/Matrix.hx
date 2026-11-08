package helix.raylib;

/** Represents raylib's `Matrix`: 4 by 4, named by rows and stored by columns, as raylib's is.

	`m0, m4, m8, m12` is the first row.

	`m0` to `m3` is the first column, stored first and sent to shaders first.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Matrix {
	/** Gets or sets row 1, column 1. */
	public var m0:Float;

	/** Gets or sets row 1, column 2. */
	public var m4:Float;

	/** Gets or sets row 1, column 3. */
	public var m8:Float;

	/** Gets or sets row 1, column 4. */
	public var m12:Float;

	/** Gets or sets row 2, column 1. */
	public var m1:Float;

	/** Gets or sets row 2, column 2. */
	public var m5:Float;

	/** Gets or sets row 2, column 3. */
	public var m9:Float;

	/** Gets or sets row 2, column 4. */
	public var m13:Float;

	/** Gets or sets row 3, column 1. */
	public var m2:Float;

	/** Gets or sets row 3, column 2. */
	public var m6:Float;

	/** Gets or sets row 3, column 3. */
	public var m10:Float;

	/** Gets or sets row 3, column 4. */
	public var m14:Float;

	/** Gets or sets row 4, column 1. */
	public var m3:Float;

	/** Gets or sets row 4, column 2. */
	public var m7:Float;

	/** Gets or sets row 4, column 3. */
	public var m11:Float;

	/** Gets or sets row 4, column 4. */
	public var m15:Float;

	/** Creates a matrix.

		@param m0  Gets or sets row 1, column 1.
		@param m4  Gets or sets row 1, column 2.
		@param m8  Gets or sets row 1, column 3.
		@param m12  Gets or sets row 1, column 4.
		@param m1  Gets or sets row 2, column 1.
		@param m5  Gets or sets row 2, column 2.
		@param m9  Gets or sets row 2, column 3.
		@param m13  Gets or sets row 2, column 4.
		@param m2  Gets or sets row 3, column 1.
		@param m6  Gets or sets row 3, column 2.
		@param m10  Gets or sets row 3, column 3.
		@param m14  Gets or sets row 3, column 4.
		@param m3  Gets or sets row 4, column 1.
		@param m7  Gets or sets row 4, column 2.
		@param m11  Gets or sets row 4, column 3.
		@param m15  Gets or sets row 4, column 4. */
	public function new(m0:Float = 0, m4:Float = 0, m8:Float = 0, m12:Float = 0, m1:Float = 0, m5:Float = 0, m9:Float = 0, m13:Float = 0, m2:Float = 0,
			m6:Float = 0, m10:Float = 0, m14:Float = 0, m3:Float = 0, m7:Float = 0, m11:Float = 0, m15:Float = 0) {
		this.m0 = m0;
		this.m4 = m4;
		this.m8 = m8;
		this.m12 = m12;
		this.m1 = m1;
		this.m5 = m5;
		this.m9 = m9;
		this.m13 = m13;
		this.m2 = m2;
		this.m6 = m6;
		this.m10 = m10;
		this.m14 = m14;
		this.m3 = m3;
		this.m7 = m7;
		this.m11 = m11;
		this.m15 = m15;
	}

	/** Returns a separate copy.

		@param out  Optional. The Matrix to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Matrix):Matrix {
		if (out == null)
			return new Matrix(m0, m4, m8, m12, m1, m5, m9, m13, m2, m6, m10, m14, m3, m7, m11, m15);
		out.m0 = m0;
		out.m4 = m4;
		out.m8 = m8;
		out.m12 = m12;
		out.m1 = m1;
		out.m5 = m5;
		out.m9 = m9;
		out.m13 = m13;
		out.m2 = m2;
		out.m6 = m6;
		out.m10 = m10;
		out.m14 = m14;
		out.m3 = m3;
		out.m7 = m7;
		out.m11 = m11;
		out.m15 = m15;
		return out;
	}
}
