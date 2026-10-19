package helix.shaders;

import helix.graphics.Graphics;
import helix.render3d.Material;

/** A library surface shader: a material drawn without light, its base color and texture times color, and its emission, under the stage's
	exposure and tone mapping as a material that isn't lit is. Made on a material, it is that material's surface shader from then on
	(Material.setShader), built on the program's GPU (Graphics) the first time a material asks for it. */
class Unlit {
	/** The material it draws. */
	public var material(default, null):Material;

	/** What the material's base color and texture are multiplied by, 0xRRGGBBAA, its color sRGB as the material's are: white (the material
		as it is) by default. Written into the shader's parameters (Material.shaderParameters); with another shader on the material since, it
		changes nothing there. */
	public var color(default, set):Int;

	function set_color(value:Int):Int {
		color = value;
		if (material.shaderParameters != null && material.shader == shader)
			material.shaderParameters.setColor("color", value);
		return value;
	}

	var shader:helix.graphics.Shader;

	/** Makes Unlit material's surface shader, color white. */
	public function new(material:Material) {
		this.material = material;
		shader = ShaderLibrary.get(Graphics.instance, "unlit", UnlitPacked.text());
		material.setShader(shader);
		color = 0xffffffff;
	}
}
