package helix.platform.tools;

/** Represents how `ShaderCompiler.compileText` compiles: the dialects it makes besides GLSL ES 300 (WebGL2), which every `ShaderSource`
	carries, where includes are looked for, the names defined, whether loose uniforms are taken, and how the vertex stage is wrapped. */
typedef ShaderCompileOptions = {
	/** Whether to make GLSL 410, for GL natively. */
	final glsl410:Bool;

	/** Whether to make SDL_GPU's stages: SPIR-V, MSL and HLSL. */
	final sdlGpu:Bool;

	/** Directories `#include` looks in, after the directory of each stage's file. Optional; none by default. */
	final ?includeDirectories:Array<String>;

	/** Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`, as glslang's `-D` takes them. Optional; none by default. */
	final ?defines:Array<String>;

	/** Whether a stage may declare uniforms outside a block (`uniform vec3 diffuse;`), in either form of source. Optional; false by
		default.

		Both stages' loose uniforms are gathered into one block, `helix_uniforms`, read by both: the vertex stage's in the order it
		declares them, then the fragment stage's not already there, at the lowest block binding the program's own blocks leave free in
		both stages, reflected as any block is. A loose texture is bound at the lowest texture binding left free, in the order declared.
		Values passed between the stages, and the attributes, may leave their locations out. */
	final ?looseUniforms:Bool;

	/** Loose uniforms gathered by name into blocks of their own, which both stages read, each laid out in the order its names are
		given, placed after `helix_uniforms`. Optional; none by default. A name neither stage declares is refused. */
	final ?gatheredBlocks:Array<{name:String, uniforms:Array<String>}>;

	/** Whether to wrap the vertex stage with a clip scale it multiplies `gl_Position` by, a loose `vec4 helix_clipScale`, for
		`ClipFlip.ClipScale`. Optional; false by default. */
	final ?clipScale:Bool;

	/** Whether to wrap the vertex stage so it writes a point size of 1, `gl_PointSize = 1.0` after its own `main`, for `Primitive.Points`
		pipelines. Optional; false by default.

		A size the program writes is replaced. The result's `ShaderSource.points` is true, and SDL_GPU's HLSL is made in SPIRV-Cross's
		compatibility mode, which takes the size HLSL has no place for. */
	final ?points:Bool;
}
