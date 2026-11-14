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
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t);
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f);

		var bg = new Color(18, 18, 26, 255);
		var frame = 0;
		while (!WindowShouldClose()) {
			frame++;
			if (IsKeyPressed(KEY_ENTER))
				break;

			BeginDrawing();
			ClearBackground(bg);
			if (panel != null)
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle(190, 95, 420, 260), new Vector2(0, 0), 0, WHITE);
			if (font != null) {
				var ts = MeasureTextEx(font, "WARDENS", 64, 2);
				DrawTextEx(font, "WARDENS", new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 2, WHITE);
				// blink once a second: on for half of each 60 frames
				if (frame % 60 < 30) {
					var ps = MeasureTextEx(font, "PRESS ENTER", 24, 2);
					DrawTextEx(font, "PRESS ENTER", new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 30), 24, 2, WHITE);
				}
			}
			if (maxFrames >= 0 && frame >= maxFrames)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (maxFrames >= 0 && frame >= maxFrames)
				break;
		}
		CloseWindow();
	}
}
