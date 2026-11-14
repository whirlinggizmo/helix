import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static function main() {
		var maxFrames = 0;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);
		SetExitKey(0);

		var panel:Texture2D = null;
		var title:Font = null;
		var prompt:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace("panel: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> title = f, e -> trace("title font: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> prompt = f, e -> trace("prompt font: " + e));

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER))
				break;

			if (panel == null || title == null || prompt == null) {
				BeginDrawing();
				ClearBackground(new Color(18, 18, 26, 255));
				EndDrawing();
				continue;
			}

			BeginDrawing();
			ClearBackground(new Color(18, 18, 26, 255));

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(title, "WARDENS", 64, 0);
			DrawTextEx(title, "WARDENS", new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 0, RAYWHITE);

			// blink once a second: visible for half of each second
			if (Std.int(GetTime() * 2) % 2 == 0) {
				var ps = MeasureTextEx(prompt, "PRESS ENTER", 24, 0);
				DrawTextEx(prompt, "PRESS ENTER", new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 20), 24, 0, LIGHTGRAY);
			}
			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (last)
				break;
		}

		CloseWindow();
	}
}
