package helix.jolt;

/** Specifies the directions a body may move and turn in, as bits combined with `|`. */
enum abstract EAllowedDOFs(Int) {
	/** Moving along x. */
	var EAllowedDOFs_TranslationX = 1;

	/** Moving along y. */
	var EAllowedDOFs_TranslationY = 2;

	/** Moving along z. */
	var EAllowedDOFs_TranslationZ = 4;

	/** Turning about x. */
	var EAllowedDOFs_RotationX = 8;

	/** Turning about y. */
	var EAllowedDOFs_RotationY = 16;

	/** Turning about z. */
	var EAllowedDOFs_RotationZ = 32;

	/** Moving along x and y and turning about z: a body in 2D. */
	var EAllowedDOFs_Plane2D = 35;

	/** Moving and turning freely. */
	var EAllowedDOFs_All = 63;

	/** Returns the directions of both values.

		@param a  One set of directions.
		@param b  The other set.
		@return  The directions in either. */
	@:op(A | B) static function or(a:EAllowedDOFs, b:EAllowedDOFs):EAllowedDOFs;
}
