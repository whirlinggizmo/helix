package helix.services.shaders;

/** Represents how `Shader.makeExpr` and `ShaderVariants.makeExpr` compile, for a library's macro: `ShaderOptions`' choices as values the
	macro has made rather than constants at a call. */
typedef ShaderBuildOptions = {
	/** Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`, besides each stage's `HELIX_VERTEX` or `HELIX_FRAGMENT`.
		Optional; none by default. */
	@:optional final defines:Array<String>;

	/** Texts an angle-bracket `#include` takes by name, before the build's class paths are looked in. Optional; none by default. */
	@:optional final includes:Map<String, String>;

	/** Directories a quoted `#include` looks in after the including file's own. Optional; none by default. */
	@:optional final includeDirectories:Array<String>;

	/** The blocks whose values are shared, as `ShaderOptions.shared`. Optional; none by default. */
	@:optional final shared:Array<ShaderSharedBlock>;

	/** Whether the compiler wraps the vertex stage with a clip scale, as `ShaderOptions.clipScale`. Optional; false by default. */
	@:optional final clipScale:Bool;

	/** Whether the compiler wraps the vertex stage to write a point size of 1, as `ShaderOptions.points`. Optional; false by default. */
	@:optional final points:Bool;

	/** The library's rules, run on the compiled shader: returns why it breaks them, which stops the build, or null. Optional. */
	@:optional final check:Shader->Null<String>;

	/** The asset path of the file, as `ShaderOptions.file`. Optional; no file by default. */
	@:optional final file:String;

	/** Whether the program is compiled for every target, whatever the build's: GLSL ES, GLSL 410 and SDL_GPU's stages, for a file one
		page and one native program both load. Optional; false by default, the build's target's alone. */
	@:optional final everyTarget:Bool;
}
