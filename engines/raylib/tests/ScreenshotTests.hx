import haxe.io.Bytes;
import helix.platform.IExport;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.screen.Screen;

/** Checks `TakeScreenshot` on graphics that read back a frame of two pixels, its files handed to the test: the screenshot is of the
	frame that ends next and is written as that frame ends, a screenshot that can't be saved is refused with the reason logged, and
	`CloseWindow` refuses a screenshot with no frame ended after `TakeScreenshot`, writing none. Run by helix.py test on Node and
	natively. */
@:access(helix.raylib.internal.Runtime)
class ScreenshotTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var warnings:Array<String> = [];
		SetTraceLogLevel(LOG_WARNING);
		SetTraceLogCallback((level, text) -> if (level == LOG_WARNING) warnings.push(text));
		var written = new WrittenFiles();
		Runtime.exportAdapter = written;

		TakeScreenshot("early.png");
		Runtime.pollAnswers();
		check(warnings.length == 1 && warnings[0] == "TakeScreenshot: early.png: Screenshot could not be saved: InitWindow first",
			'before InitWindow, refused: $warnings');
		check(Runtime.screenshotsAsked.length == 0, "a refused screenshot isn't waited for");

		var graphics = new ReadingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);

		Runtime.frame.begin(64, 64);
		TakeScreenshot("shot.png");
		check(written.names.length == 0 && Runtime.screenshotsAsked.length == 1, "TakeScreenshot returns before the file is written");
		Runtime.showFrame();
		check(written.names.join(",") == "shot.png" && written.types[0] == "image/png", 'written as the frame ends: ${written.names}');
		var png = written.files[0];
		check(png.get(1) == "P".code && png.get(2) == "N".code && png.get(3) == "G".code, "a PNG file");
		check(Runtime.screenshotsAsked.length == 0, "EndDrawing has no screenshot left to wait for");

		// Asked for between frames, the screenshot is of the next frame.
		TakeScreenshot("next.qoi");
		Runtime.frame.begin(64, 64);
		check(written.names.length == 1, "nothing written until the frame ends");
		Runtime.showFrame();
		check(written.names.join(",") == "shot.png,next.qoi", 'the next frame, written: ${written.names}');

		Runtime.frame.begin(64, 64);
		TakeScreenshot("shot.jpg");
		Runtime.showFrame();
		check(warnings.length == 2
			&& warnings[1] == "TakeScreenshot: shot.jpg: Screenshot could not be saved: only .png, .qoi and .raw files are written",
			'a format that isn\'t written, refused: $warnings');
		check(Runtime.screenshotsAsked.length == 0 && written.names.length == 2, "and not waited for");

		TakeScreenshot("it's.png");
		Runtime.pollAnswers();
		check(warnings.length == 3
			&& StringTools.startsWith(warnings[2], "TakeScreenshot: it's.png: Provided fileName could be potentially malicious"),
			'a name with \' refused, as raylib\'s is: $warnings');
		check(Runtime.screenshotsAsked.length == 0 && written.names.length == 2, "and not waited for");

		// No frame ends after the last TakeScreenshot: CloseWindow refuses the screenshot, and the frame a page clears as it closes isn't
		// written.
		TakeScreenshot("late.png");
		CloseWindow();
		check(warnings.length == 4
			&& warnings[3] == "TakeScreenshot: late.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()",
			'CloseWindow refuses a screenshot no frame ended after: $warnings');
		check(written.names.length == 2 && Runtime.screenshotsAsked.length == 0, 'and writes none: ${written.names}');

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}

// Graphics reading a frame back as two pixels.
private class ReadingGraphics extends CountingGraphics {
	override public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		read(Bytes.alloc(8), 2, 1);
	}
}

// Keeps the files handed to it.
private class WrittenFiles implements IExport {
	public final names:Array<String> = [];
	public final types:Array<String> = [];
	public final files:Array<Bytes> = [];

	public function new() {}

	public function export(name:String, mimeType:String, bytes:Bytes, exported:(where:String) -> Void, failed:String->Void):Void {
		names.push(name);
		types.push(mimeType);
		files.push(bytes);
		exported(name);
	}
}
