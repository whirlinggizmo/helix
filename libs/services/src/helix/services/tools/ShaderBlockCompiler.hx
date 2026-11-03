package helix.services.tools;

import haxe.macro.Expr;

/** Provides build-time macros making a shared block's values from its declaration alone, so no shader that shares it is needed to make
	it (a renderer's camera before any material is loaded). They live here, apart from `ShaderBlockValues`, so typing them never types
	the values classes in the macro context (`Shader`'s note on macros). */
class ShaderBlockCompiler {
	/** Makes values for a shared block from its declaration alone, a file the shaders that share it include, compiled while the program
		builds, so no shader that shares it is needed to make it (a renderer's camera before any material is loaded).

		```haxe
		var camera = ShaderBlockCompiler.compile("camera.glsl", "Camera");
		```
		@param file  The GLSL file declaring the block (a named `uniform` block, or the loose uniforms `uniforms` names), relative to the
			file holding the call.
		@param blockName  The block's name.
		@param uniforms  Optional. Loose uniforms in the file gathered into the block, as `ShaderSharedBlock.uniforms`.
		@return  New values for the block, every member 0: each evaluation makes a new one. */
	public static macro function compile(file:String, blockName:String, ?uniforms:Array<String>):ExprOf<helix.services.shaders.ShaderBlockValues> {
		var pos = haxe.macro.Context.currentPos();
		var declared = helix.services.shaders.ShaderMacros.file(file, pos);
		return block({name: declared.name, text: '#include "${haxe.io.Path.withoutDirectory(declared.name)}"\n'}, haxe.io.Path.directory(declared.name),
			blockName, uniforms, pos);
	}

	/** Makes values for a shared block from its declaration as GLSL text known while the program builds, as `Shader.compileText` takes
		text (a literal, or a class's string constant), so a library keeping its GLSL in constants needs no file.

		@param text  The GLSL declaring the block.
		@param blockName  The block's name.
		@param uniforms  Optional. Loose uniforms in the text gathered into the block.
		@return  New values for the block, every member 0. */
	public static macro function compileText(text:ExprOf<String>, blockName:String, ?uniforms:Array<String>):ExprOf<helix.services.shaders.ShaderBlockValues> {
		var pos = haxe.macro.Context.currentPos();
		var declared = helix.services.shaders.ShaderMacros.foldText(text);
		if (declared == null)
			haxe.macro.Context.error("shader: the block's text is known while the program builds", pos);
		return block({name: declared.name, text: declared.text + "\n"}, haxe.io.Path.directory(declared.name), blockName, uniforms, pos);
	}

	#if macro
	// A program of the declaration alone, the block shared: new values over it, each evaluation its own.
	static function block(declaration:{name:String, text:String}, directory:String, blockName:String, uniforms:Null<Array<String>>, pos:Position):Expr {
		var vertex = {name: declaration.name, text: '#version 450\n${declaration.text}void main() { gl_Position = vec4(0.0); }\n'};
		var fragment = {
			name: declaration.name,
			text: "#version 450\nlayout(location = 0) out vec4 helix_color;\nvoid main() { helix_color = vec4(0.0); }\n"
		};
		var shader = helix.services.shaders.ShaderMacros.shaderExpr(vertex, fragment, {
			includeDirectories: [directory],
			shared: [uniforms == null ? {name: blockName} : {name: blockName, uniforms: uniforms}]
		}, pos);
		return macro new helix.services.shaders.ShaderBlockValues($shader, $v{blockName});
	}
	#end
}
