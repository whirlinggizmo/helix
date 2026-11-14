import helix.raylib.*;
import helix.raylib.Raylib.*;

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
		var small:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> small = f, e -> trace(e));

		var frame = 0;
		while (!WindowShouldClose()) {
			if (panel == null || font == null || small == null) {
				BeginDrawing();
				ClearBackground(new Color(18, 18, 26, 255));
				EndDrawing();
				continue;
			}
			frame++;
			var done = IsKeyPressed(KEY_ENTER) || (maxFrames >= 0 && frame >= maxFrames);

			BeginDrawing();
			ClearBackground(new Color(18, 18, 26, 255));

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(font, "WARDENS", 64, 2);
			DrawTextEx(font, "WARDENS", new Vector2((800 - ts.x) / 2, 120), 64, 2, RAYWHITE);

			// blinks once a second: visible for half of each 60 frames
			if ((frame % 60) < 30) {
				var ps = MeasureTextEx(small, "PRESS ENTER", 24, 1);
				DrawTextEx(small, "PRESS ENTER", new Vector2((800 - ps.x) / 2, 120 + 64 + 20), 24, 1, LIGHTGRAY);
			}

			if (maxFrames >= 0 && frame >= maxFrames)
				TakeScreenshot("shot.png");
			EndDrawing();

			if (done) break;
		}

		if (font != null) UnloadFont(font);
		if (small != null) UnloadFont(small);
		if (panel != null) UnloadTexture(panel);
		CloseWindow();
	}
}
