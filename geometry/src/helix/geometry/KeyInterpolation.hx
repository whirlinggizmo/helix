package helix.geometry;

/** Specifies how an animation's track goes from one key to the next. */
enum KeyInterpolation {
	/** Holds each key until the next. */
	Step;

	/** Moves straight between keys; a rotation along the shorter arc (slerp). */
	Linear;

	/** Along a cubic curve through the keys, by each key's in and out tangents (glTF's CUBICSPLINE); a rotation made length 1 after. */
	CubicSpline;
}
