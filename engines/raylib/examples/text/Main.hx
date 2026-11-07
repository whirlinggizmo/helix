import helix.raylib.Raylib.*;
import helix.raylib.extras.Text.*;
import helix.raylib.Font;
import helix.raylib.Vector2;

/** raylib's text in a font of its own: a TrueType font loaded with `LoadFontAsync` and
	drawn with `DrawTextEx` beside raylib's default font. The font is `web/assets/JetBrainsMono-Regular.ttf` (SIL Open Font License,
	`web/assets/OFL.txt`). The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after
	that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: text");
		var font:Null<Font> = null;
		LoadFontAsync("assets/JetBrainsMono-Regular.ttf", loaded -> font = loaded);
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("raylib's default font", 10, 10, 20, DARKGRAY);
			if (font != null) {
				DrawTextEx(font, "JetBrains Mono, loaded", new Vector2(10, 50), 32, 0, MAROON);
				DrawTextEx(font, "I", new Vector2(360, 120), 256, 0, DARKBLUE);
			}
			EndDrawing();
		}
		if (font != null)
			UnloadFont(font);
		CloseWindow();
	}
}
