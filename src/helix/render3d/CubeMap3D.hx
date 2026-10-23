package helix.render3d;

import haxe.ds.Vector;

/** A cubemap of linear RGB floats with its mips: mips[m] holds the six faces of (size >> m) squared texels each, three floats a texel. */
class CubeMap3D {
	/** Its face size at mip 0. */
	public final size:Int;

	/** How many mips. */
	public final mipCount:Int;

	/** Each mip's texels, zero to start. */
	public final mips:Array<Vector<Float>> = [];

	/** An all-black cube of size with mipCount mips. */
	public function new(size:Int, mipCount:Int) {
		this.size = size;
		this.mipCount = mipCount;
		for (m in 0...mipCount) {
			var s = size >> m > 0 ? size >> m : 1,
				data = new Vector<Float>(6 * s * s * 3);
			for (i in 0...data.length)
				data[i] = 0;
			mips.push(data);
		}
	}
}
