package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Answers.*;
#end

/** Provides the load of a shader compiled ahead of time, for a shader the program's build doesn't hold.

	`helix.raylib.extras.Shaders` forwards to it (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RShadersAsync {
	#if !macro
	/** Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`. See `LoadShader` for loading a shader the build holds.

		The file holds the shader for every target, so the same file loads in a page and natively.

		@param fileName  The compiled shader's file.
		@param loaded  Receives the shader.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadShaderAsync(fileName:String, loaded:Shader->Void, ?failed:String->Void):Void {
		RFilesAsync.LoadFileDataAsync(fileName, bytes -> {
			var value:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
			if (value == null || value.kind != "shader" || value.source == null || !Std.isOfType(value.source.attributes, Array)) {
				refuse("LoadShaderAsync", '$fileName isn\'t a compiled shader', failed);
				return;
			}
			var shader = RModels.makeShader(new helix.services.shaders.Shader(value.source, fileName));
			// Each uniform given an initializer in the GLSL starts at it, as GL sets one when it links.
			var initials:Array<Dynamic> = Std.isOfType(value.initials, Array) ? value.initials : [];
			for (i in initials)
				shader.program.writeNamed(i.name, [for (n in (i.numbers : Array<Dynamic>)) (n : Float)]);
			loaded(shader);
		}, error -> refuse("LoadShaderAsync", error, failed));
	}
	#end
}
