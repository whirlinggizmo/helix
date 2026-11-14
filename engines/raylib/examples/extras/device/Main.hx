import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Device.*;

/** Reads the device (`helix.raylib.extras.Device`): the window's safe area, outlined, and what the device has, listed. The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: the device");
		SetTargetFPS(60);
		Sys.println('platform ${GetPlatformOS()}');
		while (!WindowShouldClose()) {
			var safe = GetWindowSafeArea();
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawRectangleLinesEx(safe, 4, SKYBLUE);
			var lines = [
				'platform: ${GetPlatformOS()}${IsPlatformWeb() ? " (browser)" : ""}',
				'has touch: ${IsTouchAvailable()}, has fine pointer: ${IsFinePointerAvailable()}',
				'window closeable: ${IsWindowCloseable()}, fullscreen: ${IsFullscreenAvailable()}',
				'orientation: ${["any", "landscape", "portrait"][GetScreenOrientation()]}',
				'safe area: ${Std.int(safe.x)}, ${Std.int(safe.y)}, ${Std.int(safe.width)} x ${Std.int(safe.height)}'
			];
			for (i => line in lines)
				DrawText(line, Std.int(safe.x) + 20, Std.int(safe.y) + 20 + i * 30, 20, DARKGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
