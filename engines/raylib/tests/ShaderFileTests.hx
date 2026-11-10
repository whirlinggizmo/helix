import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;

/** Checks the loads of a shader compiled ahead of time by `CompileShaderFile` (helix.py compiles tests/shaders' glow into
	build/tests/glow.shader first, and the build embeds it): `LoadCompiledShaderAsync` answers at a later poll with the shader, its
	locations raylib's and its uniform's initializer written, and a draw through it uses it; `LoadCompiledShaderFromData` makes the
	same shader at once; and a file or data that isn't a compiled shader, or a file that isn't there, is refused with why. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.Shader)
class ShaderFileTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function pump(until:() -> Bool):Void {
		for (_ in 0...10000) {
			if (until())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
		}
		throw "never answered";
	}

	static function load(fileName:String):{shader:Null<Shader>, error:Null<String>} {
		var answer:{shader:Null<Shader>, error:Null<String>} = null;
		LoadCompiledShaderAsync(fileName, s -> answer = {shader: s, error: null}, e -> answer = {shader: null, error: e});
		check(answer == null, '$fileName: not answered during the call');
		pump(() -> answer != null);
		return answer;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		// The files: the compiled shader the build embeds, and a text file, read as a program's files are.
		var files = new FakeFileSystem();
		files.write("glow.shader", haxe.Resource.getBytes("glow.shader"), () -> {}, e -> throw e);
		files.write("notes.txt", Bytes.ofString("not a shader"), () -> {}, e -> throw e);
		Runtime.polled.push(files);
		var data = new FakeFileSystem();
		Runtime.polled.push(data);
		Runtime.saves = new helix.services.saves.Saves(data);
		Runtime.polled.push(Runtime.saves);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);

		var loaded = load("glow.shader");
		check(loaded.shader != null, "a compiled shader: loaded");
		var shader = loaded.shader,
			made = LoadCompiledShaderFromData(haxe.Resource.getBytes("glow.shader"));
		check(made.id != 0
			&& haxe.Json.stringify(made.program.shader.source) == haxe.Json.stringify(shader.program.shader.source)
			&& made.locs.join(",") == shader.locs.join(","),
			"from its data: the same shader, at once");
		check(shader.locs[SHADER_LOC_VERTEX_POSITION] == 0
			&& shader.locs[SHADER_LOC_MATRIX_MVP] >= 0
			&& shader.locs[SHADER_LOC_COLOR_DIFFUSE] >= 0
			&& shader.locs[SHADER_LOC_MAP_ALBEDO] >= 0,
			"its locations: raylib's");

		// Drawn through: the uniform's initializer written, and the draw the shader's.
		var model = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		model.materials[0].shader = shader;
		DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
		var pass = Runtime.frame.pass,
			draw:Dynamic = pass.draws[pass.draws.length - 1];
		var p:Program = shader.program;
		var place = p.shader.findUniformPlace(p.shader.findUniform("glow"));
		var bytes:Bytes = draw.uniforms[place.blockSlot];
		check(bytes.getFloat(place.offset) == 0.5, "a uniform's initializer: written");
		check([for (_ => id in p.pipelines) id].indexOf(draw.pipeline) >= 0, "a draw through it: its pipeline");

		// Refused, with why.
		var wrong = load("notes.txt");
		check(wrong.shader == null && wrong.error.indexOf("isn't a compiled shader") >= 0, "a file that isn't a compiled shader: refused");
		var missing = load("none.shader");
		check(missing.shader == null && missing.error != null, "a file that isn't there: refused");
		check(LoadCompiledShaderFromData(Bytes.ofString("not a shader")).id == 0, "data that isn't a compiled shader: an empty shader");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
