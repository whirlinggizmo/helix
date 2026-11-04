package helix.platform;

/** Represents a compiled program, with its stages in each dialect the adapters compile, its vertex attributes, and what it binds.

	`IGraphics.createShader` builds a program from it. An adapter reads only its own dialect. That is GLSL ES 300 in the browser, GLSL 410
	for GL natively, and SDL_GPU's stages for SDL_GPU. The attributes with their types, the blocks with their members, and the textures
	are the program's reflection, for a caller that fills them by name. */
typedef ShaderSource = {
	/** The vertex attributes' names, by slot. A matrix's name is at its first slot, and its other columns' slots hold "". */
	final attributes:Array<String>;

	/** The vertex attributes' GLSL types (`float`, `vec2`, `vec3`, `vec4`, `mat4`, `int`, `ivec4` and the rest), by slot: a matrix's at its
		first slot, and its columns' (`vec4` for a `mat4`) at the rest. */
	final attributeTypes:Array<String>;

	/** The slots of the vertex attributes the vertex stage's code reads, as glslang finds; the others are declared and fed, and unread.
		A matrix's slot is its first column's. */
	final activeAttributes:Array<Int>;

	/** GLSL 410, for GL natively. Absent from a browser build. */
	@:optional final glsl410:ShaderStages;

	/** GLSL ES 300, for WebGL2. */
	final glsl300es:ShaderStages;

	/** SDL_GPU's stages. Present only in a build for SDL_GPU. */
	@:optional final sdlGpu:SdlGpuStages;

	/** The uniform blocks it declares, with their members. */
	final uniformBlocks:Array<ShaderBlock>;

	/** The textures it samples. */
	final textures:Array<ShaderTexture>;

	/** The values the vertex stage passes on, by location: what it declares as outputs. */
	final vertexOutputs:Array<ShaderVarying>;

	/** The values the fragment stage takes, by location: what it declares as inputs. */
	final fragmentInputs:Array<ShaderVarying>;

	/** Whether the vertex stage writes a point size of 1, compiled with `ShaderCompileOptions.points`, so `Primitive.Points` pipelines may
		draw it. Optional; false when omitted. */
	@:optional final points:Bool;
}
