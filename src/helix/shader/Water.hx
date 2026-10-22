package helix.shader;

import helix.render3d.Material3D;

/** A library surface shader: travelling waves moving the surface along its normals (a vertex hook: the model needs vertices enough to show
	them), colored deep where it's looked into and shallow toward grazing, lit by the stage's lights with their glints, reflecting the stage's
	environment (or a sky color without one) at grazing angles; its shadow moves with its waves. The material's base color's alpha is its
	alpha (a blended material is see-through). Made on a material, it is that material's surface shader from then on (LibrarySurface). */
class Water extends LibrarySurface {
	/** The waves' height in the model's units, 0 or more: .03 by default. Under 0, or NaN, is 0. */
	public var amplitude(default, set):Float;

	function set_amplitude(value:Float):Float {
		value = value > 0 ? value : 0;
		amplitude = value;
		writeFloat("amplitude", value);
		return value;
	}

	/** The distance between crests in the model's units, .001 or more: .4 by default. Under .001, or NaN, is .001. */
	public var wavelength(default, set):Float;

	function set_wavelength(value:Float):Float {
		value = value > .001 ? value : .001;
		wavelength = value;
		writeFloat("wavelength", value);
		return value;
	}

	/** How fast the crests travel, the model's units a second (by the stage's time): .2 by default. */
	public var waveSpeed(default, set):Float;

	function set_waveSpeed(value:Float):Float {
		value = Math.isFinite(value) ? value : 0;
		waveSpeed = value;
		writeFloat("wave_speed", value);
		return value;
	}

	/** Its color looked straight into, 0xAARRGGBB (sRGB, alpha ignored): a deep blue by default. */
	public var deepColor(default, set):Int;

	function set_deepColor(value:Int):Int {
		deepColor = value;
		writeLinear("deep_color", value);
		return value;
	}

	/** Its color toward grazing, 0xAARRGGBB (sRGB, alpha ignored): a green blue by default. */
	public var shallowColor(default, set):Int;

	function set_shallowColor(value:Int):Int {
		shallowColor = value;
		writeLinear("shallow_color", value);
		return value;
	}

	/** What it reflects at grazing angles when the stage has no environment, 0xAARRGGBB (sRGB, alpha ignored): a pale sky by default. */
	public var skyColor(default, set):Int;

	function set_skyColor(value:Int):Int {
		skyColor = value;
		writeLinear("sky_color", value);
		return value;
	}

	/** How tight the lights' glints are, 1 to 2048: 120 by default. Clamped to 1..2048 (NaN is 1). */
	public var shininess(default, set):Float;

	function set_shininess(value:Float):Float {
		value = value > 1 ? (value < 2048 ? value : 2048) : 1;
		shininess = value;
		writeFloat("shininess", value);
		return value;
	}

	/** Makes Water material's surface shader, its waves and colors at their defaults. */
	public function new(material:Material3D) {
		super(material, "water", WaterPacked.text());
		amplitude = .03;
		wavelength = .4;
		waveSpeed = .2;
		deepColor = 0xff0b2a4a;
		shallowColor = 0xff2a8f96;
		skyColor = 0xffa0b8d8;
		shininess = 120;
	}
}
