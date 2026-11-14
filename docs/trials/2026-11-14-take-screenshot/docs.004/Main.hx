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

		var panel:Texture2D = null;
		var font:Font = null;
		LoadTextureAsync("assets/ui/panel.png", function(t) panel = t);
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, function(f) font = f);
		// the prompt is drawn from a second font size
		var small:Font = null;
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, function(f) small = f);

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER))
				break;

			BeginDrawing();
			ClearBackground(new Color(20, 20, 28, 255));

			if (panel != null && IsTextureValid(panel))
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			if (font != null && IsFontValid(font)) {
				var size = MeasureTextEx(font, "WARDENS", 64, 2);
				DrawTextEx(font, "WARDENS", new Vector2((800 - size.x) / 2, 120), 64, 2, WHITE);
			}

			// on for the first quarter second, off for half, on again: once a second
			var phase = frame % 60;
			if (small != null && IsFontValid(small) && (phase < 15 || phase >= 45)) {
				var size = MeasureTextEx(small, "PRESS ENTER", 24, 2);
				DrawTextEx(small, "PRESS ENTER", new Vector2((800 - size.x) / 2, 120 + 64 + 30), 24, 2, LIGHTGRAY);
			}

			EndDrawing();
			frame++;

			if (maxFrames > 0 && frame == maxFrames - 1)
				TakeScreenshot("shot.png");
			if (maxFrames > 0 && frame >= maxFrames)
				break;
		}
		CloseWindow();
	}
}
