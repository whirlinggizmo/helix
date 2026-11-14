import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args()) {
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);

		var panel:Texture2D = null;
		var font:Font = null;
		LoadTextureAsync("assets/ui/panel.png", function(t) panel = t, function(e) trace("panel failed: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, function(f) font = f, function(e) trace("font failed: " + e));

		var frame = 0;
		var bg = new Color(20, 20, 28, 255);
		while (!WindowShouldClose()) {
			var t = GetTime();
			BeginDrawing();
			ClearBackground(bg);

			if (panel == null || font == null) {
				EndDrawing();
				continue;
			}
			DrawTexturePro(panel,
				new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle(190, 95, 420, 260),
				new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(font, "WARDENS", 64, 0);
			DrawTextEx(font, "WARDENS", new Vector2((800 - ts.x) / 2, 120), 64, 0, WHITE);

			if (Std.int(t * 2) % 2 == 0) {
				var ps = MeasureTextEx(font, "PRESS ENTER", 24, 0);
				DrawTextEx(font, "PRESS ENTER", new Vector2((800 - ps.x) / 2, 120 + ts.y + 20), 24, 0, WHITE);
			}
			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();

			if (last || IsKeyPressed(KEY_ENTER))
				break;
		}

		UnloadFont(font);
		UnloadTexture(panel);
		CloseWindow();
	}
}
