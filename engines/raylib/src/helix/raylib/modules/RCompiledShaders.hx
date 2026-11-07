package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Answers.*;
#end

/** Provides the loads of shaders compiled ahead of time by `CompileShaderFile`: from a file, or from the compiled data in memory.

	`helix.raylib.extras.Shaders` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RCompiledShaders {
	#if !macro
	/** Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See
		`LoadCompiledShaderFromData` for making one from compiled data in memory.

		@param compiledShaderFileName  The compiled shader's file.
		@param loaded  Receives the shader.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader->Void, ?failed:String->Void):Void {
		RFilesAsync.LoadFileDataAsync(compiledShaderFileName, bytes -> {
			var shader = make(bytes, compiledShaderFileName);
			if (shader == null)
				refuse("LoadCompiledShaderAsync", '$compiledShaderFileName isn\'t a compiled shader', failed);
			else
				loaded(shader);
		}, error -> refuse("LoadCompiledShaderAsync", error, failed));
	}

	/** Returns a shader made from a compiled shader's data, replacing raylib's `LoadShaderFromMemory`. See `LoadCompiledShaderAsync` for
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
