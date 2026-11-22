package helix.jolt;

/** Represents how a shape cast treats faces. */
class ShapeCastSettings {
	/** Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`. */
	public var mBackFaceModeTriangles:EBackFaceMode = EBackFaceMode_IgnoreBackFaces;

	/** Gets or sets whether a convex shape is hit from inside. Defaults to `EBackFaceMode_IgnoreBackFaces`. */
	public var mBackFaceModeConvex:EBackFaceMode = EBackFaceMode_IgnoreBackFaces;

	/** Gets or sets a value indicating whether a shape that starts overlapping returns its deepest point. Defaults to false. */
	public var mReturnDeepestPoint:Bool = false;

	/** Creates the default settings. */
	public function new() {}
}
