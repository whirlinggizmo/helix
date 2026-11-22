package helix.box2d;

/** Configures an explosion for `b2World_Explode`. The explosion considers each shape's geometry when it computes the impulse, and applies to circles, capsules and polygons. */
class B2ExplosionDef {
	/** The categories of shape the explosion affects. Defaults to all bits. */
	public var maskBits:haxe.Int64;

	/** The center of the explosion, in the world. Defaults to the origin. */
	public var position:B2Pos;

	/** The radius of the explosion, in length units. Defaults to 0. */
	public var radius:Float;

	/** The distance beyond the radius over which the impulse falls to zero, in length units. Defaults to 0. */
	public var falloff:Float;

	/** The impulse applied for each unit of the shape's perimeter that faces the explosion. Negative for an implosion. Defaults to 0. */
	public var impulsePerLength:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultExplosionDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2ExplosionDef(this);
		helix.box2d.internal.Calls.b2DefaultExplosionDef(this);
	}
}
