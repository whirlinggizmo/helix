import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);
		SetExitKey(0);

		var panel:Texture2D = null;
		var font:Font = null;
		var font24:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> font24 = f, e -> trace(e));
		var bg = new Color(18, 20, 28, 255);

		var frame = 0;
		var quit = false;
		while (!quit && !WindowShouldClose()) {
			if (panel == null || font == null || font24 == null) {
				BeginDrawing();
				ClearBackground(bg);
				EndDrawing();
				continue;
			}
			frame++;
			if (IsKeyPressed(KEY_ENTER)) quit = true;

			BeginDrawing();
			ClearBackground(bg);

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			var title = "WARDENS";
			var ts = MeasureTextEx(font, title, 64, 2);
			DrawTextEx(font, title, new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 2, RAYWHITE);

			// blink once a second: visible for the second half of each 60 frames
			if ((frame - 1) % 60 >= 30) {
				var prompt = "PRESS ENTER";
				var ps = MeasureTextEx(font24, prompt, 24, 1);
				DrawTextEx(font24, prompt, new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 30), 24, 1, LIGHTGRAY);
			}
			if (maxFrames > 0 && frame >= maxFrames) {
				TakeScreenshot("shot.png");
				quit = true;
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
