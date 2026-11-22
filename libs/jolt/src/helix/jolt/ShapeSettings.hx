package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

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

	/** Builds the shape in the module and returns its handle, or -1 with the reason in hj_shape_error. */
	function make():Int {
		return -1;
	}

	/** Builds the shape.

		@return  The result: the shape, or why it couldn't be built. */
	public function Create():ShapeResult {
		var handle = make();
		return new ShapeResult(handle, handle < 0 ? Io.bulkString(Hj.shapeError()) : "");
	}
}
