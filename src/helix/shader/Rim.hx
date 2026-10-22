package helix.shader;

import helix.render3d.Material3D;

/** A material's rim light: a color brightest where its surface turns away from the viewer, round its edge, added to its light. Every material
	has one, off until a Rim turns it on, drawn by the stage's own shading and every library surface shader alike (an app's surface shader shows
	it through helix_output too). A Rim is a view of its material's: two on one material share it. */
class Rim {
	/** The material it lights. */
	public var material(default, null):Material3D;

	/** The rim's color, 0xAARRGGBB (sRGB), its alpha how strong (0 none, 255 all of it). */
	public var color(get, set):Int;

	function get_color():Int
		return material.rimColor;

	function set_color(value:Int):Int {
		material.rimColor = value;
		return value;
	}

	/** How tight the rim keeps to the edge, .1 to 64: 1 spreads it over the surface, 3 a rim, 8 a thin line. Clamped to .1..64 (NaN is .1). */
	public var power(get, set):Float;

	function get_power():Float
		return material.rimPower;

	function set_power(value:Float):Float {
		value = value > .1 ? (value < 64 ? value : 64) : .1;
		material.rimPower = value;
		return value;
	}

	/** Turns material's rim light on: color (0xAARRGGBB, sRGB, its alpha how strong) and power (.1 to 64, clamped). */
	public function new(material:Material3D, color = 0x80ffffff, power = 3.) {
		this.material = material;
		this.color = color;
		this.power = power;
	}
}
