package helix.platform;

/** Specifies how a texture is filtered when drawn at a size other than its own. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Filter(Int) to Int {
	/** The nearest texel: sharp, for pixel art. */
	var Nearest = 0;

	/** Neighboring texels blended: smooth, and through the texture's mipmaps when it has them, so it shrinks without shimmering. */
	var Linear = 1;
}
