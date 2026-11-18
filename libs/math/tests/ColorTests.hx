import helix.math.Color;

/** Checks Color with the library alone: 0xAARRGGBB channels in and out, alpha replaced, the CSS order both ways; hue, saturation, value and
	lightness to and from colors; linear light to and from colors; mixing, laying one over another, tinting, brightening and contrasting. */
class ColorTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function main():Void {
		// Colors: 0xAARRGGBB, channels in and out, alpha replaced, and the CSS order both ways.
		var orange = Color.fromChannels(255, 128, 0);
		check(orange == 0xffff8000, "fromChannels: opaque unless told, alpha in the top byte");
		check(Color.getRed(orange) == 255
			&& Color.getGreen(orange) == 128
			&& Color.getBlue(orange) == 0
			&& Color.getAlpha(orange) == 255,
			"Each channel read back");
		check(Color.fromChannels(300, -1, 0, 128) == 0x802cff00, "Only each channel's low 8 bits are used");
		check(Color.withAlpha(orange, 64) == 0x40ff8000
			&& Color.withAlpha(orange, 64 + 256) == 0x40ff8000, "withAlpha replaces the alpha alone");
		check(Color.toRgba(0x80112233) == 0x11223380 && Color.fromRgba(0x11223380) == 0x80112233, "The CSS order, both ways");
		check(Color.fromRgba(Color.toRgba(0xdeadbeef)) == 0xdeadbeef, "The CSS order round-trips");

		check(Color.fromHsv(0, 1, 1) == 0xffff0000 && Color.fromHsv(120, 1, 1) == 0xff00ff00 && Color.fromHsv(240, 1, 1) == 0xff0000ff,
			"fromHsv: the primaries");
		check(Color.fromHsv(60, 1, 1) == 0xffffff00 && Color.fromHsv(-60, 1, 1) == 0xffff00ff && Color.fromHsv(420, 1, 1) == 0xffffff00,
			"fromHsv: between them, and angles wrapped");
		check(Color.fromHsv(0, 0, .5) == 0xff808080 && Color.fromHsv(30, 1, 1, 64) == 0x40ff8000, "fromHsv: gray, and an alpha");
		check(near(Color.getHue(0xffff8000), 30.11764705882353)
			&& near(Color.getHue(0xff808080), 0)
			&& near(Color.getHue(0xffff00ff), 300), "getHue");
		check(near(Color.getSaturation(0xffff8000), 1)
			&& near(Color.getSaturation(0xff808080), 0)
			&& near(Color.getSaturation(0xff000000), 0),
			"getSaturation");
		check(near(Color.getValue(0xff8000ff), 1) && near(Color.getValue(0xff000000), 0), "getValue");
		for (c in [0xffff8000, 0xff3366cc, 0xff10e080])
			check(Color.fromHsv(Color.getHue(c), Color.getSaturation(c), Color.getValue(c)) == c, 'HSV round-trips ${StringTools.hex(c)}');
		check(Color.lerp(0xff000000, 0xffffffff, .5) == 0xff808080
			&& Color.lerp(0x00ff0000, 0xff0000ff, 1) == 0xff0000ff
			&& Color.lerp(0xff000000, 0xffffffff, 2) == 0xffffffff,
			"lerp: halfway, the end, clamped");
		check(Color.blend(0xff0000ff, 0xffff0000) == 0xffff0000 && Color.blend(0xff0000ff, 0x00ff0000) == 0xff0000ff,
			"blend: opaque over covers, clear over doesn't");
		check(Color.blend(0xff0000ff, 0x80ff0000) == 0xff80007f && Color.blend(0, 0) == 0, "blend: half over, and nothing over nothing");
		check(Color.tint(0xff808080, 0xffffffff) == 0xff808080
			&& Color.tint(0xffff8040, 0x80ff0000) == 0x80ff0000, "tint: white keeps, a tint multiplies");
		check(Color.brighten(0x80808080, 1) == 0x80ffffff
			&& Color.brighten(0x80808080, -1) == 0x80000000
			&& Color.brighten(0xff808080, .5) == 0xffc0c0c0
			&& Color.brighten(0xff808080, 0) == 0xff808080,
			"brighten: white, black, halfway, alpha kept");
		check(Color.contrast(0xff40c080, 0) == 0xff40c080
			&& Color.contrast(0xff40c080, 1) == 0xff00ffff
			&& Color.contrast(0x80ff0000, -1) == 0x80808080,
			"contrast: unchanged, the most, none");

