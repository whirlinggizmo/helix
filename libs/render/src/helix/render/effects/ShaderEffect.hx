package helix.render.effects;

import helix.services.shaders.ShaderValues;

/** Represents a screen effect of one pass through a program's own shader, drawn over the whole frame: a fragment stage reading
	`sourceTexture`, `sourceSize` and `time` (filled by the chain), and its own values.

	```haxe
	var vignetteShader = ScreenEffect.compileShader("vignette.frag");
	var vignette = new ShaderEffect(new ShaderValues(vignetteShader));
	vignette.values.writeFloat(vignetteShader.getUniform("strength"), .4);
	post.effects.push(vignette);
	``` */
class ShaderEffect extends ScreenEffect {
	/** Gets the values it draws with: its shader, from `ScreenEffect.compileShader` or `compileShaderStages`, and the
		shader's own uniforms and textures, read at each `PostProcess.draw`. */
	public final values:ShaderValues;

	/** Creates an effect drawing through a shader.

		@param values  The values over the shader.
		@param linear  Optional. Whether it works on linear light, before the resolve; defaults to false. */
	public function new(values:ShaderValues, linear = false) {
		super(linear);
		this.values = values;
	}
}
