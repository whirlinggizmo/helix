package helix.services.fonts;

/** Represents how `Fonts` makes a font's atlas. */
@:structInit
class FontsOptions {
	/** Gets the empty texels around each glyph on the atlas, so sampling one doesn't reach its neighbour. Defaults to 1. */
	public final padding:Int = 1;

	/** Gets how glyphs are placed on the atlas. Defaults to `Skyline`. */
	public final packing:FontPacking = Skyline;
}
