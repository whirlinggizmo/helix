import haxe.io.Bytes;
import haxe.io.Float32Array;
import haxe.io.Int32Array;
import helix.raylib.*;
import helix.raylib.Raylib.*;

/** Checks the numbers a shader's uniform takes from a value (`SetShaderValue`, `SetShaderValueV`): an array, a number, a vector, a
	`Color` for a vec4, and a `haxe.io` typed array's or `Bytes`' memory read as the uniform's type, a view into part of its buffer
	among them; any other value gives none. */
@:access(helix.raylib.modules.RModels)
class ShaderValueTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function numbers(value:Dynamic, uniformType:Int):String {
		return helix.raylib.modules.RModels.numbers(value, uniformType).join(",");
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		check(numbers([1.0, 2.5], SHADER_UNIFORM_VEC2) == "1,2.5", 'an array: ${numbers([1.0, 2.5], SHADER_UNIFORM_VEC2)}');
		check(numbers(2, SHADER_UNIFORM_FLOAT) == "2", "a number");
		check(numbers(new Vector3(1, 2, 3), SHADER_UNIFORM_VEC3) == "1,2,3", "a vector");
		check(numbers(new Color(255, 0, 51, 255), SHADER_UNIFORM_VEC4) == "1,0,0.2,1",
			'a color for a vec4: ${numbers(new Color(255, 0, 51, 255), SHADER_UNIFORM_VEC4)}');

		var floats = new Float32Array(3);
		floats[0] = 1;
		floats[1] = .5;
		floats[2] = -2;
		check(numbers(floats, SHADER_UNIFORM_VEC3) == "1,0.5,-2", 'a Float32Array: ${numbers(floats, SHADER_UNIFORM_VEC3)}');
		check(numbers(floats.sub(1, 2), SHADER_UNIFORM_VEC2) == "0.5,-2", 'a view into part of its buffer: ${numbers(floats.sub(1, 2), SHADER_UNIFORM_VEC2)}');

		var ints = new Int32Array(2);
		ints[0] = 3;
		ints[1] = -4;
		check(numbers(ints, SHADER_UNIFORM_IVEC2) == "3,-4", 'an Int32Array for an ivec2: ${numbers(ints, SHADER_UNIFORM_IVEC2)}');

		var bytes = Bytes.alloc(8);
		bytes.setFloat(0, .25);
		bytes.setFloat(4, 4);
		check(numbers(bytes, SHADER_UNIFORM_VEC2) == "0.25,4", 'Bytes for a vec2, as floats: ${numbers(bytes, SHADER_UNIFORM_VEC2)}');
		bytes.setInt32(0, 7);
		bytes.setInt32(4, -1);
		check(numbers(bytes, SHADER_UNIFORM_IVEC2) == "7,-1", 'Bytes for an ivec2, as ints: ${numbers(bytes, SHADER_UNIFORM_IVEC2)}');

		check(numbers({x: 1}, SHADER_UNIFORM_FLOAT) == "", "any other value gives none");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
