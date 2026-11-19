package helix.raylib;

/** Represents raylib's `Quaternion`: a rotation in three dimensions. An alias of helix-math's `Quaternion`. Operations on a
	`Quaternion` accept an optional `out` argument that receives the result.

	A `Vector4` isn't one, as it is in C. Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
typedef Quaternion = helix.math.Quaternion;
