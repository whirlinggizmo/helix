package helix.box2d;

import helix.math.Vector2;

/** Represents Box2D's `b2Vec2`: a point, a direction, a velocity or a size. Wraps helix-math's `Vector2`, whose fields and methods it
	also has, and is passed as a `Vector2` without a copy.

	Box2D reads each component as a 32-bit float, so a value set here is rounded to the nearest 32-bit float as Box2D reads it.

	_Note that a `B2Vec2` is assigned by reference, where C copies a `b2Vec2`. A function returning one accepts an optional `out` that
	receives the result, and makes a new `B2Vec2` when `out` is omitted._ */
@:forward
abstract B2Vec2(Vector2) from Vector2 to Vector2 {
	/** Creates a vector, as C's initializer `{ x, y }`.

		@param x  Optional. The x component; defaults to 0.
		@param y  Optional. The y component; defaults to 0. */
	public inline function new(x = 0., y = 0.) {
		this = new Vector2(x, y);
	}
}
