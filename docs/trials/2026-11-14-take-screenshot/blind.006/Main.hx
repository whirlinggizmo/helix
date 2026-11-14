import helix.raylib.*;
import helix.raylib.Raylib.*;

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
		LoadTextureAsync("assets/ui/panel.png", function(t) panel = t);
		var font:Font = null;
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, function(f) font = f);
		var font24:Font = null;
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, function(f) font24 = f);

		var title = "WARDENS";
		var prompt = "PRESS ENTER";
		var frame = 0;
		var quit = false;

		while (!quit && !WindowShouldClose()) {
			frame++;

			var ready = panel != null && font != null && font24 != null;
			BeginDrawing();
			ClearBackground(new Color(18, 18, 24, 255));

			if (ready) {
			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(190, 95, 420, 260), new Vector2(0, 0), 0, WHITE);

			var ts = MeasureTextEx(font, title, 64, 0);
			DrawTextEx(font, title, new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 0, RAYWHITE);

			// blink once a second: on for half a second, off for half
			if (Std.int(GetTime() * 2) % 2 == 0) {
				var ps = MeasureTextEx(font24, prompt, 24, 0);
				DrawTextEx(font24, prompt, new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 30), 24, 0, LIGHTGRAY);
			}

			}
			var last = maxFrames > 0 && ready && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();

			if (IsKeyPressed(KEY_ENTER))
				quit = true;
			if (maxFrames > 0 && ready && frame >= maxFrames) {
				quit = true;
			}
		}

		UnloadFont(font);
		UnloadFont(font24);
		UnloadTexture(panel);
		CloseWindow();
	}
}
