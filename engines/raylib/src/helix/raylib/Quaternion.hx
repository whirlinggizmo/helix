package helix.raylib;

/** Represents raylib's `Quaternion`: a rotation in three dimensions. An alias of helix-math's `Quaternion`. Operations on a
	`Quaternion` accept an optional `out` argument that receives the result.

	Unlike the C implementation of raylib, `Quaternion` and `Vector4` are separate types.

	_Note that a `Quaternion` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Quaternion`._ */
typedef Quaternion = helix.math.Quaternion;
