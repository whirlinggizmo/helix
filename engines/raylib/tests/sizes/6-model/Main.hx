// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a glTF model loaded with LoadModelAsync and drawn beside the cube.
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Models.*;
import helix.raylib.Camera3D;
import helix.raylib.Model;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;
import helix.raylib.Vector3;

/** A program written in raylib on helix-raylib, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png,
	its model engines/raylib/parity/assets/robot.glb. */
@:adds("helix.formats.gltf", "helix.formats.text", "helix.geometry.Animation3D", "helix.geometry.AnimationProperty3D", "helix.geometry.AnimationTrack3D",
	"helix.geometry.Bone3D", "helix.geometry.KeyInterpolation", "helix.geometry.Mesh3D", "helix.geometry.Skeleton3D", "helix.geometry.Skin3D",
	"helix.raylib.internal.Animations", "helix.raylib.modules.RMath", "helix.raylib.modules.RModelsAsync", "helix.services.models")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var texture:Null<Texture2D> = null;
		var model:Null<Model> = null;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		LoadModelAsync("robot.glb", loaded -> model = loaded);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(cube, new Vector3(-3, 0.5, 0), 1, WHITE);
			if (model != null)
				DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
			EndMode3D();
			DrawRectangle(20, 20, 120, 60, MAROON);
			DrawCircle(220, 50, 30, DARKBLUE);
			DrawLine(20, 100, 260, 100, BLACK);
			DrawTriangle(new Vector2(300, 20), new Vector2(280, 80), new Vector2(340, 80), GOLD);
			DrawText("Hello, raylib", 20, 120, 20, DARKGRAY);
			if (texture != null)
				DrawTexture(texture, 20, 160, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
