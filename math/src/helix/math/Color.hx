package helix.math;

/** Provides functions for colors held as 0xAARRGGBB integers, with alpha in the top byte: their channels, hue, saturation and value,
	blending one over another, and mixing, tinting, brightening and contrasting them.

	Each channel is 0 to 255. Text writes a color in CSS order, as #RRGGBB or #RRGGBBAA. `fromRgba` and `toRgba` convert between that
	order and this one.

	```haxe
	var orange = Color.fromChannels(255, 128, 0);
	var faded = Color.withAlpha(orange, 128);
	```
 */
class Color {
	/** Returns the color with the provided channels.

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

	/** Returns the color of a hue, saturation and value, opaque or with an alpha.

		@param hue  The hue, in degrees: 0 red, 120 green, 240 blue; any angle, wrapped.
		@param saturation  The saturation, 0 (gray) to 1, clamped.
		@param value  The value, 0 (black) to 1, clamped.
		@param alpha  Optional. The alpha channel, 0 to 255; defaults to 255.
		@return  The color, its channels rounded. */
	public static function fromHsv(hue:Float, saturation:Float, value:Float, alpha = 255):Int {
		hue = hue % 360;
		if (hue < 0)
			hue += 360;
		saturation = saturation < 0 ? 0 : saturation > 1 ? 1 : saturation;
		value = value < 0 ? 0 : value > 1 ? 1 : value;
		function channel(n:Float):Int {
			var k = (n + hue / 60) % 6;
			var least = Math.min(k, 4 - k);
			return Math.round((value - value * saturation * Math.max(0, Math.min(least, 1))) * 255);
		}
		return fromChannels(channel(5), channel(3), channel(1), alpha);
	}

	/** Returns a color's hue.

		@param color  The color, as 0xAARRGGBB.
		@return  The hue, in degrees, 0 up to 360: 0 for a gray. */
	public static function getHue(color:Int):Float {
		var r = getRed(color) / 255,
			g = getGreen(color) / 255,
			b = getBlue(color) / 255;
		var most = Math.max(r, Math.max(g, b)),
			delta = most - Math.min(r, Math.min(g, b));
		if (delta == 0)
			return 0;
		var hue = most == r ? 60 * ((g - b) / delta) : most == g ? 60 * ((b - r) / delta + 2) : 60 * ((r - g) / delta + 4);
		return hue < 0 ? hue + 360 : hue;
	}

	/** Returns a color's saturation: how far it is from gray.

		@param color  The color, as 0xAARRGGBB.
		@return  The saturation, 0 to 1: 0 for a gray or black. */
	public static function getSaturation(color:Int):Float {
		var most = Math.max(getRed(color), Math.max(getGreen(color), getBlue(color)));
		var least = Math.min(getRed(color), Math.min(getGreen(color), getBlue(color)));
		return most == 0 ? 0 : (most - least) / most;
	}

	/** Returns a color's value: its brightest channel.

		@param color  The color, as 0xAARRGGBB.
		@return  The value, 0 (black) to 1. */
	public static function getValue(color:Int):Float
		return Math.max(getRed(color), Math.max(getGreen(color), getBlue(color))) / 255;

	/** Returns the color a fraction of the way from one color to another, each channel alpha included.

		@param from  The color at 0, as 0xAARRGGBB.
		@param to  The color at 1.
		@param t  The fraction, clamped to 0 to 1.
		@return  The mix, its channels rounded. */
	public static function lerp(from:Int, to:Int, t:Float):Int {
		t = t < 0 ? 0 : t > 1 ? 1 : t;
		inline function mix(a:Int, b:Int):Int
			return Math.round(a + (b - a) * t);
		return fromChannels(mix(getRed(from), getRed(to)), mix(getGreen(from), getGreen(to)), mix(getBlue(from), getBlue(to)),
			mix(getAlpha(from), getAlpha(to)));
	}

	/** Returns one color laid over another by its alpha, as a translucent paint covers what is under it ("source over").

		@param under  The color beneath, as 0xAARRGGBB.
		@param over  The color laid over it.
		@return  What is seen, its channels rounded: the color beneath where the one over is clear, the one over where it is opaque. */
	public static function blend(under:Int, over:Int):Int {
		var a = getAlpha(over) / 255,
			b = getAlpha(under) / 255,
			alpha = a + b * (1 - a);
		if (alpha == 0)
			return 0;
		inline function mix(top:Int, bottom:Int):Int
			return Math.round((top * a + bottom * b * (1 - a)) / alpha);
		return fromChannels(mix(getRed(over), getRed(under)), mix(getGreen(over), getGreen(under)), mix(getBlue(over), getBlue(under)),
			Math.round(alpha * 255));
	}

	/** Returns a color multiplied by another, channel by channel, alpha included: white leaves it as it is, black makes it black.

		@param color  The color, as 0xAARRGGBB.
		@param tint  The color it is multiplied by.
		@return  The tinted color, its channels rounded. */
	public static function tint(color:Int, tint:Int):Int {
		inline function times(a:Int, b:Int):Int
			return Math.round(a * b / 255);
		return fromChannels(times(getRed(color), getRed(tint)), times(getGreen(color), getGreen(tint)), times(getBlue(color), getBlue(tint)),
			times(getAlpha(color), getAlpha(tint)));
	}

	/** Returns a color brightened toward white or darkened toward black, its alpha kept.

		@param color  The color, as 0xAARRGGBB.
		@param factor  How far: 1 white, -1 black, 0 unchanged; clamped to -1 to 1.
		@return  The color, its channels rounded. */
	public static function brighten(color:Int, factor:Float):Int {
		factor = factor < -1 ? -1 : factor > 1 ? 1 : factor;
		inline function step(c:Int):Int
			return Math.round(factor < 0 ? c * (1 + factor) : c + (255 - c) * factor);
		return fromChannels(step(getRed(color)), step(getGreen(color)), step(getBlue(color)), getAlpha(color));
	}

	/** Returns a color with its contrast changed: its channels pushed away from mid-gray, or pulled toward it, its alpha kept.

		@param color  The color, as 0xAARRGGBB.
		@param factor  How far: 1 the most contrast (each channel to 0 or 255), -1 none (mid-gray), 0 unchanged; clamped to -1 to 1.
		@return  The color, its channels rounded and kept to 0 to 255. */
	public static function contrast(color:Int, factor:Float):Int {
		factor = factor < -1 ? -1 : factor > 1 ? 1 : factor;
		// The usual curve: a channel's distance from the middle scaled by (1 + factor) / (1 - factor), infinite at 1.
		var scale = factor == 1 ? Math.POSITIVE_INFINITY : (1 + factor) / (1 - factor);
		inline function step(c:Int):Int {
			var v = (c - 127.5) * scale + 127.5;
			return v <= 0 ? 0 : v >= 255 ? 255 : Math.round(v);
		}
		return fromChannels(step(getRed(color)), step(getGreen(color)), step(getBlue(color)), getAlpha(color));
	}
}
