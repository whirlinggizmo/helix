import helix.raylib.Raylib.*;

/** Screenshots saved to files in the directory the program's files are read from, so `LoadImage` reads them back: the first frame,
	taken before it is drawn; a frame part way through, its clear but not the gold drawn after; and the frame last shown, taken between
	frames. Natively each file is read back and its colors at the window's left and right quarters printed. In a page each screenshot is
	downloaded, which the page can't read back, so it prints nothing. The `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: screenshots");
		SetTargetFPS(60);
		// Nothing is drawn yet, so this saves the first frame as it ends.
		TakeScreenshot(GetApplicationDirectory() + "first.png");
		var frame = 0;
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(frame == 0 ? DARKBLUE : MAROON);
			// The frame drawn so far: the clear, without the gold drawn after it.
			if (frame == 1)
				TakeScreenshot(GetApplicationDirectory() + "during.png");
			if (frame > 0)
				DrawRectangle(0, 0, Std.int(GetScreenWidth() / 2), GetScreenHeight(), GOLD);
			EndDrawing();
			if (frame == 1) {
				// Between frames: the frame last shown, gold over maroon.
				TakeScreenshot(GetApplicationDirectory() + "between.png");
				#if !js
				for (name in ["first.png", "during.png", "between.png"])
					report(name);
				#end
			}
			frame++;
		}
		CloseWindow();
	}

	#if !js
	// Prints a screenshot's colors at its left and right quarters, halfway down.
	static function report(fileName:String):Void {
		var image = LoadImage(GetApplicationDirectory() + fileName);
		var left = GetImageColor(image, Std.int(image.width / 4), Std.int(image.height / 2)),
			right = GetImageColor(image, Std.int(image.width * 3 / 4), Std.int(image.height / 2));
		Sys.println('$fileName ${image.width} x ${image.height}: ${left.r} ${left.g} ${left.b} and ${right.r} ${right.g} ${right.b}');
		UnloadImage(image);
	}
	#end
}
