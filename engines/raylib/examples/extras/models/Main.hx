import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.Models.*;

/** Blends two animations bone by bone (`helix.raylib.extras.Models`): raylib's robot runs, and every 2 seconds punches from the waist
	up, its legs running on, the punch eased in and out. Its bounds as posed are drawn around it (`GetModelBoundingBoxPosed`). The
	model is `web/assets/robot.glb`, raylib's. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60`
	in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: models");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(9, 7, 11), new Vector3(0, 2.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var model:Null<Model> = null;
		var anims:Null<Array<ModelAnimation>> = null;
		LoadModelAsync("assets/robot.glb", loaded -> model = loaded);
		LoadModelAnimationsAsync("assets/robot.glb", loaded -> anims = loaded);
		var mask:Array<Float> = [];
		var time = 0.0;
		while (!WindowShouldClose()) {
			time += GetFrameTime();
			BeginDrawing();
			ClearBackground(RAYWHITE);
			camera.fovy = GetScreenFitFovy(45);
			BeginMode3D(camera);
			if (model != null && anims != null) {
				var run = anims.filter(a -> a.name == "Robot_Running")[0];
				var punch = anims.filter(a -> a.name == "Robot_Punch")[0];
				GetModelBoneMask(model, "Abdomen", mask);
				// A punch every 2 seconds, eased in and out over 0.15 seconds each.
				var t = time % 2, length = (punch.frameCount - 1) / 60;
				var blend = t < length ? Math.min(1, Math.min(t, length - t) / 0.15) : 0.0;
				UpdateModelAnimationMasked(model, run, time * 60, punch, t * 60, mask, blend);
				DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
				DrawBoundingBox(GetModelBoundingBoxPosed(model), LIME);
			}
			DrawGrid(10, 1);
			EndMode3D();
			DrawText("running, punching from the waist up", 10, 10, 20, DARKGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
