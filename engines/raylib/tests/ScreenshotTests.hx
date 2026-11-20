import haxe.io.Bytes;
import helix.platform.IExport;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.screen.Screen;

/** Checks `TakeScreenshot` on graphics that read back two pixels, its files handed to the test. The first call with nothing drawn on
	the screen returns at once, and its screenshot is of the next frame, written as that frame ends. From then on the frames are kept: a
	call between frames writes the frame last shown, and one during a frame the frame drawn so far, each before it returns, read from
	the kept target. A first call in a frame whose draws all wait in rlgl's batch draws the batch and writes that frame. A screenshot that can't be saved is refused with the reason logged, and `CloseWindow` refuses a first screenshot
	left for a frame that never ended, writing none. Run by helix.py test on Node and natively. */
@:access(helix.raylib.internal.Runtime)
class ScreenshotTests {
	public static var checks = 0;

	public static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function report(_:Int):Void {
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function main():Void {
		Runtime.exitKey = 0;
		Runtime.system = new FakeSystem();
		Runtime.time = new helix.services.time.Time(Runtime.system);
		#if js
		Runtime.requestFrame = f -> haxe.Timer.delay(() -> f(0), 0);
		(Screenshots.all() : Dynamic).then(report, error -> {
			js.Syntax.code("console.log({0})", Std.string(error));
			js.Syntax.code("process.exit(1)");
		});
		#else
		report(Screenshots.all());
		#end
	}
}

/** The screenshots, built as a program's classes are. */
@:build(helix.raylib.internal.Wait.build())
@:access(helix.raylib.internal.Runtime)
class Screenshots {
	/** Captures every screenshot and checks it.

		@return  The checks made. */
	public static function all():Int {
		var warnings:Array<String> = [];
		SetTraceLogLevel(LOG_WARNING);
		SetTraceLogCallback((level, text) -> if (level == LOG_WARNING) warnings.push(text));
		var written = new WrittenFiles();
		Runtime.exportAdapter = written;

		TakeScreenshot("early.png");
		ScreenshotTests.check(warnings.length == 1
			&& warnings[0] == "TakeScreenshot: early.png: Screenshot could not be saved: InitWindow first",
			'before InitWindow, refused: $warnings');
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 0, "a refused screenshot isn't waited for");

		var graphics = new ReadingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);

		// The first, before the frame draws: of the frame as it ends.
		BeginDrawing();
		TakeScreenshot("shot.png");
		ScreenshotTests.check(written.names.length == 0 && Runtime.screenshotsAsked.length == 1, "TakeScreenshot returns before the file is written");
		ClearBackground(RED);
		EndDrawing();
		var kept = graphics.targets[0];
		ScreenshotTests.check(graphics.targets.length == 1 && graphics.reads.join(",") == '$kept',
			'the frame kept in a target, read as it ends: ${graphics.targets}, ${graphics.reads}');
		ScreenshotTests.check(written.names.join(",") == "shot.png"
			&& written.types[0] == "image/png", 'written as the frame ends: ${written.names}');
		var png = written.files[0];
		ScreenshotTests.check(png.get(1) == "P".code && png.get(2) == "N".code && png.get(3) == "G".code, "a PNG file");
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 0, "EndDrawing has no screenshot left to wait for");

		// Between frames: the frame last shown, from the kept target, written before the call returns.
		TakeScreenshot("last.qoi");
		ScreenshotTests.check(written.names.join(",") == "shot.png,last.qoi" && written.types[1] == "image/qoi",
			'the frame last shown, written: ${written.names}');
		ScreenshotTests.check(graphics.reads.join(",") == '$kept,$kept', 'read from the kept target: ${graphics.reads}');
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 0, "nothing left for EndDrawing");

		// During a frame: the frame drawn so far.
		BeginDrawing();
		ClearBackground(BLUE);
		TakeScreenshot("now.raw");
		ScreenshotTests.check(written.names.join(",") == "shot.png,last.qoi,now.raw"
			&& graphics.reads.length == 3
			&& graphics.reads[2] == kept,
			'the frame drawn so far, written: ${written.names}, ${graphics.reads}');
		ScreenshotTests.check(written.files[2].length == 8 && written.files[2].get(3) == 255, "the raw pixels, opaque");

		TakeScreenshot("shot.jpg");
		ScreenshotTests.check(warnings.length == 2
			&& warnings[1] == "TakeScreenshot: shot.jpg: Screenshot could not be saved: only .png, .qoi and .raw files are written",
			'a format that isn\'t written, refused: $warnings');
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 0 && written.names.length == 3, "and not waited for");
		EndDrawing();

		TakeScreenshot("it's.png");
		ScreenshotTests.check(warnings.length == 3
			&& StringTools.startsWith(warnings[2], "TakeScreenshot: it's.png: Provided fileName could be potentially malicious"),
			'a name with \' refused, as raylib\'s is: $warnings');
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 0 && written.names.length == 3, "and not waited for");

		// A new window's first, in a frame whose draws all wait in rlgl's batch: the batch is drawn, and the frame written before the call
		// returns.
		Runtime.frame = new Frame(graphics);
		var drawn = graphics.drawnTextures.length;
		BeginDrawing();
		DrawRectangle(0, 0, 2, 2, RED);
		TakeScreenshot("batched.png");
		ScreenshotTests.check(written.names.join(",") == "shot.png,last.qoi,now.raw,batched.png" && Runtime.screenshotsAsked.length == 0,
			'a frame of batched draws alone, written: ${written.names}');
		ScreenshotTests.check(graphics.drawnTextures.length == drawn + 1, 'the batch drawn before the read: ${graphics.drawnTextures.length - drawn}');
		EndDrawing();

		// A new window's first, between frames, with no frame ended after it: CloseWindow refuses it, and the frame a page clears as it
		// closes isn't written.
		Runtime.frame = new Frame(graphics);
		TakeScreenshot("late.png");
		ScreenshotTests.check(Runtime.screenshotsAsked.length == 1 && written.names.length == 4, "left for the next frame");
		CloseWindow();
		ScreenshotTests.check(warnings.length == 4
			&& warnings[3] == "TakeScreenshot: late.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()",
			'CloseWindow refuses a screenshot no frame ended after: $warnings');
		ScreenshotTests.check(written.names.length == 4 && Runtime.screenshotsAsked.length == 0, 'and writes none: ${written.names}');
		return ScreenshotTests.checks;
	}
}

// Graphics reading a frame back as two pixels, keeping the render targets made and the handles read.
private class ReadingGraphics extends CountingGraphics {
	/** The render targets made, in order. */
	public final targets:Array<Int> = [];

	/** The handles read, in order. */
	public final reads:Array<Int> = [];

	override public function createRenderTarget(width:Int, height:Int, format:helix.platform.TextureFormat = Rgba8,
			depth:helix.platform.RenderTargetDepth = Buffer, msaaSampleCount:Int = 0, bottomRowFirst:Bool = false):Int {
		var handle = super.createRenderTarget(width, height, format, depth, msaaSampleCount, bottomRowFirst);
		targets.push(handle);
		return handle;
	}

	override public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		reads.push(handle);
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
