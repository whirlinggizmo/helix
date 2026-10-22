package helix.shaders;

import helix.graphics.Color;

/** An HDR chain's tone mapping, a screen effect of the library: the frame's light (a stage's after its exposure, drawn into a half-float scene
	as sRGB values running past 1) brought into the screen's 0..1 by mode, as Stage3D does drawing straight to the screen, and written as the
	screen's sRGB. It wants HDR itself (ScreenEffect.hdr). PostProcess adds one after the last effect wanting HDR, with its stage's mode, to a
	chain that has none; one added by hand runs where it's added, with its own mode, and only in an HDR chain. Built on the program's GPU
	(Graphics) the first time one is made. */
class Tonemap extends LibraryScreenEffect {
	/** The most linear light computeHdrColor answers with, for a color the mode never reaches (Neutral never reaches 1): Neutral shows it as
		white written in 8 bits. */
	public static inline var MAX_LIGHT = 16.;

	/** A tone mapping by Khronos PBR Neutral. */
	public function new() {
		super("tonemap", TonemapPacked.text());
		hdr = true;
		mode = helix.render3d.Tonemap.Neutral;
	}

	/** How the light comes into 0..1 (helix.render3d.Tonemap's modes, as Stage3D.tonemap): Khronos PBR Neutral to start. */
	public var mode(default, set):helix.render3d.Tonemap;

	function set_mode(value:helix.render3d.Tonemap):helix.render3d.Tonemap {
		mode = value;
		parameters.setFloat("mode", (value : Int));
		return value;
	}

	/** Fills out (its first four) with what an HDR frame holds where this tone mapping shows color (0xAARRGGBB): red, green and blue as sRGB
		values running past 1, alpha as given, 0 to 1. PostProcess clears an HDR scene to it, so a background of clear color alone looks the
		same with and without an HDR chain. Solved on the CPU (this tone mapping as the shader works it, one channel at a time by bisection,
		round after round, as the modes mix the channels a little), no channel past MAX_LIGHT. A color the mode can't show comes as near as it
		lets: Neutral desaturates what nears white, so a bright saturated color (0xffff2000) is shown paler. */
	public function computeHdrColor(color:Int, out:Array<Float>):Void {
		var target = [
			for (channel in [Color.getRed(color), Color.getGreen(color), Color.getBlue(color)])
				decode(channel / 255)
		];
		var light = target.copy();
		if (mode != helix.render3d.Tonemap.None)
			for (round in 0...12)
				for (c in 0...3) {
					// Bisection in the square root of the light: even steps across the dark end, where the toe is steep.
					var low = 0., high = Math.sqrt(MAX_LIGHT);
					for (step in 0...48) {
						var middle = (low + high) / 2;
						light[c] = middle * middle;
						if (map(mode, light)[c] < target[c])
							low = middle;
						else
							high = middle;
					}
					light[c] = high * high;
				}
		for (c in 0...3)
			out[c] = encode(light[c]);
		out[3] = Color.getAlpha(color) / 255;
	}

	/** linear (red, green, blue light) tone mapped by mode as the shader does it, into 0..1, a new array. */
	public static function map(mode:helix.render3d.Tonemap, linear:Array<Float>):Array<Float> {
		var color = [for (v in linear) v > 0 ? v : 0.];
		switch mode {
			case Neutral:
				var startCompression = .8 - .04, desaturation = .15;
				var x = Math.min(color[0], Math.min(color[1], color[2]));
				var offset = x < .08 ? x - 6.25 * x * x : .04;
				for (c in 0...3)
					color[c] -= offset;
				var peak = Math.max(color[0], Math.max(color[1], color[2]));
				if (peak >= startCompression) {
					var d = 1 - startCompression;
					var newPeak = 1 - d * d / (peak + d - startCompression);
					var g = 1 - 1 / (desaturation * (peak - newPeak) + 1);
					for (c in 0...3)
						color[c] = color[c] * newPeak / peak * (1 - g) + newPeak * g;
				}
			case Aces:
				for (c in 0...3) {
					var v = color[c] * .6;
					color[c] = (v * (2.51 * v + .03)) / (v * (2.43 * v + .59) + .14);
				}
			case None:
		}
		return [for (v in color) v < 0 ? 0. : (v > 1 ? 1. : v)];
	}

	// An sRGB value (running past 1 too) to linear light.
	static function decode(v:Float):Float
		return v < .04045 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4);

	// Linear light to an sRGB value, the curve carried on past 1.
	static function encode(v:Float):Float
		return v < .0031308 ? v * 12.92 : 1.055 * Math.pow(v, 1 / 2.4) - .055;
}
