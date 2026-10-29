package helix.platform;

/** Represents a texture that a program samples, and its kind.

	A texture is a plain 2D texture unless one of shadow, cube or data is true. */
typedef ShaderTexture = {
	/** The binding slot of the texture and its sampler. */
	final slot:Int;

	/** The stage that samples it: "vertex" or "fragment". */
	final stage:String;

	/** The GLSL name of the texture and sampler pair. */
	final glslName:String;

	/** Whether it is a shadow map: a depth array read through a comparison sampler. */
	final shadow:Bool;

	/** Whether it is a cubemap. */
	final cube:Bool;

	/** Whether the program never filters it: it only reads it texel by texel (`texelFetch`), so it is sampled nearest whatever the draw's
		sampling, as a data texture (`IGraphics.createDataTexture`) always is. */
	final data:Bool;
}
