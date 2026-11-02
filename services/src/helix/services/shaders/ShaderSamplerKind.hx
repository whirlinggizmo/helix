package helix.services.shaders;

/** Specifies what kind of texture a sampler reads, from its GLSL type, as `IGraphics` creates them. */
enum abstract ShaderSamplerKind(Int) to Int {
	/** A `sampler2D`: an image or a render target (`IGraphics.createTexture`, `createRenderTarget`). */
	var Texture2D = 0;

	/** A `samplerCube`: a cubemap (`IGraphics.createCubeTexture`). */
	var Cube = 1;

	/** A `sampler2DArray`: a texture of layers. */
	var Array2D = 2;

	/** A `sampler2DArrayShadow`: a shadow map read through a comparison sampler (`IGraphics.createShadowMap`). */
	var Shadow = 3;

	/** A `sampler2D` the code reads only with `texelFetch`: a data texture, never filtered (`IGraphics.createDataTexture`).
		`textureSize` is a query, not a read, so using it leaves a sampler `Data`; any `texture` call makes it `Texture2D`. */
	var Data = 4;
}
