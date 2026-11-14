import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlights.*;
import helix.raylib.extras.Lighting.*;

/** Lights spheres with the PBR shader (`helix.raylib.extras.Lighting`): a row from rough to smooth, a row from non-metal to metal,
	under one light. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after
	that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: lighting");
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(0, 3, 9), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shader = LoadPbrShader();
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.15, 0.15, 0.18, 1.0], SHADER_UNIFORM_VEC4);
		var light = CreateLight(LIGHT_DIRECTIONAL, new Vector3(4, 6, 6), Vector3Zero(), WHITE, shader);
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
			SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			UpdateLightValues(shader, light);
			BeginDrawing();
			ClearBackground(new Color(30, 32, 40, 255));
			BeginMode3D(camera);
			for (s in spheres)
				DrawModel(s.model, s.at, 1, WHITE);
			EndMode3D();
			DrawText("roughness, left to right", 10, 10, 20, LIGHTGRAY);
			DrawText("metalness, left to right", 10, 420, 20, LIGHTGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
