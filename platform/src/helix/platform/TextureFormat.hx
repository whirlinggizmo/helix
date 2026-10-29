package helix.platform;

/** Specifies the format of a texture's texels.

	The 8-bit and compressed formats hold sRGB values. The compressed formats store 4x4 blocks of 16 bytes, and only some GPUs sample them
	(`IGraphics.canSample`). */
@:build(helix.platform.macros.EnumNames.build())
enum abstract TextureFormat(Int) to Int {
	/** Four bytes a texel, rows top first. */
	var Rgba8 = 0;

	/** BC7 (BPTC), compressed: desktop GPUs. */
	var Bc7 = 1;

	/** ASTC 4x4, compressed: phone GPUs. */
	var Astc4x4 = 2;

	/** ETC2 RGBA8 with EAC alpha, compressed: older phone GPUs. */
	var Etc2Rgba8 = 3;

	/** RGBA half floats (IEEE binary16, little-endian), 8 bytes a texel, rows top first: linear light that can exceed 1. Filtered linearly
		where `IGraphics.canSample` is true for it. */
	var Rgba16f = 4;

	/** Returns the byte size of one level of a texture in this format.

		@param width  The level's width, in texels.
		@param height  The level's height, in texels; for a cube, one face's.
		@return  The level's size, in bytes. */
	public function levelBytes(width:Int, height:Int):Int
		return this == Rgba8 ? width * height * 4 : this == Rgba16f ? width * height * 8 : Std.int((width + 3) / 4) * Std.int((height + 3) / 4) * 16;
}
