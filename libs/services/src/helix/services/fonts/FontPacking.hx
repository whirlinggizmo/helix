package helix.services.fonts;

/** Specifies how `Fonts.load` places glyphs on the atlas. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract FontPacking(Int) {
	/** In rows, in the order asked for, each row a line's height. */
	var Rows = 0;

	/** As tightly as a skyline packs them, tallest first (helix-math's `RectPacker2D`). */
	var Skyline = 1;
}
