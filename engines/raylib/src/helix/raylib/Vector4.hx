package helix.raylib;

/** Represents raylib's `Vector4`: four components. An alias of helix-math's `Vector4`. Operations on a `Vector4` accept an optional
	`out` argument that receives the result. `Quaternion` is a separate type.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
typedef Vector4 = helix.math.Vector4;
