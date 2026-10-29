package helix.platform;

/** Specifies how a pipeline's colors are combined with the colors already in the target.

	Colors use straight alpha, not premultiplied alpha. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract BlendMode(Int) to Int {
	/** The color replaces the target's. */
	var Opaque = 0;

	/** The color is blended over the target's by its alpha. */
	var Alpha = 1;

	/** The color, multiplied by its alpha, is added to the target's. It suits light, fire and glows. */
	var Additive = 2;
}
