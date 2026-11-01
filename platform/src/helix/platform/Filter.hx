package helix.platform;

/** Specifies how a texture is filtered when drawn at a size other than its own. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Filter(Int) to Int {
	/** The nearest texel is used. It looks sharp and suits pixel art. */
	var Nearest = 0;

	/** Neighboring texels are blended, which looks smooth. */
	var Linear = 1;
}
