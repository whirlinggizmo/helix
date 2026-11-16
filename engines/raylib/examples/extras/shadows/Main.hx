import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlights.*;
import helix.raylib.extras.Lighting.*;

/** Casts shadows with the Lighting extra (`helix.raylib.extras.Lighting`): a pillar, a cube and a sphere on a floor drawn with the PBR
	shader, under a sun from the west whose shadows have two cascades and a warm lamp whose shadows fall every way from it. Each frame's
	shadow pass draws the scene once, between `BeginShadowMode` and `EndShadowMode`, and the frame draws it again, receiving them. The
	pillar's shadow from the sun falls east along the floor. The `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static var floor:Model;
	static var pillar:Model;
	static var cube:Model;
	static var ball:Model;

	static function main():Void {
		InitWindow(800, 450, "helix-raylib: shadows");
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(0, 6, 9), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shader = LoadPbrShader();
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.25, 0.25, 0.28, 1.0], SHADER_UNIFORM_VEC4);
		var sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(-6, 8, 0), Vector3Zero(), WHITE, shader);
		SetLightShadows(sun, {mapSize: 2048, distance: 30, cascades: 2});
		SetLightShadowCasting(sun, true);
		var lamp = CreateLight(LIGHT_POINT, new Vector3(3, 2.5, 3), Vector3Zero(), new Color(255, 190, 120, 255), shader);
		SetLightRange(lamp, 6);
		SetLightIntensity(lamp, 4);
		SetLightShadowCasting(lamp, true);
		floor = shaded(GenMeshPlane(14, 14, 1, 1), new Color(200, 200, 200, 255), shader);
		pillar = shaded(GenMeshCube(1, 4, 1), new Color(180, 70, 60, 255), shader);
		cube = shaded(GenMeshCube(1.2, 1.2, 1.2), new Color(70, 110, 190, 255), shader);
		ball = shaded(GenMeshSphere(0.7, 32, 32), new Color(220, 190, 90, 255), shader);
		while (!WindowShouldClose()) {
			SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			BeginShadowMode(camera);
			drawScene();
			EndShadowMode();
			BeginDrawing();
			ClearBackground(new Color(30, 32, 40, 255));
			BeginMode3D(camera);
			drawScene();
			DrawSphere(lamp.position, 0.1, lamp.color);
			EndMode3D();
			DrawText("a sun's and a lamp's shadows", 10, 10, 20, LIGHTGRAY);
			EndDrawing();
		}
		CloseWindow();
	}

	// A model of a mesh, its material drawn by the PBR shader in a color, rough.
	static function shaded(mesh:Mesh, color:Color, shader:Shader):Model {
		var model = LoadModelFromMesh(mesh);
		model.materials[0].shader = shader;
		model.materials[0].maps[MATERIAL_MAP_ALBEDO].color = color;
		model.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 0.8;
		return model;
	}

	// The scene, drawn alike in the shadow pass and the frame.
	static function drawScene():Void {
		DrawModel(floor, Vector3Zero(), 1, WHITE);
		DrawModel(pillar, new Vector3(0, 2, 0), 1, WHITE);
		DrawModel(cube, new Vector3(-2.5, 0.6, -2), 1, WHITE);
		DrawModel(ball, new Vector3(-3, 0.7, 2), 1, WHITE);
	}
}
