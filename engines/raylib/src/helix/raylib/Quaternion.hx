package helix.raylib;

/** Represents raylib's `Quaternion`: a rotation in three dimensions. It is helix-math's `Quaternion`, so it has that type's operations
	too, each taking an out to fill. A new one is the identity.

	A `Vector4` isn't one, as it is in C. Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
typedef Quaternion = helix.math.Quaternion;
