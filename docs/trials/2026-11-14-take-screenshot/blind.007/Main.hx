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
		var font64:Font = null;
		var font24:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace("panel: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font64 = f, e -> trace("font64: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> font24 = f, e -> trace("font24: " + e));

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER)) break;

			BeginDrawing();
			ClearBackground(new Color(20, 20, 28, 255));

			if (panel == null || font64 == null || font24 == null) {
				EndDrawing();
				continue;
			}

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(font64, "WARDENS", 64, 2);
			DrawTextEx(font64, "WARDENS", new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 2, RAYWHITE);

			// blink once a second: on for half, off for half
			if ((frame % 60) >= 30) {
				var ps = MeasureTextEx(font24, "PRESS ENTER", 24, 1);
				DrawTextEx(font24, "PRESS ENTER", new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 30), 24, 1, GOLD);
			}
			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last) TakeScreenshot("shot.png");
			EndDrawing();
			if (last) break;
		}

		if (font64 != null) UnloadFont(font64);
		if (font24 != null) UnloadFont(font24);
		if (panel != null) UnloadTexture(panel);
		CloseWindow();
	}
}
