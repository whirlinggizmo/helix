package helix.platform;

/** Represents a compiled program, with its stages in each dialect the adapters compile, its vertex attributes, and what it binds.

	`IGraphics.createShader` builds a program from it. An adapter reads only its own dialect. That is GLSL ES 300 in the browser, GLSL 410
	for GL natively, and SDL_GPU's stages for SDL_GPU. */
typedef ShaderSource = {
	/** The vertex attributes' names, by slot. A matrix's name is at its first slot, and its other columns' slots hold "". */
	final attributes:Array<String>;

	/** GLSL 410, for GL natively. Absent from a browser build. */
	@:optional final glsl410:ShaderStages;

	/** GLSL ES 300, for WebGL2. */
	final glsl300es:ShaderStages;

	/** SDL_GPU's stages. Present only in a build for SDL_GPU. */
	@:optional final sdlGpu:SdlGpuStages;

	/** The uniform blocks it declares. */
	final uniformBlocks:Array<ShaderBlock>;

	/** The textures it samples. */
	final textures:Array<ShaderTexture>;
}
