import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.extras.Materials.*;

/** Shows the Materials extra (`helix.raylib.extras.Materials`): on the left, through raylib's default shader, a leaf cut from a square
	by its alpha cutoff and a dark cube glowing orange; on the right, under the PBR shader and one light, a sphere glowing, a sphere
	drawn unlit and a sphere flashing white for 0.15 seconds each second, as a hit in a game does. The `quit_after_frame` option
	(`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: materials");
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(0, 2, 8), new Vector3(0, 0.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		// A green leaf on a clear square: the square's clear corners cut out.
		var image = GenImageColor(64, 64, BLANK);
		ImageDrawCircle(image, 32, 32, 28, DARKGREEN);
		var leaf = LoadModelFromMesh(GenMeshPlane(1.6, 1.6, 1, 1));
		leaf.materials[0].maps[MATERIAL_MAP_ALBEDO].texture = LoadTextureFromImage(image);
		SetMaterialAlphaCutoff(leaf.materials[0], 0.5);
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(40, 40, 40, 255);
		SetMaterialEmissive(cube.materials[0], ORANGE, 0.6);

		var pbr = LoadPbrShader();
		SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.2, 0.2, 0.2, 1.0], SHADER_UNIFORM_VEC4);
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 4), Vector3Zero(), WHITE, pbr);
		var spheres = [for (_ in 0...3) LoadModelFromMesh(GenMeshSphere(0.5, 32, 32))];
		for (s in spheres) {
			s.materials[0].shader = pbr;
			s.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(60, 90, 160, 255);
			s.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 0.5;
		}
		SetMaterialEmissive(spheres[0].materials[0], new Color(255, 200, 80, 255), 1.5);
		SetMaterialUnlit(spheres[1].materials[0], true);

		while (!WindowShouldClose()) {
			SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			// The hit flash: white for 0.15 seconds each second.
			SetModelEmissive(spheres[2], WHITE, GetTime() % 1 < 0.15 ? 1 : 0);
			BeginDrawing();
			ClearBackground(new Color(30, 32, 40, 255));
			BeginMode3D(camera);
			DrawModelEx(leaf, new Vector3(-2.6, 0.8, 0), new Vector3(1, 0, 0), 90, new Vector3(1, 1, 1), WHITE);
			DrawModel(cube, new Vector3(-1, 0.5, 0), 1, WHITE);
			for (i => s in spheres)
				DrawModel(s, new Vector3(0.6 + i * 1.2, 0.5, 0), 1, WHITE);
			EndMode3D();
			DrawText("cut out, glowing", 10, 10, 20, LIGHTGRAY);
			DrawText("glowing, unlit, flashing", 480, 10, 20, LIGHTGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
