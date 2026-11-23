import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Lighting.*;

/** Lights a floor and spheres with the PBR shader and the scene's lights (`helix.raylib.extras.Lighting`): a row of spheres from
	rough to smooth and a row from non-metal to metal, under a dim sun, six colored lamps circling them, each reaching 3 units, and a
	spot light on the floor in front. The lamps move by their positions alone. The `quit_after_frame` option (`--quit_after_frame=60`
	natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: lighting");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(0, 3, 9), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shader = LoadPbrShader();
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.15, 0.15, 0.18, 1.0], SHADER_UNIFORM_VEC4);
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(4, 6, 6), Vector3Zero(), new Color(110, 110, 130, 255), shader);
		var colors = [RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE];
		var lamps = [
			for (color in colors) {
				var lamp = CreateLight(LIGHT_POINT, Vector3Zero(), Vector3Zero(), color, shader);
				lamp.range = 3;
				lamp.intensity = 2;
				lamp;
			}
		];
		var spot = CreateLight(LIGHT_SPOT, new Vector3(0, 1.5, 3), new Vector3(0, -1.5, 3), WHITE, shader);
		spot.innerAngle = 15;
		spot.outerAngle = 25;
		spot.range = 6;
		spot.intensity = 10;
		var floor = LoadModelFromMesh(GenMeshPlane(14, 10, 1, 1));
		floor.materials[0].shader = shader;
		floor.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(90, 90, 90, 255);
		floor.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 0.8;
		var spheres = [];
		for (row in 0...2)
			for (i in 0...5) {
				var model = LoadModelFromMesh(GenMeshSphere(0.6, 32, 32));
				var material = model.materials[0];
				material.shader = shader;
				material.maps[MATERIAL_MAP_ALBEDO].color = row == 0 ? new Color(200, 60, 50, 255) : new Color(230, 190, 120, 255);
				material.maps[MATERIAL_MAP_ROUGHNESS].value = row == 0 ? 0.1 + i * 0.2 : 0.3;
				material.maps[MATERIAL_MAP_METALNESS].value = row == 0 ? 0 : i / 4;
				spheres.push({model: model, at: new Vector3(-3 + i * 1.5, row == 0 ? 0.8 : -0.8, 0)});
			}
		while (!WindowShouldClose()) {
			var time = GetTime();
			for (i => lamp in lamps) {
				var angle = time * 0.5 + i * PI / 3;
				lamp.position = new Vector3(Math.cos(angle) * 4.5, 0, Math.sin(angle) * 2);
			}
			SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			BeginDrawing();
			ClearBackground(new Color(30, 32, 40, 255));
			camera.fovy = GetScreenFitFovy(45);
			BeginMode3D(camera);
			DrawModel(floor, new Vector3(0, -1.5, 0), 1, WHITE);
			for (s in spheres)
				DrawModel(s.model, s.at, 1, WHITE);
			for (lamp in lamps)
				DrawSphere(lamp.position, 0.1, lamp.color);
			EndMode3D();
			DrawText("roughness, left to right", 10, 10, 20, LIGHTGRAY);
			DrawText("metalness, left to right", 10, 420, 20, LIGHTGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
