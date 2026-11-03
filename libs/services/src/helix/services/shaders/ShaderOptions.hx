package helix.services.shaders;

/** Represents how a build-time compile at a call compiles: every macro that compiles a shader takes it, as a constant object written at
	the call or a class's static constant holding one (`static final OPTIONS:ShaderOptions = {...}`), so options several calls share
	live in one place. An array of them composes, left to right: `[Lit.OPTIONS, {file: "shaders/lit.shader"}]` takes `Lit.OPTIONS` and
	sets `file`; a later array (`defines`, `shared`) is added to an earlier one, a later value replaces an earlier one.

	```haxe
	Shader.compile("lit.vert", "lit.frag", {defines: ["MAX_LIGHTS=8"], includes: "three.ShaderChunk", shared: [{name: "Frame"}],
		file: "shaders/lit.shader"});
	``` */
typedef ShaderOptions = {
	/** Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`. Optional; none by default. Each stage also has its own:
		`HELIX_VERTEX` in the vertex stage, `HELIX_FRAGMENT` in the fragment stage, so a file both include tells them apart. */
	@:optional var defines:Array<String>;

	/** A class whose static `String` constants (`static inline final` or `static final` with a constant value) are texts an
		angle-bracket `#include` takes by the constant's name: `#include <common>` takes `common`. It is named as Haxe names it from the
		call's file: `ShaderChunk`, `three.ShaderChunk`, or `three.Chunks.Standard` for a type in another type's module. Optional; none
		by default. An included text may include others. They are looked in before the build's class paths. */
	@:optional var includes:String;

	/** Directories a quoted `#include` looks in after the including file's own, relative to the file holding the call. Optional; none by
		default. */
	@:optional var includeDirectories:Array<String>;

	/** The blocks whose values are shared (`ShaderBlockValues`): a block the shader declares, or loose uniforms gathered into one.
		Optional; none by default. A values drawn while a shared block is shared neither on it nor on its base throws, so a frame's data
		is never silently 0, and a typed values class leaves a shared block's members out (`ShaderValueClasses.buildBlock` makes the
		block's own). */
	@:optional var shared:Array<ShaderSharedBlock>;

	/** Whether the compiler wraps the vertex stage so a draw into a render target is turned the right way up whatever the shader
		writes: it declares a loose `vec4 helix_clipScale` and multiplies `gl_Position` by it, component by component, after the stage's
		own `main`. Optional; false by default. A pipeline flips it with `flip: ClipScale, flipUniform: "helix_clipScale"`
		(`ShaderPipelineState.CLIP_SCALE`): a layer whose users write their own vertex stages (helix-raylib) needs no named matrix. */
	@:optional var clipScale:Bool;

	/** Whether the compiler wraps the vertex stage so it writes a point size of 1 after the stage's own `main`, whatever the stage wrote,
		so a pipeline may draw it as points (`ShaderPipelineState.primitive` `Points`, which the platform refuses over any other shader).
		Optional; false by default. */
	@:optional var points:Bool;

	/** A static function `Shader->Null<String>`, by its dotted path (`helix.draw.ShaderRules.check`), run on the compiled shader while the
		program builds: it returns why the shader breaks a library's rules, which stops the build at the call, or null. Optional; no check
		by default. */
	@:optional var check:String;

	/** The asset path of a file holding the compiled shader (`shaders/lit.shader`), which `Shaders.watch` watches, so the shader is
		replaced in place when the file changes. Optional; no file by default.

		The shader's `filePath` is this path whatever the build. The file is written under the directory `-D helix-asset-directory`
		names (each target's build names its own, as `web/assets` and `native/assets`), with that target's dialects; a build without the
		define, as a release build, writes none, and nothing ever changes it, so a watch of it waits and costs nothing. Variants compiled
		with a file write one file for the whole set. */
	@:optional var file:String;
}
