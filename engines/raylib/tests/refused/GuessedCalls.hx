import helix.raylib.Raylib.*;

/** A program calling refused functions with guessed arguments, which doesn't build on any target: `helix.py test` builds it for JS and
	natively and checks that each call is refused with its own message, whether given raylib's arguments, too few, too many or the wrong
	types. */
class GuessedCalls {
	static function main():Void {
		InitWindow(320, 200, "refused");
		TakeScreenshot();
		TakeScreenshot("shot.png");
		var pixels = LoadImageFromTexture(1, 2);
		var text = GetClipboardText("all");
		DisableCursor(true);
		SetClipboardText(1, 2);
		CloseWindow();
	}
}
