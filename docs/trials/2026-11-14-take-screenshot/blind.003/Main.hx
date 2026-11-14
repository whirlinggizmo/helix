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

		var panel:Texture2D = null;
		var font:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace("panel: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace("font: " + e));
		var bg = new Color(20, 20, 28, 255);

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER)) break;
			frame++;

			BeginDrawing();
			ClearBackground(bg);
			if (panel == null || font == null) {
				EndDrawing();
				continue;
			}

			var src = new Rectangle(0, 0, panel.width, panel.height);
			var dst = new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260);
			DrawTexturePro(panel, src, dst, new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(font, "WARDENS", 64, 2);
			DrawTextEx(font, "WARDENS", new Vector2((800 - ts.x) / 2, 120), 64, 2, WHITE);

			{
				// blink once a second: visible half of each second
				if (GetTime() - Math.floor(GetTime()) < 0.5) {
					var ps = MeasureTextEx(font, "PRESS ENTER", 24, 2);
					DrawTextEx(font, "PRESS ENTER", new Vector2((800 - ps.x) / 2, 120 + ts.y + 20), 24, 2, WHITE);
				}
			}
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last) TakeScreenshot("shot.png");
			EndDrawing();
			if (last) break;
		}
		UnloadFont(font);
		UnloadTexture(panel);
		CloseWindow();
	}
}
