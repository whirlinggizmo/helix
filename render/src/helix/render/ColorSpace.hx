package helix.render;

/** Specifies how a texture's texels are read by helix-render's own shaders: as sRGB colors, decoded to linear light, or as linear values. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract ColorSpace(Int) {
	/** As the slot it is used in: sRGB in a color slot (base color, emissive, a sprite's or a glyph's texture), linear in a data slot
		(normal, metallic-roughness, occlusion, alpha, light). */
	var Auto = 0;

	/** sRGB colors, decoded to linear light wherever it is used. */
	var Srgb = 1;

	/** Linear values, read as they are wherever it is used. */
	var Linear = 2;
}
