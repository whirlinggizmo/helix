package helix.jolt;

/** Represents what a shape is built from: a hull's points, a mesh's triangles, a compound's parts. `Create` builds the shape.

	```haxe
	var hull = new ConvexHullShapeSettings();
	hull.mPoints = points;
	var result = hull.Create();
	if (result.HasError())
		trace(result.GetError());
	var shape = result.Get();
	``` */
class ShapeSettings {
	/** Gets or sets the number the shape keeps for the program. Defaults to 0. */
	public var mUserData:Int = 0;

	function new() {}

	/** Builds the shape.

		@return  The result: the shape, or why it couldn't be built. */
	public function Create():ShapeResult {
		throw "not built yet";
	}
}
