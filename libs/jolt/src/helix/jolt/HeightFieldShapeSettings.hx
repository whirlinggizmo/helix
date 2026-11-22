package helix.jolt;

/** Represents what a height field is built from: a square grid of heights, for terrain. The grid lies along x and z, a sample's place
	being `mOffset + mScale * (x, height, z)`. */
class HeightFieldShapeSettings extends ShapeSettings {
	/** Gets or sets where the grid's first sample is, in meters. Defaults to (0, 0, 0). */
	public var mOffset:Vec3;

	/** Gets or sets the size of a step between samples along x and z, and the scale of a height along y. Defaults to (1, 1, 1). */
	public var mScale:Vec3;

	/** Gets or sets the number of samples along each side of the grid. */
	public var mSampleCount:Int = 0;

	/** Gets or sets the heights, row by row along x, `mSampleCount` squared of them. `HeightFieldShapeConstantValues.cNoCollisionValue`
		makes a hole. */
	public var mHeightSamples:Array<Float> = [];

	/** Gets or sets the size of a block of samples, 2 to 8. Defaults to 2. */
	public var mBlockSize:Int = 2;

	/** Gets or sets the bits a height is stored in, 1 to 8. Defaults to 8. */
	public var mBitsPerSample:Int = 8;

	/** Creates the settings with no samples. */
	public function new() {
		super();
		throw "not built yet";
	}
}