		// Hue, saturation and lightness, pinned to Python's colorsys.
		check(Color.fromHsl(0, 1, .5) == 0xffff0000 && Color.fromHsl(120, 1, .5) == 0xff00ff00 && Color.fromHsl(240, 1, .5) == 0xff0000ff,
			"fromHsl: the primaries at lightness .5");
		check(Color.fromHsl(30, 1, .5) == 0xffff8000
			&& Color.fromHsl(200, .6, .3) == 0xff1f5c7a
			&& Color.fromHsl(310, .35, .7) == 0xffcd98c4
			&& Color.fromHsl(90, 1, .25) == 0xff408000,
			"fromHsl: between them, pinned");
		check(Color.fromHsl(-160, .6, .3) == 0xff1f5c7a && Color.fromHsl(560, .6, .3) == 0xff1f5c7a, "fromHsl: angles wrapped");
		check(Color.fromHsl(70, 1, 0) == 0xff000000 && Color.fromHsl(70, 1, 1) == 0xffffffff && Color.fromHsl(70, 0, .5) == 0xff808080,
			"fromHsl: black, white and gray whatever the hue");
		check(Color.fromHsl(30, 2, .5) == 0xffff8000 && Color.fromHsl(30, 1, 7) == 0xffffffff && Color.fromHsl(30, -1, -1) == 0xff000000,
			"fromHsl: saturation and lightness clamped");
		check(Color.fromHsl(30, 1, .5, 64) == 0x40ff8000, "fromHsl: an alpha");
		check(near(Color.getLightness(0xff40c080), 0.5019607843137255)
			&& Color.getLightness(0xff000000) == 0
			&& Color.getLightness(0xffffffff) == 1
			&& near(Color.getLightness(0xffff0000), .5),
			"getLightness");
		check(near(Color.getHslSaturation(0xff40c080), 0.5039370078740157)
			&& Color.getHslSaturation(0xff808080) == 0
			&& Color.getHslSaturation(0xff000000) == 0
			&& Color.getHslSaturation(0xffffffff) == 0
			&& Color.getHslSaturation(0xffff0000) == 1,
			"getHslSaturation: 0 for a gray, black and white");
		for (color in [0xff1f5c7a, 0xffcd98c4, 0xff408000, 0xff123456])
			check(Color.fromHsl(Color.getHue(color), Color.getHslSaturation(color), Color.getLightness(color)) == color,
				"a color's hue, saturation and lightness make the color again");

		// Linear light: sRGB's curve both ways, pinned to the curve worked in Python.
		check(Math.abs(Color.srgbToLinear(.5) - 0.21404114048223255) < 1e-15
			&& Math.abs(Color.srgbToLinear(.04) - 0.0030959752321981426) < 1e-17
			&& Color.srgbToLinear(0) == 0
			&& Color.srgbToLinear(1) == 1,
			"srgbToLinear: the curve, the straight part near black, and the ends");
		check(Math.abs(Color.linearToSrgb(.5) - 0.7353569830524495) < 1e-15
			&& Math.abs(Color.linearToSrgb(.002) - 0.025840000000000002) < 1e-17
			&& Color.linearToSrgb(0) == 0
			&& Math.abs(Color.linearToSrgb(1) - 1) < 1e-15,
			"linearToSrgb: the curve, the straight part near black, and the ends");
		var channelsBack = true;
		for (channel in 0...256)
			if (Math.round(Color.linearToSrgb(Color.srgbToLinear(channel / 255)) * 255) != channel)
				channelsBack = false;
		check(channelsBack, "each of a channel's 256 values, to linear light and back");
		var linear = Color.toLinear(0x40ff8000);
		check(linear.x == 1 && Math.abs(linear.y - 0.21586050011389926) < 1e-15 && linear.z == 0 && near(linear.w, 64 / 255),
			"toLinear: red, green and blue as linear light, the alpha as stored");
		var into = new helix.math.Vector4(9, 9, 9, 9);
		check(Color.toLinear(0x40ff8000, into) == into && into.equals(linear), "toLinear, into the vector given");
		check(Color.fromLinear(.5, .2, .01) == 0xffbc7c19, "fromLinear: pinned, opaque unless told");
		check(Color.fromLinear(linear.x, linear.y, linear.z, linear.w) == 0x40ff8000, "fromLinear makes toLinear's color again");
		check(Color.fromLinear(2, -1, 1, 3) == 0xffff00ff
			&& Color.fromLinear(0, 0, 0, -1) == 0x00000000, "fromLinear: each number clamped");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
