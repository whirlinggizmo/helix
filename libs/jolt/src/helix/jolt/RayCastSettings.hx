package helix.jolt;

/** Represents how a ray cast treats faces and solids. */
class RayCastSettings {
	/** Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`. */
	public var mBackFaceModeTriangles:EBackFaceMode = EBackFaceMode_IgnoreBackFaces;

	/** Gets or sets whether a convex shape is hit from inside, at its far side. Defaults to `EBackFaceMode_IgnoreBackFaces`. */
	public var mBackFaceModeConvex:EBackFaceMode = EBackFaceMode_IgnoreBackFaces;

	/** Gets or sets a value indicating whether a ray starting inside a convex shape hits it at its origin. Defaults to true. */
	public var mTreatConvexAsSolid:Bool = true;

	/** Creates the default settings. */
	public function new() {}

	/** Sets both back face modes.

		@param inBackFaceMode  The mode. */
	public function SetBackFaceMode(inBackFaceMode:EBackFaceMode):Void {
		throw "not built yet";
	}
}
