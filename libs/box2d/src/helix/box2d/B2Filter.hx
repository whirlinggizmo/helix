package helix.box2d;

/** Decides which shapes collide. It applies to shape against shape and to shapes found by a query such as `b2World_CastRay`. */
class B2Filter {
	/** The categories the shape belongs to, usually one bit for each kind of object in the program, such as static, dynamic or player. Defaults to 1. */
	public var categoryBits:haxe.Int64;

	/** The categories the shape collides with. A player might collide with static objects and other players only. Defaults to all bits. */
	public var maskBits:haxe.Int64;

	/** A group of shapes that never collide (negative) or always collide (positive), whatever the mask bits say. 0 has no effect. A ragdoll whose shapes share one unique negative index does not collide with itself. Defaults to 0. */
	public var groupIndex:Int;

	/** Creates one holding Box2D's defaults, as `b2DefaultFilter()` returns. */
	public function new() {
		throw "not built yet";
	}
}
