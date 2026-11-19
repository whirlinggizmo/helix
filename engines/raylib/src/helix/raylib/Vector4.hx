package helix.raylib;

/** Represents raylib's `Vector4`: four components. An alias of helix-math's `Vector4`. Operations on a `Vector4` accept an optional
	`out` argument that receives the result. `Quaternion` is a separate type.

	_Note that a `Vector4` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Vector4`._ */
typedef Vector4 = helix.math.Vector4;
