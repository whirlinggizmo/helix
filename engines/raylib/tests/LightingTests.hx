import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;

/** Checks the scene's lights (the Lighting extra's `CreateLight`), on graphics that count what is live: each draw through a
	shader declaring `lights` is lit by the lights reaching its bounds most, 8 of more than 8, best first, the rest off; a range keeps a
	far lamp off a draw; a spot light's cone keeps it off what it points away from; more than 4 lights light one draw; `UnloadLight`
	removes a light; a light moves by its fields alone; a shader of 4 lights gets the best 4; `DrawMeshInstanced` scores against all
	its instances; immediate shapes drawn through a lit shader are lit by their vertices' bounds; and the light's fields (intensity,
	range, cone) reach the next draw once assigned, each clamped to its range there. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.extras.Light)
@:access(helix.raylib.Shader)
@:access(helix.services.shaders)
class LightingTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The last draw recorded.
	static function lastDraw():Dynamic {
		var pass = Runtime.frame.pass;
		return pass.draws[pass.draws.length - 1];
	}

	// Where a block member's element is in the last draw's blocks: its bytes and offset.
	static function member(p:Program, name:String, elementIndex:Int):{bytes:Bytes, offset:Int} {
		for (block in @:privateAccess p.shader.blocks)
			for (m in block.members)
				if (m.glslName == name)
					return {bytes: lastDraw().uniforms[block.indices[0]], offset: m.offset + elementIndex * m.stride};
		throw 'no $name';
	}

	static function drawnInt(p:Program, name:String, i:Int):Int {
		var m = member(p, name, i);
		return m.bytes.getInt32(m.offset);
	}

	static function drawnFloat(p:Program, name:String, i:Int, component = 0):Float {
		var m = member(p, name, i);
		return m.bytes.getFloat(m.offset + component * 4);
	}

	// The last draw's lights that are on, by their positions' x, in the order written.
	static function lit(p:Program, slots = 8):Array<Float>
		return [
			for (i in 0...slots)
				if (drawnInt(p, "lights.enabled", i) == 1) drawnFloat(p, "lights.position", i)
		];

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var shader = LoadLightingShader();
		var p = shader.program;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].shader = shader;

		// Ten lamps of one color, each 2 units further from the cube than the last, every one reaching it: the 8 nearest light it, the
		// nearest first.
		var lamps = [
			for (i in 0...10) {
				var lamp = CreateLight(LIGHT_POINT, new Vector3(1 + i * 2, 0, 0), Vector3Zero(), WHITE, shader);
				lamp.range = 100;
				lamp;
			}
		];
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "1,3,5,7,9,11,13,15", "the 8 lamps reaching the cube most light it, the nearest first");
		check(drawnFloat(p, "lights.range", 0) == 100 && drawnFloat(p, "lights.intensity", 0) == 1,
			"a lamp's range and intensity written into the draw's lights");
		check(lamps[0].intensity == 1 && lamps[0].range == 100 && lamps[0].innerAngle == 30 && lamps[0].outerAngle == 45,
			"a light's intensity 1 and cone of 30 and 45 degrees by default");

		// A brighter lamp further off wins a place: the score is its brightness through its falloff.
		lamps[9].intensity = 10000;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p)[0] == 19
			&& lit(p).length == 8
			&& drawnFloat(p, "lights.intensity", 0) == 10000, "a lamp made brighter reaches the cube most, first");
		lamps[9].intensity = 1;

		// Out of range: a negative intensity lights nothing and a negative range is none, each clamped to 0 where read, the field kept.
		lamps[0].intensity = -5;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "3,5,7,9,11,13,15,17"
			&& lamps[0].intensity == -5, "a negative intensity clamped to 0: the lamp lights nothing");
		lamps[0].intensity = 1;
		lamps[0].range = -3;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p)[0] == 1 && drawnFloat(p, "lights.range", 0) == 0 && lamps[0].range == -3, "a negative range clamped to 0: no limit");

		// A lamp's range keeps it off a draw past it.
		for (i in 0...10)
			lamps[i].range = 3;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "1,3", "a range keeps the far lamps off the cube");
		DrawModel(cube, new Vector3(20, 0, 0), 1, WHITE);
		check(lit(p).join(",") == "19,17", "the same lamps light a cube near the far ones");

		// A light moved by its fields alone: the next draw reads where it is.
		lamps[9].position = new Vector3(0, 1.5, 0);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "1,0,3"
			&& drawnFloat(p, "lights.position", 1, 1) == 1.5, "a lamp moved by its position alone lights the draw from there");
		lamps[9].enabled = false;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "1,3", "a lamp turned off by its field lights nothing");

		// UnloadLight: out of the scene.
		UnloadLight(lamps[0]);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).join(",") == "3", "an unloaded lamp lights nothing");
		for (lamp in lamps)
			UnloadLight(lamp);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).length == 0, "with every light unloaded, the draw's lights are all off");

		// Six lights at once: more than rlights' 4 light one draw.
		var six = [
			for (i in 0...6)
				CreateLight(LIGHT_POINT, new Vector3(i, 2, 0), Vector3Zero(), WHITE, shader)
		];
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).length == 6, "six lights light one draw");
		// A shader of 4 lights, as raylib's examples' lighting.fs: the best 4 of them.
		var four = LoadCompiledShaderFromMemory(haxe.Resource.getBytes("four_lights.shader"));
		cube.materials[0].shader = four;
		six[5].range = 10;
		six[5].intensity = 50;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(four.program, 4).length == 4 && lit(four.program, 4)[0] == 5, "a shader of 4 lights gets the 4 reaching the draw most");
		cube.materials[0].shader = shader;
		for (light in six)
			UnloadLight(light);

		// A directional light reaches everything, a spot light only what its cone covers.
		var sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(0, 10, 0), Vector3Zero(), WHITE, shader);
		var spot = CreateLight(LIGHT_SPOT, new Vector3(0, 5, 0), new Vector3(0, 0, 0), WHITE, shader);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drawnInt(p, "lights.type", 1) == LIGHT_SPOT
			&& Math.abs(drawnFloat(p, "lights.innerCosine", 1) - Math.cos(30 * DEG2RAD)) < 1e-6
			&& Math.abs(drawnFloat(p, "lights.outerCosine", 1) - Math.cos(45 * DEG2RAD)) < 1e-6,
			"a spot light with no cone set: its default cone, 30 and 45 degrees");
		spot.innerAngle = 10;
		spot.outerAngle = 20;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lit(p).length == 2, "a spot light pointing at the cube lights it, with the sun");
		check(drawnInt(p, "lights.type", 1) == LIGHT_SPOT
			&& Math.abs(drawnFloat(p, "lights.innerCosine", 1) - Math.cos(10 * DEG2RAD)) < 1e-6
			&& Math.abs(drawnFloat(p, "lights.outerCosine", 1) - Math.cos(20 * DEG2RAD)) < 1e-6,
			"a spot light's cone written, its cosines");
		// Out of range: the outer angle clamped to 89.9, the inner to 0 and to the outer.
		spot.outerAngle = 120;
		spot.innerAngle = -10;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(Math.abs(drawnFloat(p, "lights.outerCosine", 1) - Math.cos(89.9 * DEG2RAD)) < 1e-6
			&& drawnFloat(p, "lights.innerCosine", 1) == 1,
			"an outer angle over 89.9 clamped to 89.9, a negative inner angle to 0");
		spot.outerAngle = 20;
		spot.innerAngle = 30;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(Math.abs(drawnFloat(p, "lights.innerCosine", 1) - Math.cos(20 * DEG2RAD)) < 1e-6, "an inner angle past the outer clamped to the outer");
		DrawModel(cube, new Vector3(6, 0, 0), 1, WHITE);
		check(lit(p).join(",") == "0"
			&& drawnInt(p, "lights.type", 0) == LIGHT_DIRECTIONAL, "a cube outside the spot's cone: the sun alone");
		UnloadLight(spot);

		// DrawMeshInstanced: scored against every instance's bounds, through its skinned or instanced shader's own lights.
		var instanced = LoadCompiledShaderFromMemory(haxe.Resource.getBytes("instanced_lights.shader"));
		instanced.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocationAttrib(instanced, "instanceTransform");
		var material = LoadMaterialDefault();
		material.shader = instanced;
		var lamp = CreateLight(LIGHT_POINT, new Vector3(10, 0, 0), Vector3Zero(), WHITE, shader);
		lamp.range = 2;
		var mesh = GenMeshCube(1, 1, 1);
		DrawMeshInstanced(mesh, material, [MatrixTranslate(-10, 0, 0)], 1);
		check(lit(instanced.program).join(",") == "0", "one instance far from the lamp: the sun alone");
		DrawMeshInstanced(mesh, material, [MatrixTranslate(-10, 0, 0), MatrixTranslate(10, 0, 0)], 2);
		check(lit(instanced.program).length == 2, "an instance by the lamp: the lamp lights the draw");

		// Shapes drawn through a lit shader: scored against their vertices.
		BeginShaderMode(shader);
		DrawCube(new Vector3(10, 0, 0), 1, 1, 1, WHITE);
		rlDrawRenderBatchActive();
		check(lit(p).length == 2, "a cube drawn by the lamp through the lit shader: lit by it and the sun");
		DrawCube(new Vector3(-10, 0, 0), 1, 1, 1, WHITE);
		rlDrawRenderBatchActive();
		check(lit(p).join(",") == "0", "a cube drawn far from it: the sun alone");
		EndShaderMode();
		UpdateLightValues(shader, lamp);

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
