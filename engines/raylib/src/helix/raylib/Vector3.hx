package helix.raylib;

/** Represents raylib's `Vector3`: a point or a direction in three dimensions. An alias of helix-math's `Vector3`. Operations on a
	`Vector3` accept an optional `out` argument that receives the result.

	_Note that a `Vector3` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Vector3`._ */
typedef Vector3 = helix.math.Vector3;
