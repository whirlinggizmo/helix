import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.Particles.*;

/** Draws a sparkler (`helix.raylib.extras.Particles`): one 2D emitter throwing sparks every way, each a streak along its motion that falls
	under gravity and cools from white through yellow to red as it fades, drawn added over what's behind in the same batch as the text.
	The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: particles2d");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var sparks = LoadEmitter2D(1024);
		sparks.position = new Vector2(400, 200);
		sparks.rate = 500;
		sparks.speed = 260;
		sparks.spread = 180;
		sparks.speedVariance = 0.6;
		sparks.gravity = new Vector2(0, 420);
		sparks.drag = 0.8;
		sparks.minLife = 0.4;
		sparks.maxLife = 0.9;
		sparks.sizeKeys = [{at: 0, size: 5}, {at: 1, size: 2}];
		sparks.stretch = 0.03;
		sparks.colorKeys = [
			{at: 0, color: new Color(255, 255, 230, 255)},
			{at: 0.3, color: new Color(255, 200, 60, 255)},
			{at: 1, color: new Color(220, 40, 10, 0)}
		];
		sparks.blendMode = BLEND_ADDITIVE;
		PrewarmEmitter2D(sparks, 1);
		while (!WindowShouldClose()) {
			UpdateEmitter2D(sparks, GetFrameTime());
			BeginDrawing();
			ClearBackground(new Color(16, 14, 22, 255));
			DrawRectangle(396, 200, 8, 160, new Color(90, 80, 70, 255));
			DrawEmitter2D(sparks);
			DrawText('${sparks.particleCount} sparks', 10, 10, 20, LIGHTGRAY);
			EndDrawing();
		}
		UnloadEmitter2D(sparks);
		CloseWindow();
	}
}
