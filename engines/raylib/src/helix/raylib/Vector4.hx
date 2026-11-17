package helix.raylib;

/** Represents raylib's `Vector4`: four components. It is helix-math's `Vector4`, so it has that type's operations too, each taking an
	out to fill. A `Quaternion` is a type of its own.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
typedef Vector4 = helix.math.Vector4;
