package helix.shaders;

import helix.render3d.Material;

/** A library surface shader: a material drawn without light, its base color and texture times color, and its emission, under the stage's
	exposure and tone mapping as a material that isn't lit is. Made on a material, it is that material's surface shader from then on
	(LibrarySurface). */
class Unlit extends LibrarySurface {
	/** What the material's base color and texture are multiplied by, 0xAARRGGBB, its color sRGB as the material's are: white (the material
		as it is) by default. */
	public var color(default, set):Int;

	function set_color(value:Int):Int {
		color = value;
		if (attached)
			material.shaderParameters.setColor("color", value);
		return value;
	}

	/** Makes Unlit material's surface shader, color white. */
	public function new(material:Material) {
		super(material, "unlit", UnlitPacked.text());
		color = 0xffffffff;
	}
}
