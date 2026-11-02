package helix.render.effects;

import helix.render.Texture2D;

/** Represents color grading on encoded colors, after the resolve: brightness, contrast and saturation, then a look-up table.

	The table is a strip of square slices, its height the size of each (16 or 32 a side as editors export them): red across a slice,
	green down it, blue from slice to slice, each texel the color its place maps to. */
class ColorGradeEffect extends ScreenEffect {
	/** Gets or sets the brightness added: 0 until set, -1 to 1. Clamped to -1 to 1. */
	public var brightness(default, set):Float = 0;

	/** Gets or sets the contrast, a multiplier about mid grey: 1 until set. Below 0 is clamped to 0. */
	public var contrast(default, set):Float = 1;

	/** Gets or sets the saturation, a multiplier: 1 until set, 0 grey. Below 0 is clamped to 0. */
	public var saturation(default, set):Float = 1;

	/** Gets or sets the look-up table, or null for none. */
	public var lut:Null<Texture2D> = null;

	/** Gets or sets how much of the table's color replaces the color: 1 until set. Clamped to 0 to 1. */
	public var lutIntensity(default, set):Float = 1;

	/** Creates grading that changes nothing until set. */
	public function new() {
		super(false);
	}

	function set_brightness(value:Float):Float {
		throw "helix-render: ColorGradeEffect.set_brightness is not yet built (stage 5, post-processing)";
	}

	function set_contrast(value:Float):Float {
		throw "helix-render: ColorGradeEffect.set_contrast is not yet built (stage 5, post-processing)";
	}

	function set_saturation(value:Float):Float {
		throw "helix-render: ColorGradeEffect.set_saturation is not yet built (stage 5, post-processing)";
	}

	function set_lutIntensity(value:Float):Float {
		throw "helix-render: ColorGradeEffect.set_lutIntensity is not yet built (stage 5, post-processing)";
	}
}
