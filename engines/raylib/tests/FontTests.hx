import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.screen.Screen;

/** Checks the text functions when provided a null font, as a program's font is until its `...Async` load's `loaded` is called, on graphics
	that keep nothing: the draws and `MeasureTextEx` refused, the reason logged the first time alone, drawing nothing and measuring
	0 by 0; `IsFontValid` false; the glyph lookups returning index 0, an empty glyph and an empty rectangle; and a font with no texture
	drawn as the default font, as before. Run by helix.py test on Node and natively. */
@:access(helix.raylib.internal.Frame)
class FontTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The sprites a call adds to the frame.
	static function sprites(draw:Void->Void):Int {
		var before = Runtime.frame.sprites;
		draw();
		return Runtime.frame.sprites - before;
	}

	static function main():Void {
		var warnings:Array<String> = [];
		SetTraceLogLevel(LOG_WARNING);
		SetTraceLogCallback((level, text) -> if (level == LOG_WARNING) warnings.push(text));
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);
		Runtime.frame.begin(64, 64);
		var none:Font = null, at = new Vector2(0, 0);

		var drawn = sprites(() -> DrawTextEx(GetFontDefault(), "Hi", at, 10, 1, WHITE));
		check(drawn == 2, 'two letters in the default font: $drawn');
		check(sprites(() -> DrawTextEx(new Font(), "Hi", at, 10, 1, WHITE)) == drawn, "a font with no texture draws as the default font");
		check(warnings.length == 0, 'nothing logged for a font with no texture: $warnings');

		check(sprites(() -> DrawTextEx(none, "Hi", at, 10, 1, WHITE)) == 0, "DrawTextEx: a null font draws nothing");
		check(warnings.length == 1
			&& warnings[0] == "FONT: DrawTextEx refused: the font is null. An asynchronously loaded font is invalid until its loaded callback is called.",
			'the refusal, logged: $warnings');
		check(sprites(() -> DrawTextPro(none, "Hi", at, at, 30, 10, 1, WHITE)) == 0, "DrawTextPro");
		check(sprites(() -> DrawTextCodepoint(none, "H".code, at, 10, WHITE)) == 0, "DrawTextCodepoint");
		check(sprites(() -> DrawTextCodepoints(none, ["H".code, "i".code], 2, at, 10, 1, WHITE)) == 0, "DrawTextCodepoints");
		var size = MeasureTextEx(none, "Hi", 10, 1);
		check(size.x == 0 && size.y == 0, 'MeasureTextEx: 0 by 0: $size');
		check(warnings.length == 1, 'logged the first time alone, as text is drawn each frame: $warnings');

		check(!IsFontValid(none), "IsFontValid: false for null");
		check(GetGlyphIndex(none, "H".code) == 0, "GetGlyphIndex: 0");
		var glyph = GetGlyphInfo(none, "H".code);
		check(glyph != null && glyph.value == 0 && glyph.advanceX == 0, "GetGlyphInfo: an empty glyph");
		var rec = GetGlyphAtlasRec(none, "H".code);
		check(rec != null && rec.width == 0 && rec.height == 0, "GetGlyphAtlasRec: an empty rectangle");
		check(GetGlyphInfo(GetFontDefault(), "H".code).value == "H".code, "a valid font's glyph, as before");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
