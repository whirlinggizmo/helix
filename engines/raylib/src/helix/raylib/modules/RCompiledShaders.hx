package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Answers.*;
#end

/** Provides the loads of shaders compiled ahead of time by `CompileShaderFile`: from a file, or from the compiled data in memory.

	`helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RCompiledShaders {
	#if !macro
	/** Loads a shader compiled ahead of time by `CompileShaderFile`, and returns it, in place of raylib's `LoadShader`. See
		`LoadCompiledShaderFromData` for making one from compiled data in memory.

		Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as
		`<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

		```hxml
		--macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
		```

		@param compiledShaderFileName  The compiled shader's file.
		@return  The shader, or an empty one (id 0) when it couldn't be loaded. Why it couldn't is logged. */
	@:waits
	static function LoadCompiledShader(compiledShaderFileName:String, answer:Shader->Void):Void {
		LoadCompiledShaderAsync(compiledShaderFileName, answer, failing("LoadCompiledShader", answer, new Shader(0, [for (_ in 0...32) -1], null)));
	}

	/** Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See
		`LoadCompiledShaderFromData` for making one from compiled data in memory.

		Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as
		`<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

		```hxml
		--macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
		```

		@param compiledShaderFileName  The compiled shader's file.
		@param loaded  Receives the shader.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader->Void, ?failed:String->Void):Void {
		// One of the program's files, fetched as a texture's or a model's is.
		var path = RCore.normalize(compiledShaderFileName);
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadCompiledShaderAsync", error, failed);
				return;
			}
			var shader = make(Runtime.files.get(path), compiledShaderFileName);
			if (shader == null)
				refuse("LoadCompiledShaderAsync", '$compiledShaderFileName isn\'t a compiled shader', failed);
			else
				loaded(shader);
		});
	}

	/** Returns a shader made from a compiled shader's data, replacing raylib's `LoadShaderFromMemory`. See `LoadCompiledShader` for
		loading one from a file.

		@param compiledShaderData  The compiled shader, as `CompileShaderFile` writes it.
		@return  The shader, or an empty one (id 0) when the data isn't a compiled shader, with a warning. */
	static function LoadCompiledShaderFromData(compiledShaderData:haxe.io.Bytes):Shader {
		var shader = make(compiledShaderData, "compiled shader data");
		if (shader != null)
			return shader;
		Runtime.log(LOG_WARNING, "SHADER: Failed to load: not a compiled shader");
		return new Shader(0, [for (_ in 0...32) -1], null);
	}

	// A shader of a compiled shader's data, its uniforms' initializers written as GL sets them when it links; null when the data isn't one.
	static function make(data:haxe.io.Bytes, name:String):Null<Shader> {
		var value:Dynamic = try haxe.Json.parse(data.toString()) catch (_:Dynamic) null;
		if (value == null || value.kind != "shader" || value.source == null || !Std.isOfType(value.source.attributes, Array))
			return null;
		var shader = RModels.makeShader(new helix.services.shaders.Shader(value.source, name));
		var initials:Array<Dynamic> = Std.isOfType(value.initials, Array) ? value.initials : [];
		for (i in initials)
			shader.program.writeNamed(i.name, [for (n in (i.numbers : Array<Dynamic>)) (n : Float)]);
		return shader;
	}
	#end
}
