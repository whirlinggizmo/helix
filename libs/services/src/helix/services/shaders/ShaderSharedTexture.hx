package helix.services.shaders;

import helix.platform.Sampling;

/** Represents a texture many values read, as a scene's shadow map or a white fallback, changeable at any time and seen at once by every
	values sharing it (`IShaderValues.shareTexture`), whatever their shader.

	```haxe
	var shadowMap = new ShaderSharedTexture(graphics.createShadowMap(2048, 1));
	scene.shareTexture("shadowMap", shadowMap);   // every material drawn in the scene reads it
	shadowMap.texture = largerMap;                                        // every sharer reads the new one from its next draw
	``` */
class ShaderSharedTexture {
	/** Gets or sets the texture, as an `IGraphics` handle, or 0 for none. The handle is trusted, as `writeTexture`'s is. */
	public var texture:Int;

	/** Gets or sets how it is sampled; `Sampling.LINEAR` by default. */
	public var sampling:Sampling;

	/** Creates a shared texture.

		@param texture  Optional. The texture; defaults to none.
		@param sampling  Optional. How it is sampled; defaults to `Sampling.LINEAR`. */
	public function new(texture:Int = 0, ?sampling:Sampling) {
		this.texture = texture;
		this.sampling = sampling == null ? Sampling.LINEAR : sampling;
	}
}
