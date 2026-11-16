package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.SyncLoads;
import helix.raylib.internal.Answers.*;
#end

/** Provides the loads of shaders compiled ahead of time by `CompileShaderFile`: from a file, at once or asynchronously, or from the
	compiled data in memory.

	`helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RCompiledShaders {
	#if !macro
	/** Loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See `LoadCompiledShaderFromMemory`
		for making one from compiled data in memory.

		Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as
		`<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

		```hxml
		--macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
		```

		A file ensured (`EnsureAssetAsync`, `helix.raylib.extras.Assets`), or brought in by an async load this run, loads at once.
		Natively any other file is read during the call. In a page it can't be, as the browser reads its cache only asynchronously: the
		load logs why and gives an empty shader (id 0). See `LoadCompiledShaderAsync` for loading it asynchronously.

		@param compiledShaderFileName  The compiled shader's file.
		@return  The shader, the program's until `UnloadShader`, or an empty one (id 0) when the file isn't a compiled shader, with a
			warning. */
	static function LoadCompiledShader(compiledShaderFileName:String):Shader {
		var path = RCore.normalize(compiledShaderFileName);
		return SyncLoads.load(path, Runtime.compiledShaders.exists(path) || Runtime.files.exists(path), () -> {
			var value = Runtime.compiledShaders.exists(path) ? Runtime.compiledShaders.get(path) : read(Runtime.files.get(path));
			if (value != null)
				return make(value, compiledShaderFileName);
			Runtime.log(LOG_WARNING, 'SHADER: [$compiledShaderFileName] Failed to load: not a compiled shader');
			return empty();
		},
			(loaded, failed) -> LoadCompiledShaderAsync(compiledShaderFileName, loaded, failed), empty);
	}

	/** Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See
		`LoadCompiledShaderFromMemory` for making one from compiled data in memory.

		Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as
		`<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

		```hxml
		--macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
		```

		An asynchronously loaded shader is invalid until `loaded` is called.

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
			var value = read(Runtime.files.get(path));
			if (value == null)
				refuse("LoadCompiledShaderAsync", '$compiledShaderFileName isn\'t a compiled shader', failed);
			else
				loaded(make(value, compiledShaderFileName));
		});
	}

	/** Returns a shader made from a compiled shader's data, replacing raylib's `LoadShaderFromMemory`. See `LoadCompiledShader` for
		loading one from a file.

		@param compiledShaderData  The compiled shader, as `CompileShaderFile` writes it.
		@return  The shader, or an empty one (id 0) when the data isn't a compiled shader, with a warning. */
	static function LoadCompiledShaderFromMemory(compiledShaderData:haxe.io.Bytes):Shader {
		var value = read(compiledShaderData);
		if (value != null)
			return make(value, "compiled shader data");
		Runtime.log(LOG_WARNING, "SHADER: Failed to load: not a compiled shader");
		return empty();
	}

	// The shader a load that fails gives: id 0, with no locations.
	static function empty():Shader {
		return new Shader(0, [for (_ in 0...32) -1], null);
	}

	// A compiled shader's data read to the value a shader is made of (`make`); null when the data isn't a compiled shader.
	static function read(data:haxe.io.Bytes):Null<Dynamic> {
		var value:Dynamic = try haxe.Json.parse(data.toString()) catch (_:Dynamic) null;
		if (value == null || value.kind != "shader" || value.source == null || !Std.isOfType(value.source.attributes, Array))
			return null;
		return value;
	}

	// A shader of a compiled shader's value (`read`), its uniforms' initializers written as GL sets them when it links.
	static function make(value:Dynamic, name:String):Shader {
		var shader = RModels.makeShader(new helix.services.shaders.Shader(value.source, name));
		// Its shadow variant, made a program by the shadow pass's first draw through it (Shadows).
		shader.program.casterSource = value.shadow;
		var initials:Array<Dynamic> = Std.isOfType(value.initials, Array) ? value.initials : [];
		for (i in initials)
			shader.program.writeNamed(i.name, [for (n in (i.numbers : Array<Dynamic>)) (n : Float)]);
		// A shader reading a material's values (lights.glsl's, pbr.glsl's) has them written by each draw.
		if (helix.raylib.internal.Surfaces.declares(shader.program.shader))
			helix.raylib.internal.Surfaces.install();
		return shader;
	}
	#end
}
