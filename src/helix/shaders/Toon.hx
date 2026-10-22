package helix.shaders;

import helix.render3d.Material3D;

/** A library surface shader: the stage's lights in a few flat bands over the material's base color and texture (their shadows banded with
	them), its unlit side no darker than a shadow color, and its emission; with a rim of light round its edge (the material's Rim, which it
	turns on). Made on a material, it is that material's surface shader from then on (LibrarySurface). */
class Toon extends LibrarySurface {
	/** How many levels of light there are, 1 to 16: 3 by default. Clamped to 1..16. */
	public var bands(default, set):Int;

	function set_bands(value:Int):Int {
		value = value < 1 ? 1 : value > 16 ? 16 : value;
		bands = value;
		writeFloat("bands", value);
		return value;
	}

	/** The least light the surface shows, its unlit side's, 0xAARRGGBB (sRGB, alpha ignored): the material's color times this where no light
		reaches. A dark blue grey by default. */
	public var shadowColor(default, set):Int;

	function set_shadowColor(value:Int):Int {
		shadowColor = value;
		writeLinear("shadow_color", value);
		return value;
	}

	/** Its rim of light: the material's rim light (Rim), on to start, white at a third, power 3. */
	public var rim(default, null):Rim;

	/** Makes Toon material's surface shader: 3 bands, the shadow color dark blue grey, a rim of light. */
	public function new(material:Material3D) {
		super(material, "toon", ToonPacked.text());
		bands = 3;
		shadowColor = 0xff3a4150;
		rim = new Rim(material, 0x55ffffff, 3);
	}
}
