package helix.platform;

/** Specifies how a texture is sampled outside the 0 to 1 range of its coordinates. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Wrap(Int) to Int {
	/** The edge texel continues. */
	var Clamp = 0;

	/** The texture tiles. */
	var Repeat = 1;

	/** The texture tiles, every other copy mirrored. */
	var Mirror = 2;
}
