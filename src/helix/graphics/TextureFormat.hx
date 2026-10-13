package helix.graphics;

/** What a texture's texels are: plain RGBA8, or a GPU's compressed format (4x4 blocks of 16 bytes each), which only some GPUs sample
	(IGraphics.canSample). Colors are sRGB values either way, as the shaders treat them. */
enum abstract TextureFormat(Int) to Int {
	/** 4 bytes a texel, rows top first. */
	var Rgba8 = 0;

	/** BC7 (BPTC): desktops. */
	var Bc7 = 1;

	/** ASTC 4x4: phones. */
	var Astc4x4 = 2;

	/** ETC2 RGBA8 (with EAC alpha): older phones. */
	var Etc2Rgba8 = 3;

	/** The bytes of a level width x height. */
	public function levelBytes(width:Int, height:Int):Int
		return this == Rgba8 ? width * height * 4 : Std.int((width + 3) / 4) * Std.int((height + 3) / 4) * 16;
}
