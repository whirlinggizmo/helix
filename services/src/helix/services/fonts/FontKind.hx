package helix.services.fonts;

/** Specifies what a font's glyphs hold, as `Fonts.load` and `Fonts.rasterize` rasterize them. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract FontKind(Int) {
	/** Antialiased coverage: each texel how much of it the glyph covers. */
	var Coverage = 0;

	/** Coverage made hard-edged: each texel covered or not, for pixel fonts drawn at their own size. */
	var Bitmap = 1;

	/** Signed distances to the outline, sharp at any size through a distance-field shader: 128 on the outline, 64 a texel, with 4
		texels of padding around each glyph. */
	var Distance = 2;
}
