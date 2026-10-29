package helix.platform;

/** Provides functions for colors held as 0xAARRGGBB integers, alpha in the top byte.

	Each channel is 0 to 255. Text writes a color in CSS order, #RRGGBB or #RRGGBBAA; `fromRgba` and `toRgba` convert between that order
	and this one.

	```haxe
	var orange = Color.fromChannels(255, 128, 0);
	var faded = Color.withAlpha(orange, 128);
	```
 */
class Color {
	/** Returns the color with the given channels.

		Only the low 8 bits of each channel are used.
		@param red  The red channel, 0 to 255.
		@param green  The green channel, 0 to 255.
		@param blue  The blue channel, 0 to 255.
		@param alpha  Optional. The alpha channel, 0 (clear) to 255 (opaque); defaults to 255.
		@return  The color, as 0xAARRGGBB. */
	public static inline function fromChannels(red:Int, green:Int, blue:Int, alpha = 255):Int
		return (alpha & 255) << 24 | (red & 255) << 16 | (green & 255) << 8 | (blue & 255);

	/** Returns a color's red channel.

		@param color  The color, as 0xAARRGGBB.
		@return  The red channel, 0 to 255. */
	public static inline function getRed(color:Int):Int
		return (color >>> 16) & 255;

	/** Returns a color's green channel.

		@param color  The color, as 0xAARRGGBB.
		@return  The green channel, 0 to 255. */
	public static inline function getGreen(color:Int):Int
		return (color >>> 8) & 255;

	/** Returns a color's blue channel.

		@param color  The color, as 0xAARRGGBB.
		@return  The blue channel, 0 to 255. */
	public static inline function getBlue(color:Int):Int
		return color & 255;

	/** Returns a color's alpha channel.

		@param color  The color, as 0xAARRGGBB.
		@return  The alpha channel, 0 (clear) to 255 (opaque). */
	public static inline function getAlpha(color:Int):Int
		return color >>> 24;

	/** Returns a color with its alpha channel replaced.

		Only the low 8 bits of alpha are used.
		@param color  The color, as 0xAARRGGBB.
		@param alpha  The new alpha channel, 0 (clear) to 255 (opaque).
		@return  The color with the new alpha. */
	public static inline function withAlpha(color:Int, alpha:Int):Int
		return (color & 0xffffff) | (alpha & 255) << 24;

	/** Returns the color that an integer in CSS order names.

		@param rgba  The color, as 0xRRGGBBAA.
		@return  The color, as 0xAARRGGBB. */
	public static inline function fromRgba(rgba:Int):Int
		return rgba >>> 8 | (rgba & 255) << 24;

	/** Returns a color as an integer in CSS order.

		@param color  The color, as 0xAARRGGBB.
		@return  The color, as 0xRRGGBBAA. */
	public static inline function toRgba(color:Int):Int
		return color << 8 | color >>> 24;
}
