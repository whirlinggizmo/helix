package helix.shaders;

import helix.render3d.Material;

/** A material's hit flash: a color mixed over its light, all of it at a trigger and fading to none over some seconds of the stage's time
	(Stage3D.time, which the app advances, as its particles do), or an amount held. Every material has one, off until a HitFlash shows it, drawn
	by the stage's own shading and every library surface shader alike (an app's surface shader shows it through helix_output too), mixed in
	after the exposure, so the tone mapping applies to it as to the light. A HitFlash is a view of its material's: two on one material share
	it. */
class HitFlash {
	/** The material it flashes. */
	public var material(default, null):Material;

	/** Shows material's hit flash: none until triggered or an amount is held. */
	public function new(material:Material)
		this.material = material;

	/** The flash's color, 0xAARRGGBB (sRGB), its alpha how strong at most. White by default. */
	public var color(get, set):Int;

	function get_color():Int
		return material.flashColor;

	function set_color(value:Int):Int {
		material.flashColor = value;
		return value;
	}

	/** How much of the flash is held, 0 to 1 (times its color's alpha): 0, none, by default. Assigning holds it, ending a fade; read during a
		fade, it's the fade's start, 1. Clamped to 0..1 (NaN is 0). */
	public var amount(get, set):Float;

	function get_amount():Float
		return material.flashAmount;

	function set_amount(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		material.flashAmount = value;
		material.flashSeconds = 0;
		return value;
	}

	/** Flashes color (0xAARRGGBB, sRGB, its alpha how strong) all at once, fading to nothing over seconds of the stage's time from the next
		draw. False, changing nothing, for seconds not above 0. */
	public function trigger(color:Int, seconds:Float):Bool {
		if (!(seconds > 0))
			return false;
		material.flashColor = color;
		material.flashAmount = 1;
		material.flashSeconds = seconds;
		material.flashStart = Math.NaN;
		return true;
	}
}
