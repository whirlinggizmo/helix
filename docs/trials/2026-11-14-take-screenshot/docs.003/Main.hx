import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static var font:Font;
	static var fontReady = false;
	static var small:Font;
	static var smallReady = false;
	static var panel:Texture2D;
	static var panelReady = false;

	static function centeredX(font:Font, text:String, size:Float):Float {
		return (800 - MeasureTextEx(font, text, size, 0).x) / 2;
	}

	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);

		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> {
			font = f;
			fontReady = true;
		});
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> {
			small = f;
			smallReady = true;
		});
		LoadTextureAsync("assets/ui/panel.png", t -> {
			panel = t;
			panelReady = true;
		});

		var frame = 0;
		var quit = false;
		while (!quit && !WindowShouldClose()) {
			frame++;
			if (IsKeyPressed(KEY_ENTER))
				quit = true;
			var last = maxFrames > 0 && frame >= maxFrames;

			BeginDrawing();
			ClearBackground(new Color(18, 18, 26, 255));
			if (panelReady)
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(190, 95, 420, 260), new Vector2(0, 0), 0,
					WHITE);
			if (fontReady && smallReady) {
				DrawTextEx(font, "WARDENS", new Vector2(centeredX(font, "WARDENS", 64), 120), 64, 0, WHITE);
				if (Std.int(GetTime()) % 2 == 0)
					DrawTextEx(small, "PRESS ENTER", new Vector2(centeredX(small, "PRESS ENTER", 24), 120 + 64 + 30), 24, 0, LIGHTGRAY);
			}
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();

			if (last)
				break;
		}
		CloseWindow();
	}
}
