package helix.platform;

/** Specifies how a texture's mipmaps are sampled when it is drawn smaller than its size.

	A texture without mipmaps reads its top level whatever this is. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract MipmapFilter(Int) to Int {
	/** The mipmaps aren't read: the top level alone, filtered as the sampling's filter says. */
	var None = 0;

	/** The mipmap nearest the drawn size, filtered as the sampling's filter says. */
	var Nearest = 1;

	/** The two mipmaps nearest the drawn size, each filtered as the sampling's filter says, blended, so a texture shrinks without
		shimmering or a seam between levels. */
	var Linear = 2;
}
