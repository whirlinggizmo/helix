import haxe.io.Bytes;
import helix.platform.IClipboard;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.services.input.Mouse;
import helix.services.saves.Saves;
import helix.services.screen.Screen;

/** Checks helix-raylib's Async requests and writes over fakes (services' `FakeWindow`, `FakeEvents`, `FakeDevices` and
	`FakeFileSystem`, and a clipboard here): each answers once, at a later poll and never during its call, `done` once the platform
	reflects it and `failed` with the reason where it refuses; a request the platform can't ask is refused with why; a write is done
	once the saves are written, or the program's save callback has said it wrote, and fails when they can't be. */
@:access(helix.raylib.internal.Runtime)
class AsyncTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var window:FakeWindow;
	static var devices:FakeDevices;
	static var clipboard:FakeClipboard;

	// A frame's polls, as Runtime's: the services, the work left for later, then the events, which the window's answers come after.
	static function frame():Void {
		Runtime.pollAll();
		var now = Runtime.waiting;
		Runtime.waiting = [];
		for (f in now)
			f();
		Runtime.events.poll();
		window.answer();
		devices.answer();
		clipboard.answer();
	}

	static function pump(answered:Void->Bool):Void {
		for (_ in 0...1000) {
			if (answered())
				return;
			frame();
		}
		throw "never answered";
	}

	// Calls a request, checking it answers once, after its call: "done", or "failed: " and the reason.
	static function answer(request:(done:Void->Void, failed:String->Void)->Void):String {
		var answers:Array<String> = [], calling = true;
		request(() -> answers.push(calling ? "during the call" : "done"), error -> answers.push(calling ? "during the call" : 'failed: $error'));
		calling = false;
		pump(() -> answers.length > 0);
		for (_ in 0...3)
			frame();
		check(answers.length == 1, 'answered once: $answers');
		return answers[0];
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		window = new FakeWindow();
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);
		devices = new FakeDevices();
		Runtime.mouseAdapter = devices;
		Runtime.mouseService = new Mouse(Runtime.events, devices);
		clipboard = new FakeClipboard();
		Runtime.clipboardAdapter = clipboard;
		var files = new FakeFileSystem();
		Runtime.polled.push(files);
		Runtime.saves = new Saves(files);
		Runtime.polled.push(Runtime.saves);

		// The window's requests.
		check(answer((d, f) -> SetWindowSizeAsync(640, 360, d, f)) == "done"
			&& GetScreenWidth() == 640, "SetWindowSizeAsync: done once resized");
		check(answer((d, f) -> SetWindowSizeAsync(0, 360, d, f)) == "failed: 0 x 360 is under 1 pixel", "a size the window can't ask for is refused");
		window.refusing.push("size");
		check(answer((d, f) -> SetWindowSizeAsync(800, 600, d, f)) == "failed: size refused" && GetScreenWidth() == 640,
			"the platform's refusal, its reason given");
		check(answer((d, f) -> SetWindowPositionAsync(10, 20, d, f)) == "done" && GetWindowPosition().x == 10, "SetWindowPositionAsync");
		check(answer((d, f) -> MaximizeWindowAsync(d, f)) == "done" && IsWindowMaximized(), "MaximizeWindowAsync");
		check(answer((d, f) -> RestoreWindowAsync(d, f)) == "done" && !IsWindowMaximized(), "RestoreWindowAsync from maximized");
		check(answer((d, f) -> MinimizeWindowAsync(d, f)) == "done" && IsWindowMinimized(), "MinimizeWindowAsync");
		check(answer((d, f) -> RestoreWindowAsync(d, f)) == "done" && !IsWindowMinimized(), "RestoreWindowAsync from minimized");
		check(answer((d, f) -> SetWindowMonitorAsync(1, d, f)) == "done" && GetCurrentMonitor() == 1, "SetWindowMonitorAsync");
		check(answer((d, f) -> SetWindowMonitorAsync(5, d, f)) == "failed: there is no monitor 5", "a monitor that isn't there");
		check(answer((d, f) -> SetWindowOpacityAsync(.5, d, f)) == "done" && window.opacity == .5, "SetWindowOpacityAsync");
		check(answer((d, f) -> SetWindowMinSizeAsync(100, 80, d, f)) == "done"
			&& answer((d, f) -> SetWindowMaxSizeAsync(1000, 800, d, f)) == "done"
			&& window.limits.join(",") == "minimum 100 80,maximum 1000 800",
			"SetWindowMinSizeAsync and SetWindowMaxSizeAsync");
		check(answer((d, f) -> SetWindowFocusedAsync(d, f)) == "done", "SetWindowFocusedAsync");
		window.refusing.push("focus");
		check(answer((d, f) -> SetWindowFocusedAsync(d, f)) == "failed: focus refused", "SetWindowFocusedAsync refused");
		check(answer((d, f) -> ToggleFullscreenAsync(d, f)) == "done" && IsWindowFullscreen(), "ToggleFullscreenAsync");
		check(answer((d, f) -> ToggleBorderlessWindowedAsync(d, f)) == "done"
			&& !IsWindowFullscreen(), "ToggleBorderlessWindowedAsync, back");

		// The cursor's lock and the clipboard, which the fakes answer at the next poll, as the platform's do.
		check(answer((d, f) -> DisableCursorAsync(d, f)) == "done"
			&& devices.locked
			&& IsCursorHidden(), "DisableCursorAsync: done after the call");
		check(answer((d, f) -> EnableCursorAsync(d, f)) == "done" && !devices.locked && !IsCursorHidden(), "EnableCursorAsync");
		check(answer((d, f) -> SetClipboardTextAsync("copied", d, f)) == "done" && clipboard.text == "copied", "SetClipboardTextAsync");
		clipboard.refusing = true;
		check(answer((d, f) -> SetClipboardTextAsync("again", d, f)) == "failed: no keyboard", "SetClipboardTextAsync refused");
		check(answer((d, f) -> GetClipboardTextAsync(text -> text == "copied" ? d() : f(text), f)) == "done", "GetClipboardTextAsync");

		// The writes, kept in the saves.
		check(answer((d, f) -> SaveFileTextAsync("notes.txt", "hello", d, f)) == "done"
			&& files.writes == 1, "SaveFileTextAsync: done once written");
		var read:Null<String> = null;
		LoadFileTextAsync("notes.txt", text -> read = text, e -> throw e);
		pump(() -> read != null);
		check(read == "hello", "and read back");
		check(answer((d, f) -> SaveFileDataAsync("bytes.bin", Bytes.ofString("abc"), 3, d, f)) == "done", "SaveFileDataAsync");
		var bytes:Null<Bytes> = null;
		LoadFileDataAsync("bytes.bin", b -> bytes = b, e -> throw e);
		pump(() -> bytes != null);
		check(bytes.toString() == "abc", "and read back");
		check(answer((d, f) -> SaveFileDataAsync("none.bin", Bytes.ofString("abc"), 9, d, f)) == "failed: none.bin: there are no 9 bytes to write",
			"more bytes than there are");
		files.failWrites = true;
		check(StringTools.startsWith(answer((d, f) -> SaveFileTextAsync("notes.txt", "lost", d, f)), "failed: notes.txt: "), "a write that fails");
		files.failWrites = false;
		var image = GenImageColor(2, 2, RED);
		check(answer((d, f) -> ExportImageAsync(image, "red.png", d, f)) == "done", "ExportImageAsync");
		check(answer((d, f) -> ExportImageAsync(image, "red.bmp", d, f)) == "failed: red.bmp: Failed to export image", "an image of another kind");
		check(answer((d, f) -> ExportImageAsCodeAsync(image, "red.h", d, f)) == "done", "ExportImageAsCodeAsync");
		check(answer((d, f) -> ExportDataAsCodeAsync(Bytes.ofString("abc"), 3, "abc.h", d, f)) == "done", "ExportDataAsCodeAsync");
		check(answer((d, f) -> ExportMeshAsync(GenMeshCube(1, 1, 1), "cube.ply", d, f)) == "failed: cube.ply: only .obj files are written",
			"ExportMeshAsync of another kind");

		// Through the program's callback, which writes during the call and answers by what it returned.
		var written = "";
		SetSaveFileTextCallback((fileName, text) -> {
			written = fileName;
			return fileName != "refused.obj";
		});
		check(answer((d, f) -> ExportMeshAsync(GenMeshCube(1, 1, 1), "cube.obj", d, f)) == "done"
			&& written == "cube.obj", "ExportMeshAsync");
		check(answer((d,
				f) -> ExportMeshAsync(GenMeshCube(1, 1, 1), "refused.obj", d, f)) == "failed: refused.obj: the program's save callback didn't write it",
			"what the program's callback refused");
		check(answer((d, f) -> ExportMeshAsCodeAsync(GenMeshCube(1, 1, 1), "cube.h", d, f)) == "done", "ExportMeshAsCodeAsync");
		check(answer((d, f) -> ExportFontAsCodeAsync(GetFontDefault(), "font.h", d, f)) == "done", "ExportFontAsCodeAsync");
		var list = LoadAutomationEventList(null);
		check(answer((d, f) -> ExportAutomationEventListAsync(list, "list.txt", d, f)) == "done", "ExportAutomationEventListAsync");
		var wave = new Wave(4, 8000, 16, 1, Bytes.alloc(8));
		check(answer((d, f) -> ExportWaveAsCodeAsync(wave, "wave.h", d, f)) == "done", "ExportWaveAsCodeAsync");
		SetSaveFileDataCallback((fileName, data, size) -> true);
		check(answer((d, f) -> ExportWaveAsync(wave, "wave.wav", d, f)) == "done", "ExportWaveAsync");
		check(answer((d, f) -> ExportWaveAsync(wave, "wave.qoa", d, f)) == "failed: wave.qoa: Failed to export wave data", "a wave of another kind");

		// A screenshot needs the window's frame.
		check(answer((d, f) -> TakeScreenshotAsync("shot.png", d, f)) == "failed: shot.png: Screenshot could not be saved: InitWindow first",
			"TakeScreenshotAsync before InitWindow");
		check(StringTools.startsWith(answer((d, f) -> TakeScreenshotAsync("it's.png", d, f)),
			"failed: it's.png: Provided fileName could be potentially malicious"),
			"a name with ' refused, as raylib's is");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}

