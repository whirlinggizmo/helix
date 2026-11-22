package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

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
		mOffset = new Vec3();
		mScale = new Vec3(1, 1, 1);
	}

	override function make():Int {
		var count = mSampleCount * mSampleCount;
		var base = Io.bulk(count * 4);
		for (n in 0...count)
			Io.setBulkF(base, n, n < mHeightSamples.length ? mHeightSamples[n] : HeightFieldShapeConstantValues.cNoCollisionValue);
		Io.setF(0, mOffset.x);
		Io.setF(1, mOffset.y);
		Io.setF(2, mOffset.z);
		Io.setF(3, mScale.x);
		Io.setF(4, mScale.y);
		Io.setF(5, mScale.z);
		return Hj.shapeHeightField(mSampleCount, mBlockSize, mBitsPerSample, mUserData);
	}
}
