package helix.render.effects;

/** Represents an effect over a whole frame in a `PostProcess` chain: `BloomEffect`, `ColorGradeEffect`, `FxaaEffect`, a `ShaderEffect`,
	or a program's own.

	An effect of its own extends this, says whether it works on linear light (`linear`) and what intermediate targets it needs
	(`intermediates`), draws into them in `drawIntermediates`, and draws its result in `draw`, both through its `ScreenFrame`.

	**A screen shader** (`ShaderEffect`, `ScreenFrame.drawPass`) is compiled by `compileShader` (a fragment stage over the screen
	triangle) or `compileShaderStages`. The chain fills, by name, what it declares: `sourceTexture` (sampler2D, the frame it reads),
	`sourceSize` (vec2, its size in texels) and `time` (float, `PostProcess.draw`'s seconds); the view's `linearTarget`
	(`View3D`) when it includes `<helix/render/shaders/view.glsl>`. */
abstract class ScreenEffect {
	#if !macro
	/** Gets or sets a value indicating whether the chain draws it: true until set. */
	public var enabled:Bool = true;

	/** Gets a value indicating whether it works on linear light, before the chain's resolve, rather than on encoded colors after it. */
	public final linear:Bool;

	/** Gets the intermediate targets it draws through before its result, each its size as a fraction of the frame's each way (0.5 half,
		at least a pixel): empty for an effect of one pass. The chain makes them RGBA16F for a linear effect, RGBA8 otherwise. */
	public final intermediates:Array<Float> = [];

	/** Creates an effect.

		@param linear  Whether it works on linear light, before the resolve. */
	function new(linear:Bool) {
		this.linear = linear;
	}

	/** Draws its passes before its result into the frame's intermediates; nothing for an effect of one pass.

		@param frame  What it draws from and into. */
	public function drawIntermediates(frame:ScreenFrame):Void {}

	/** Draws its result over the target the chain gives it, reading the frame's source and its intermediates.

		@param frame  What it draws from. */
	public function draw(frame:ScreenFrame):Void {}
	#end

	/** Compiles a fragment stage over the screen triangle, for a pass over a whole frame (`ShaderEffect`, `ScreenFrame.drawPass`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or
		`#version 450` (Vulkan's), the screen triangle's vertex stage given in the same form; GLSL ES 100 is not taken. The vertex stage
		passes `texCoord` (vec2), 0 to 1 across the frame, v down, read by name.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShader(fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: ScreenEffect.compileShader is not yet built (stage 5, post-processing)";
	}

	/** Compiles a vertex and a fragment stage, both the program's, for a pass over a whole frame (`ShaderEffect`, `ScreenFrame.drawPass`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or
		`#version 450`. The vertex stage is drawn for the three corners of one triangle covering the frame.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShaderStages(vertex:String, fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: ScreenEffect.compileShaderStages is not yet built (stage 5, post-processing)";
	}
}
