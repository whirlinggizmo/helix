import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Particles.*;

/** Draws a fountain of water drops (`helix.raylib.extras.Particles`): one 3D emitter throwing pale blue drops up in a narrow cone, falling
	back under gravity as they turn deeper blue and fade, its particles worked out on the GPU from their age in one draw. Prewarmed, so it
	is running at the first frame. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page)
	quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: particles3d");
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(0, 3, 9), new Vector3(0, 2, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var fountain = LoadEmitter3D(512);
		fountain.rate = 160;
		fountain.velocity = new Vector3(0, 6, 0);
		fountain.spread = 10;
		fountain.speedVariance = 0.1;
		fountain.gravity = new Vector3(0, -9.8, 0);
		fountain.minLife = 1.1;
		fountain.maxLife = 1.3;
		fountain.startSize = 0.22;
		fountain.endSize = 0.1;
		fountain.startColor = new Color(170, 230, 255, 255);
		fountain.colorKeys = [{at: 0.5, color: new Color(60, 140, 255, 255)}];
		fountain.endColor = new Color(30, 70, 200, 0);
		PrewarmEmitter3D(fountain, 2);
		while (!WindowShouldClose()) {
			UpdateEmitter3D(fountain, GetFrameTime());
			BeginDrawing();
			ClearBackground(new Color(24, 26, 34, 255));
			BeginMode3D(camera);
			DrawPlane(new Vector3(0, 0, 0), new Vector2(8, 8), new Color(50, 54, 66, 255));
			DrawEmitter3D(fountain);
			EndMode3D();
			DrawText('${fountain.particleCount} drops, one draw', 10, 10, 20, LIGHTGRAY);
			EndDrawing();
		}
		UnloadEmitter3D(fountain);
		CloseWindow();
	}
}
