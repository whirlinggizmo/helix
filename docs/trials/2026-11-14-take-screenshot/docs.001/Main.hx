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
		var big:Font = null;
		var small:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t);
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> big = f);
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> small = f);

		var frame = 0;
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(new Color(18, 18, 26, 255));
			if (panel != null)
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle(190, 95, 420, 260), new Vector2(0, 0), 0, WHITE);
			if (big != null) {
				var s = MeasureTextEx(big, "WARDENS", 64, 2);
				DrawTextEx(big, "WARDENS", new Vector2((800 - s.x) / 2, 120), 64, 2, RAYWHITE);
			}
			if (small != null && Std.int(GetTime()) % 2 == 0) {
				var s = MeasureTextEx(small, "PRESS ENTER", 24, 2);
				DrawTextEx(small, "PRESS ENTER", new Vector2((800 - s.x) / 2, 210), 24, 2, GOLD);
			}
			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last) TakeScreenshot("shot.png");
			EndDrawing();
			if (last || IsKeyPressed(KEY_ENTER)) break;
		}
		CloseWindow();
	}
}
