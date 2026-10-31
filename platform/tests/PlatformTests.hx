import helix.platform.BlendMode;
import helix.platform.Color;
import helix.platform.Filter;
import helix.platform.Sampling;
import helix.platform.TextureFormat;
import helix.platform.Wrap;

/** Checks helix-platform's own values, built with -lib helix-platform alone so nothing above it is visible: colors' channels and their
	CSS order, a sampling's parts, texture formats' level sizes, and the enum abstracts read as their names. Run by helix.py test on the
	interpreter and Node. */
class PlatformTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// A program's company and product, each one directory's name on every OS.
		var name = helix.platform.FilePath.isDirectoryName;
		check(name("Whirling Gizmo") && name("asteroids-2") && name("Ünïcode"), "directory names: spaces, digits and letters of any script");
		check(!name("") && !name(".") && !name("..") && !name("a/b") && !name("a\\b") && !name("a:b") && !name("what?"),
			"directory names: not empty, . or .., no separator or reserved character");
		check(!name("trailing ") && !name("trailing.") && !name([for (_ in 0...65) "x"].join("")),
			"directory names: no space or . at the end, 64 characters at most");
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

		// A sampling keeps its filter and wraps in a small value, and with* change one part.
		var sampling = new Sampling(Linear, Repeat, Mirror);
		check(sampling.filter == Linear && sampling.wrapU == Repeat && sampling.wrapV == Mirror && (sampling : Int) < Sampling.COUNT,
			"Sampling keeps its filter and wraps");
		check(sampling.withFilter(Nearest).filter == Nearest
			&& sampling.withFilter(Nearest).wrapU == Repeat, "withFilter changes the filter alone");
		check(sampling.withWrap(Clamp, Clamp).wrapV == Clamp
			&& sampling.withWrap(Clamp, Clamp).filter == Linear, "withWrap changes the wraps alone");
		check(Sampling.NEAREST.filter == Nearest && Sampling.LINEAR.filter == Linear && Sampling.LINEAR.wrapU == Clamp, "The two clamped samplings");
		var seen = new Map<Int, Bool>();
		for (filter in [Nearest, Linear])
			for (u in [Clamp, Repeat, Mirror])
				for (v in [Clamp, Repeat, Mirror])
					seen.set(new Sampling(filter, u, v), true);
		check(Lambda.count(seen) == 18 && [for (s in seen.keys()) s].filter(s -> s < 0 || s >= Sampling.COUNT).length == 0,
			"Every combination distinct and under COUNT");

		// Level sizes: blocks of 4x4 of 16 bytes, or bytes a texel.
		check((Astc4x4 : TextureFormat).levelBytes(5, 3) == 32
			&& (Bc7 : TextureFormat).levelBytes(4, 4) == 16, "Compressed: 16 bytes a 4x4 block");
		check((Rgba8 : TextureFormat).levelBytes(5, 3) == 60
			&& (Rgba16f : TextureFormat).levelBytes(5, 3) == 120, "Uncompressed: 4 or 8 bytes a texel");

		// The enum abstracts read as their names where typed (helix.platform.macros.EnumNames), staying numbers.
		var blend = BlendMode.Additive,
			format = TextureFormat.Etc2Rgba8,
			wrap = Wrap.Mirror;
		check(Std.string(blend) == "Additive" && '$format' == "Etc2Rgba8" && "" + wrap == "Mirror" && (blend : Int) == 2,
			"BlendMode, TextureFormat, Wrap by name, still their numbers");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
