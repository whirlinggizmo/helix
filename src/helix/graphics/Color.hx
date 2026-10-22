package helix.graphics;

/** Colors as HeliX holds them: 0xAARRGGBB integers, alpha in the top byte, as Haxe's libraries write them and as an editor's color picker
	reads a literal. Each channel is 0 to 255. Text names a color the CSS way, #RRGGBB or #RRGGBBAA (a scene file, a color picker's field),
	converted by fromRgba and toRgba. */
class Color {
	/** The color of these channels, each 0 to 255 (only its low 8 bits are taken), alpha opaque unless given. */
	public static inline function fromChannels(red:Int, green:Int, blue:Int, alpha = 255):Int
		return (alpha & 255) << 24 | (red & 255) << 16 | (green & 255) << 8 | (blue & 255);

	/** color's red, 0 to 255. */
	public static inline function getRed(color:Int):Int
		return (color >>> 16) & 255;

	/** color's green, 0 to 255. */
	public static inline function getGreen(color:Int):Int
		return (color >>> 8) & 255;

	/** color's blue, 0 to 255. */
	public static inline function getBlue(color:Int):Int
		return color & 255;

	/** color's alpha, 0 (clear) to 255 (opaque). */
	public static inline function getAlpha(color:Int):Int
		return color >>> 24;

	/** color with its alpha replaced by alpha, 0 to 255 (only its low 8 bits are taken). */
	public static inline function withAlpha(color:Int, alpha:Int):Int
		return (color & 0xffffff) | (alpha & 255) << 24;

	/** The color an 0xRRGGBBAA integer names (the CSS order, as text writes it). */
	public static inline function fromRgba(rgba:Int):Int
		return rgba >>> 8 | (rgba & 255) << 24;

	/** color as an 0xRRGGBBAA integer (the CSS order, as text writes it). */
	public static inline function toRgba(color:Int):Int
		return color << 8 | color >>> 24;
}
