import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Rlgl.*;
import js.Browser;

/** Checks the screen reads that wait in a page on WebGL2 (tools/test_raylib_pages.py): a render texture cleared blue with its left half
	drawn red, read by `LoadImageFromTexture`, holds both; the screen read part way through each frame, its left half drawn red over a
	green clear, holds both at the framebuffer's size, opaque; the frame goes on, its top left quarter drawn blue on top, which the tool
	checks on the page's screenshot (ScreenReadPage.check.json) with the red and the green kept. The screen read after the last frame,
	between frames, holds that frame: the blue over the red, and the green. Leaves {passed, checks, failures} in `window.helixResult`. */
class ScreenReadPage {
	static var checks = 0;
	static final failures:Array<String> = [];

	static function check(value:Bool, message:String):Void {
		if (value)
			checks++;
		else
			failures.push(message);
	}

	// A pixel's color, "r g b a".
	static function pixel(image:Image, x:Int, y:Int):String {
		var at = (y * image.width + x) * 4;
		return '${image.data.get(at)} ${image.data.get(at + 1)} ${image.data.get(at + 2)} ${image.data.get(at + 3)}';
	}

	static function main():Void {
		InitWindow(320, 240, "screen reads");
		var target = LoadRenderTexture(4, 4);
		var frames = 0;
		while (!WindowShouldClose() && frames < 5) {
			BeginDrawing();
			BeginTextureMode(target);
			ClearBackground(BLUE);
			DrawRectangle(0, 0, 2, 4, RED);
			EndTextureMode();
			var texture = LoadImageFromTexture(target.texture);
			check(texture.width == 4 && texture.height == 4, 'the render texture\'s size: ${texture.width} x ${texture.height}');
			check(pixel(texture, 0, 1) == "230 41 55 255" && pixel(texture, 3, 2) == "0 121 241 255",
				'the render texture\'s red and blue: ${pixel(texture, 0, 1)}, ${pixel(texture, 3, 2)}');

			var width = GetScreenWidth(), height = GetScreenHeight();
			ClearBackground(GREEN);
			DrawRectangle(0, 0, Std.int(width / 2), height, RED);
			rlDrawRenderBatchActive();
			var screen = LoadImageFromScreen();
			check(screen.width == GetRenderWidth() && screen.height == GetRenderHeight(),
				'the framebuffer\'s size: ${screen.width} x ${screen.height}, ${GetRenderWidth()} x ${GetRenderHeight()}');
			var w = screen.width, h = screen.height;
			check(pixel(screen, Std.int(w / 4), Std.int(h / 4)) == "230 41 55 255"
				&& pixel(screen, Std.int(w * 3 / 4), Std.int(h / 2)) == "0 228 48 255",
				'the screen drawn so far, red over green: ${pixel(screen, Std.int(w / 4), Std.int(h / 4))}, ${pixel(screen, Std.int(w * 3 / 4), Std.int(h / 2))}');
			DrawRectangle(0, 0, Std.int(width / 2), Std.int(height / 2), BLUE);
			EndDrawing();
			frames++;
		}
		var last = LoadImageFromScreen();
		var w = last.width, h = last.height;
		check(w == GetRenderWidth() && h == GetRenderHeight(), 'between frames, the framebuffer\'s size: $w x $h');
		check(pixel(last, Std.int(w / 4), Std.int(h / 4)) == "0 121 241 255"
			&& pixel(last, Std.int(w / 4), Std.int(h * 3 / 4)) == "230 41 55 255"
			&& pixel(last, Std.int(w * 3 / 4), Std.int(h / 2)) == "0 228 48 255",
			'between frames, the frame last shown, blue and red over green: ${pixel(last, Std.int(w / 4), Std.int(h / 4))}, ${pixel(last, Std.int(w / 4), Std.int(h * 3 / 4))}, ${pixel(last, Std.int(w * 3 / 4), Std.int(h / 2))}');
		var result:Dynamic = {passed: failures.length == 0, checks: checks, failures: failures};
		Reflect.setField(Browser.window, "helixResult", result);
	}
}
