import helix.math.Color;

/** Checks Color with the library alone: 0xAARRGGBB channels in and out, alpha replaced, the CSS order both ways; hue, saturation and value
	to and from colors; mixing, laying one over another, tinting, brightening and contrasting. */
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
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
