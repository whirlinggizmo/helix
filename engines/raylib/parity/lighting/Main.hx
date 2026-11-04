import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.extras.Window.*;
import helix.raylib.extras.Models.*;

// scene.c drawn by helix-raylib: its lighting shader is LoadLightingShader, built in, and its second a program's own (own.vs and own.fs,
// over <helix/raylib/shaders/skinning.glsl> and <helix/raylib/shaders/lights.glsl>); greenman is skinned on the GPU under both. The
// third frame after its loads saved as helix.png.
class Main {
	static function main():Void {
		InitWindow(640, 360, "lighting");
		var camera = new Camera(new Vector3(2, 4, 6), new Vector3(0, 0.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shader = LoadLightingShader();
		var ambientLoc = GetShaderLocation(shader, "ambient");
		SetShaderValue(shader, ambientLoc, [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
		var own = LoadShader("own.vs", "own.fs");
		own.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(own, "viewPos");
		SetShaderValue(own, GetShaderLocation(own, "ambient"), [0.2, 0.2, 0.3, 1.0], SHADER_UNIFORM_VEC4);
		var lights = [
			CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader),
			CreateLight(LIGHT_POINT, new Vector3(2, 1, 2), Vector3Zero(), RED, shader),
			CreateLight(LIGHT_POINT, new Vector3(-2, 1, 2), Vector3Zero(), GREEN, shader),
			CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 3, -2), Vector3Zero(), BLUE, shader)
		];
		CreateLight(LIGHT_POINT, new Vector3(0, 3, 0), Vector3Zero(), WHITE, own);
		SetShaderValue(own, GetShaderLocation(own, "lights[0].enabled"), 1, SHADER_UNIFORM_INT);
		SetShaderValue(own, GetShaderLocation(own, "lights[0].type"), LIGHT_POINT, SHADER_UNIFORM_INT);
		SetShaderValue(own, GetShaderLocation(own, "lights[0].position"), [1, 2, 2], SHADER_UNIFORM_VEC3);
		SetShaderValue(own, GetShaderLocation(own, "lights[0].color"), [1, 0.8, 0.6, 1], SHADER_UNIFORM_VEC4);
		var plane = LoadModelFromMesh(GenMeshPlane(10, 10, 1, 1)),
			cube = LoadModelFromMesh(GenMeshCube(2, 4, 2));
		plane.materials[0].shader = shader;
		cube.materials[0].shader = shader;
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (_ in 0...2)
			LoadModelAsync("greenman.glb", m -> models.push(m));
		LoadModelAnimationsAsync("greenman.glb", a -> anims = a);
		var frame = -1;
		while (!WindowShouldClose()) {
			var ready = models.length == 2 && anims != null;
			if (ready && frame < 0) {
				frame = 0;
				for (m in models[0].materials)
					m.shader = shader;
				for (m in models[1].materials)
					m.shader = own;
			}
			var f = frame < 0 ? 0 : frame;
			SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			SetShaderValue(own, own.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			lights[2].enabled = f != 1;
			for (light in lights)
				UpdateLightValues(shader, light);
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(plane, new Vector3(0, -0.02, 0), 1, WHITE);
			DrawModel(cube, new Vector3(-2.5, 0, -1), 0.5, WHITE);
			if (ready) {
				UpdateModelAnimation(models[0], anims[1], 10.5 + f);
				DrawModel(models[0], new Vector3(0.6, 0, 0.8), 0.8, WHITE);
				UpdateModelAnimation(models[0], anims[2], 20.25 + f);
				DrawModel(models[0], new Vector3(2.2, 0, -0.6), 0.8, WHITE);
				UpdateModelAnimation(models[1], anims[3], 5 + f);
				DrawModel(models[1], new Vector3(-0.8, 0, 1.8), 0.8, WHITE);
			}
			for (light in lights)
				if (light.enabled)
					DrawSphereEx(light.position, 0.2, 8, 8, light.color);
				else
					DrawSphereWires(light.position, 0.2, 8, 8, ColorAlpha(light.color, 0.3));
			DrawGrid(10, 1.0);
			EndMode3D();
			if (frame == 2)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			if (frame >= 0)
				frame++;
		}
		CloseWindow();
	}
}
