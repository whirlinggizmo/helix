package helix.jolt;

/** Represents how a shape overlap is tested. */
class CollideShapeSettings {
	/** Gets or sets the distance apart at which shapes still count as touching, in meters. Defaults to 0. */
	public var mMaxSeparationDistance:Float = 0;

	/** Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`. */
	public var mBackFaceMode:EBackFaceMode = EBackFaceMode_IgnoreBackFaces;

	/** Creates the default settings. */
	public function new() {}
}