/** A clipboard answering at the next `answer`, as an `IEvents.poll` would: its text kept, or refused while `refusing`. */
class FakeClipboard implements IClipboard {
	/** Gets the text last put on it. */
	public var text(default, null) = "";

	/** Gets or sets whether writes are refused. */
	public var refusing = false;

	// The answers due at the next answer().
	var due:Array<Void->Void> = [];

	/** Creates an empty one. */
	public function new() {}

	/** Answers the calls made since the last one, as an `IEvents.poll` would. */
	public function answer():Void {
		var now = due;
		due = [];
		for (f in now)
			f();
	}

	public function requestText(read:String->Void, ?failed:String->Void):Bool {
		var kept = text;
		due.push(() -> read(kept));
		return true;
	}

	public function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		if (refusing) {
			due.push(() -> if (failed != null) failed("no keyboard"));
			return;
		}
		this.text = text;
		due.push(() -> if (done != null) done());
	}

	public function requestImage(read:Bytes->Void, ?failed:String->Void):Bool {
		due.push(() -> if (failed != null) failed("no image"));
		return true;
	}

	public function setImage(png:Bytes, ?done:Void->Void, ?failed:String->Void):Void {
		due.push(() -> if (failed != null) failed("no images"));
	}

	public function dispose():Void {}
}
