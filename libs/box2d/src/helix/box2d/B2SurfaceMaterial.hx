package helix.box2d;

/** The surface properties of a shape, which is the 2D boundary. A chain can have one for each segment. */
class B2SurfaceMaterial {
	/** The Coulomb (dry) friction coefficient, usually 0 to 1. Defaults to 0.6. */
	public var friction:Float;

	/** The coefficient of restitution (bounce), usually 0 to 1. Defaults to 0. */
	public var restitution:Float;

	/** The rolling resistance, usually 0 to 1. Defaults to 0. */
	public var rollingResistance:Float;

	/** The speed of the surface along its tangent, in meters per second, as on a conveyor belt. Defaults to 0. */
	public var tangentSpeed:Float;

	/** A number the program chooses to identify the material. It is passed to the friction and restitution callbacks and returned with query results, and Box2D doesn't use it otherwise. Defaults to 0. */
	public var userMaterialId:haxe.Int64;

	/** The color to debug draw the shape with, as 0xRRGGBB. Defaults to 0, which draws the usual color. */
	public var customColor:Int;

	/** Creates one holding Box2D's defaults, as `b2DefaultSurfaceMaterial()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2SurfaceMaterial(this);
		helix.box2d.internal.Calls.b2DefaultSurfaceMaterial(this);
	}
}
