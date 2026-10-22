package helix.shader;

import helix.graphics.Color;
import helix.graphics.Graphics;
import helix.graphics.Shader;
import helix.render3d.Material3D;

/** What the shader library's surface shader classes share (Unlit, Toon, Dissolve, Water): made on a material, the class's shader is that
	material's surface shader from then on (Material3D.setShader), built on the program's GPU (Graphics) the first time a material asks for it,
	and its fields write their parameters into the material's (Material3D.shaderParameters) while the material keeps it: with another shader
	on the material since, a field changes nothing there. Every library surface shader shows the material's hit flash and rim light
	(HitFlash, Rim), as the stage's own shading does. */
class LibrarySurface {
	/** The material it draws. */
	public var material(default, null):Material3D;

	var shader:Shader;

	function new(material:Material3D, name:String, text:String) {
		this.material = material;
		shader = ShaderLibrary.get(Graphics.instance, name, text);
		material.setShader(shader);
	}

	/** Whether it is still its material's surface shader. */
	public var attached(get, never):Bool;

	function get_attached():Bool
		return material.shader == shader && material.shaderParameters != null;

	// Writes a float parameter, while attached.
	function writeFloat(name:String, value:Float):Void
		if (attached)
			material.shaderParameters.setFloat(name, value);

	// Writes a color parameter as linear light: color (0xAARRGGBB, sRGB) decoded, times scale, its alpha as it is; while attached.
	function writeLinear(name:String, color:Int, scale = 1.):Void
		if (attached)
			material.shaderParameters.setValues(name, [
				linear(Color.getRed(color)) * scale,
				linear(Color.getGreen(color)) * scale,
				linear(Color.getBlue(color)) * scale,
				Color.getAlpha(color) / 255
			]);

	// An sRGB channel (0..255) as linear light.
	static function linear(channel:Int):Float {
		var c = channel / 255;
		return c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}
}
