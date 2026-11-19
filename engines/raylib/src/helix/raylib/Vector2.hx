package helix.raylib;

/** Represents raylib's `Vector2`: a point or a direction in two dimensions. An alias of helix-math's `Vector2`. Operations on a
	`Vector2` accept an optional `out` argument that receives the result.

	_Note that a `Vector2` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Vector2`._ */
typedef Vector2 = helix.math.Vector2;
