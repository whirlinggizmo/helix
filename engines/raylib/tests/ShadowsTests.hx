import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.extras.Materials.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;

/** Checks the Lighting extra's shadows on graphics that count what is live: casting off until `EnableLightShadows` turns it on, and
	a light's `shadows` set alone casting nothing; the shadows' defaults filled, out-of-range fields clamped where the pass reads them,
	and a field written after casting is on taking effect at the next pass; a pass made for each map
	of each light casting (a directional light's cascades, a spot light's one map, a point light's six faces) into one shadow map of
	their layers, as large as the largest asked, each pass the whole layer; the casters drawn into the maps their bounds reach and
	nowhere else, through a depth-only pipeline, a cut-out material's alpha cutoff and a program's own vertex stage's uniforms reaching
	its shadow draw, a posed model cast through its caster's skinned twin, the batch cast too; a fifth light's shadows refused with a
	warning and `EnableLightShadows` returning false, a light turned off freeing its place and keeping its options; the lit draws after the pass given the shadows (their
	lights' shadow, the matrices, the strengths, the map), and `shadowed` false written for a material shadows don't fall on; a frame
	without the pass keeping the last one's shadows. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.internal.Shadows)
@:access(helix.raylib.extras.Light)
@:access(helix.raylib.Shader)
@:access(helix.raylib.Model)
@:access(helix.raylib.Mesh)
@:access(helix.services.shaders)
class ShadowsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The frame's shadow passes, in their order.
	static function shadowPasses():Array<Dynamic>
		return [for (p in Runtime.frame.passes) if ((p : Dynamic).target < -1) p];

	// Where a block member's element is in a draw's blocks: its bytes and offset.
	static function member(p:Program, draw:Dynamic, name:String, elementIndex:Int):{bytes:Bytes, offset:Int} {
		for (block in @:privateAccess p.shader.blocks)
			for (m in block.members)
				if (m.glslName == name)
					return {bytes: draw.uniforms[block.indices[0]], offset: m.offset + elementIndex * m.stride};
		throw 'no $name';
	}

	static function drawnInt(p:Program, draw:Dynamic, name:String, i = 0):Int {
		var m = member(p, draw, name, i);
		return m.bytes.getInt32(m.offset);
	}

	static function drawnFloat(p:Program, draw:Dynamic, name:String, i = 0, component = 0):Float {
		var m = member(p, draw, name, i);
		return m.bytes.getFloat(m.offset + component * 4);
	}

	// The last draw recorded on the screen.
	static function lastDraw():Dynamic {
		var draws:Array<Dynamic> = Runtime.frame.pass.draws;
		return draws[draws.length - 1];
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) <= 1e-5 * (1 + Math.abs(b));

	static function main():Void {
		SetTraceLogLevel(LOG_WARNING);
		var warnings:Array<String> = [];
		Runtime.logCallback = (level, text) -> warnings.push(text);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var frame = Runtime.frame;
		var shader = LoadLightingShader();
		var p = shader.program;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].shader = shader;
		var camera = new Camera3D(new Vector3(0, 5, 10), Vector3Zero(), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		// Casting off until EnableLightShadows; a light's shadows every default, the same options at each read.
		var sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(-4, 8, 0), Vector3Zero(), WHITE, shader);
		check(!IsLightCastingShadows(sun), "a light casts no shadows until EnableLightShadows");
		var o = sun.shadows;
		check(o != null && o == sun.shadows && o.mapSize == 2048 && o.distance == 50 && o.cascadeCount == 1 && o.bias == 1 && o.slopeBias == 4
			&& o.normalOffset == 1 && o.softness == 1 && o.strength == 1 && o.bounds == null,
			"a light's shadows: every default, the same options at each read");
		o.cascadeCount = 2;
		check(!IsLightCastingShadows(sun), "a light's shadows set alone cast nothing");
		BeginShadowMode(camera);
		check(shadowPasses().length == 0, "no shadow pass for a light whose shadows are set but off");
		EndShadowMode();
		frame.draw(800, 450, true);

		// Out of range: each option clamped where the pass reads it, the field kept as written.
		o.mapSize = 3000;
		o.cascadeCount = 9;
		o.strength = 2;
		o.softness = -1;
		o.bias = -1;
		check(EnableLightShadows(sun) && IsLightCastingShadows(sun), "EnableLightShadows turns casting on, returning true");
		BeginShadowMode(camera);
		check(shadowPasses().length == 4 && shadowPasses()[0].width == 2048, "a map size of 3000 read as 2048, 9 cascades as 4");
		check(helix.raylib.internal.Shadows.strengths[0] == 1
			&& helix.raylib.internal.Shadows.params[0] == 32 * 4
			&& helix.raylib.internal.Shadows.params[1] == 0,
			"a strength of 2 read as 1, a softness and a bias of -1 as 0");
		check(o.mapSize == 3000 && o.cascadeCount == 9 && o.strength == 2 && o.softness == -1, "the fields kept as written");
		EndShadowMode();
		frame.draw(800, 450, true);
		o.mapSize = 100;
		BeginShadowMode(camera);
		check(shadowPasses()[0].width == 256, "a map size under 256 read as 256");
		EndShadowMode();
		frame.draw(800, 450, true);

		// A field written after casting is on: taken at the next pass.
		o.mapSize = 1024;
		o.cascadeCount = 2;
		o.distance = 30;
		o.strength = 0.75;
		o.softness = 1;
		o.bias = 1;
		BeginShadowMode(camera);
		check(shadowPasses().length == 2 && shadowPasses()[0].width == 1024 && helix.raylib.internal.Shadows.strengths[0] == 0.75,
			"the sun's map size, cascades and strength written while casting, read by the next pass");
		o.strength = 1;
		EndShadowMode();
		frame.draw(800, 450, true);
		graphics.shadowPasses.resize(0);

		// A pass for each map: the sun's two cascades, a lamp's six faces, a spot's one map, all layers of one shadow map.
		var lamp = CreateLight(LIGHT_POINT, new Vector3(2, 2, 0), Vector3Zero(), WHITE, shader);
		lamp.range = 6;
		lamp.shadows.mapSize = 512;
		lamp.shadows.strength = 0.5;
		EnableLightShadows(lamp);
		var spot = CreateLight(LIGHT_SPOT, new Vector3(0, 4, 0), Vector3Zero(), WHITE, shader);
		spot.innerAngle = 10;
		spot.outerAngle = 15;
		EnableLightShadows(spot);
		BeginShadowMode(camera);
		var passes = shadowPasses();
		check(passes.length == 9, "9 shadow passes: 2 cascades, 6 faces and a spot's map");
		var map = @:privateAccess helix.raylib.internal.Shadows.map;
		check(graphics.shadowMaps.get(map).join(",") == "2048,9", "one shadow map, as large as the largest asked for, of 9 layers");
		check(passes[0].width == 2048 && passes[0].draws.length == 0, "a pass the size of the map, empty until a caster is drawn");

		// A cube at the origin: cast into the cascades and the spot's map, and the lamp's faces looking toward it, not the screen.
		var screenDraws = frame.passes[frame.passes.length - 1].draws.length;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		var drawn = [for (q in passes) q.draws.length];
		check(drawn[1] == 1 && drawn[8] == 1, "the cube cast into the cascade holding it and the spot's map");
		var faces = drawn.slice(2, 8);
		check(faces[1] == 1 && faces[3] == 1 && faces[0] == 0 && faces[2] == 0, "the cube cast into the lamp's faces toward -x and -y, not those away from it");
		check(frame.passes[frame.passes.length - 1].draws.length == screenDraws, "a caster drawn nowhere else");
		var shadowDraw:Dynamic = passes[8].draws[0];
		var desc = graphics.pipelines.get(shadowDraw.pipeline);
		check(desc.depthOnly && desc.depthTest == LessEqual && desc.depthWrite, "cast through a depth-only pipeline, depth tested and written");
		check([for (q in passes) if (q.width != 2048 || q.height != 2048) q].length == 0 && [
			for (q in passes)
				for (d in (q.draws : Array<Dynamic>))
					if (d.viewport != null)
						d
		].length == 0,
			"every casting light's passes the whole 2048 map, the lamp's 512 and the sun's 1024 asked for too");
		// A cube far from every map's view isn't cast.
		var before = [for (q in passes) q.draws.length];
		DrawModel(cube, new Vector3(0, 0, 200), 1, WHITE);
		check([for (q in passes) q.draws.length].join(",") == before.join(","), "a caster outside every map's view isn't drawn");
		// Shapes cast too, through the batch.
		DrawCube(Vector3Zero(), 1, 1, 1, WHITE);
		rlDrawRenderBatchActive();
		check(passes[8].draws.length == 2, "a shape cast through the batch");
		var batchDraw:Dynamic = passes[8].draws[1];
		check(graphics.pipelines.get(batchDraw.pipeline).depthOnly, "the batch cast depth-only");
		EndShadowMode();
		check(frame.eyes == null, "EndShadowMode ends the casting");

		// A lit draw after the pass: its lights' shadows, the maps' matrices, the shadow map bound.
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		var lit = lastDraw();
		check(lit != null && !graphics.pipelines.get(lit.pipeline).depthOnly, "a draw after the pass drawn on the screen, in color");
		var shadows = [
			for (i in 0...8)
				if (drawnInt(p, lit, "lights.enabled", i) == 1) drawnInt(p, lit, "lights.shadow", i)
		];
		shadows.sort((a, b) -> a - b);
		check(shadows.join(",") == "1,2,3", "the draw's three casting lights given their shadows' indices");
		check(drawnInt(p, lit, "shadowed") == 1, "shadows fall on a material until SetMaterialShadowed");
		var m = @:privateAccess helix.raylib.internal.Shadows.matrices[0].values;
		check(near(drawnFloat(p, lit, "helixShadowMatrices", 0, 0), m[0])
			&& near(drawnFloat(p, lit, "helixShadowMatrices", 8, 15), @:privateAccess helix.raylib.internal.Shadows.matrices[8].values[15]),
			"the maps' matrices written");
		check(drawnFloat(p, lit, "helixShadowStrengths", 0, 0) == 1 && drawnFloat(p, lit, "helixShadowStrengths", 0, 1) == 0.5,
			"each light's strength written, the lamp's 0.5");
		check(lit.textures[helix.raylib.internal.ShadowSlots.slotOf(p)] == map, "the shadow map bound to the lit draw");
		SetMaterialShadowed(cube.materials[0], false);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drawnInt(p, lastDraw(), "shadowed") == 0, "shadowed false written for a material shadows don't fall on");
		SetMaterialShadowed(cube.materials[0], true);

		// A frame without the pass keeps the last one's shadows.
		frame.draw(800, 450, true);
		check([for (b in graphics.shadowPasses) b[0] == map ? b[1] : -1].join(",") == "0,1,2,3,4,5,6,7,8",
			"each pass drawn into its layer of the shadow map, in order");
		check(shadowPasses().length == 0, "a frame drawn: its shadow passes gone");
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(lastDraw().textures[helix.raylib.internal.ShadowSlots.slotOf(p)] == map
			&& near(drawnFloat(p, lastDraw(), "helixShadowMatrices", 0, 0), m[0])
			&& drawnInt(p, lastDraw(), "lights.shadow", 0) > 0,
			"a frame without the pass keeps the last one's shadows");
		frame.draw(800, 450, true);

		// A cut-out material's cutoff, and a program's own vertex stage's uniforms, in the shadow draw.
		var leaf = LoadModelFromMesh(GenMeshPlane(1, 1, 1, 1));
		leaf.materials[0].shader = shader;
		SetMaterialAlphaCutoff(leaf.materials[0], 0.5);
		var sway = LoadCompiledShaderFromMemory(haxe.Resource.getBytes("sway.shader"));
		check(sway.program.casterSource != null, "a compiled shader carries its shadow variant");
		SetShaderValue(sway, GetShaderLocation(sway, "sway"), 0.25, SHADER_UNIFORM_FLOAT);
		var tree = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		tree.materials[0].shader = sway;
		BeginShadowMode(camera);
		passes = shadowPasses();
		check(passes.length == 9 && @:privateAccess helix.raylib.internal.Shadows.map == map, "the next pass draws into the same shadow map");
		DrawModel(leaf, Vector3Zero(), 1, WHITE);
		var caster = p.caster.program;
		check(caster != null
			&& drawnFloat(caster, passes[8].draws[0], "alphaCutoff") == 0.5, "the material's alpha cutoff in its shadow draw");
		DrawModel(tree, Vector3Zero(), 1, WHITE);
		var treeCaster = sway.program.caster.program;
		check(treeCaster != null
			&& treeCaster.shader.findUniform("sway") != null
			&& drawnFloat(treeCaster, passes[8].draws[1], "sway") == 0.25,
			"a program's own vertex stage's uniform in its shadow draw");
		SetShaderValue(sway, GetShaderLocation(sway, "sway"), 0.5, SHADER_UNIFORM_FLOAT);
		DrawModel(tree, Vector3Zero(), 1, WHITE);
		check(drawnFloat(treeCaster, passes[8].draws[2], "sway") == 0.5, "the uniform as it is at each draw");
		// A model posed by UpdateModelAnimation casts through its caster's skinned twin, given its first bone.
		var posed = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var bones = posed.meshes[0];
		bones.boneIds = [for (k in 0...bones.vertexCount * 4) 0];
		bones.boneWeights = [for (k in 0...bones.vertexCount * 4) k % 4 == 0 ? 1. : 0.];
		posed.boneCount = 1;
		posed.bones = [new BoneInfo("root", -1)];
		posed.bindPose = [
			new Transform(new Vector3(0, 0, 0), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1))
		];
		posed.materials[0].shader = shader;
		var raise = new ModelAnimation();
		raise.boneCount = 1;
		raise.bones = [new BoneInfo("root", -1)];
		raise.frameCount = 1;
		raise.framePoses = [
			[
				new Transform(new Vector3(0, 1, 0), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1))
			]
		];
		UpdateModelAnimation(posed, raise, 0);
		DrawModel(posed, Vector3Zero(), 1, WHITE);
		var skinnedCaster = caster.twin;
		check(skinnedCaster != null && drawnInt(skinnedCaster, passes[8].draws[3], "boneOffset") >= 1,
			"a posed model cast through its caster's skinned twin, given its first bone");
		EndShadowMode();
		frame.draw(800, 450, true);

		// A fifth light's shadows refused with a warning; one light turned off, another taking its place; an unloaded light's let go of.
		var fourth = CreateLight(LIGHT_DIRECTIONAL, new Vector3(4, 8, 0), Vector3Zero(), WHITE, shader);
		EnableLightShadows(fourth);
		var fifth = CreateLight(LIGHT_DIRECTIONAL, new Vector3(0, 8, 4), Vector3Zero(), WHITE, shader);
		warnings.resize(0);
		check(!EnableLightShadows(fifth), "EnableLightShadows returns false for a fifth light");
		check(!IsLightCastingShadows(fifth) && warnings.length == 1 && warnings[0].indexOf("4 lights cast shadows at most") >= 0,
			"a fifth light's shadows off, with a warning");
		DisableLightShadows(lamp);
		check(!IsLightCastingShadows(lamp), "DisableLightShadows turns casting off");
		check(lamp.shadows.mapSize == 512 && lamp.shadows.strength == 0.5, "a light turned off keeps its options");
		EnableLightShadows(fifth);
		check(IsLightCastingShadows(fifth), "a light turned off frees its place for another");
		UnloadLight(fourth);
		check(!IsLightCastingShadows(fourth), "an unloaded light's shadows freed");
		EnableLightShadows(lamp);
		check(IsLightCastingShadows(lamp) && lamp.shadows.mapSize == 512 && lamp.shadows.strength == 0.5,
			"a light turned on again once a fourth is unloaded, its options as they were");
		BeginShadowMode(camera);
		check(shadowPasses().length == 10, "10 shadow passes: the sun's 2 cascades, the spot's map, the fifth's map and the lamp's 6 faces");
		EndShadowMode();
		frame.draw(800, 450, true);

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
