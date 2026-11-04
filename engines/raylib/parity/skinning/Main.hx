import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Window.*;
import helix.raylib.extras.Models.*;

// scene.c's greenman, drawn by helix-raylib: the third frame after its loads saved as helix.png. Its files (web/) are the model and raylib
// 6.2's example skinning shaders.
class Main {
	static function main():Void {
		InitWindow(640, 360, "anim");
		var camera = new Camera(new Vector3(4, 3.5, 5), new Vector3(0, 1, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (_ in 0...4)
			LoadModelAsync("greenman.glb", m -> models.push(m));
		LoadModelAnimationsAsync("greenman.glb", a -> anims = a);
		var skinning = LoadShader("skinning.vs", "skinning.fs");
		var frame = -1;
		while (!WindowShouldClose()) {
			var ready = models.length == 4 && anims != null;
			if (ready) {
				if (frame < 0) {
					frame = 0;
					models[1].materials[1].shader = skinning;
					models[3].materials[1].shader = skinning;
				}
				UpdateModelAnimation(models[0], anims[1], 30.5 + frame);
				UpdateModelAnimation(models[1], anims[2], 20.25 + frame);
				UpdateModelAnimationEx(models[2], anims[1], 12 + frame, anims[3], 25, 0.4);
				UpdateModelAnimationEx(models[3], anims[2], 8.5 + frame, anims[1], 30, 0.7);
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawGrid(10, 1);
			if (ready) {
				DrawModel(models[0], new Vector3(-1.3, 0, 0), 1, WHITE);
				DrawModel(models[1], new Vector3(1.3, 0, 0), 1, WHITE);
				DrawModel(models[2], new Vector3(0, 0, -2), 1, WHITE);
				DrawModel(models[3], new Vector3(2.6, 0, -2.2), 1, WHITE);
			}
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
