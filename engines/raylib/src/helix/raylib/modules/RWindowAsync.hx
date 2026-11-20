package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix4;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.ObjModels;
import helix.formats.obj.MtlFile;
import helix.formats.obj.ObjFile;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.internal.CallbackFiles;
import helix.raylib.internal.WaveReader;
import helix.raylib.internal.Waves;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.internal.Answers.*;
import helix.raylib.modules.RFilesAsync.*;
import helix.raylib.modules.RTexturesAsync.*;
import helix.raylib.modules.RTextAsync.*;
import helix.raylib.modules.RModelsAsync.*;
import helix.raylib.modules.RAudioAsync.*;
#end

/** Holds the async versions of rcore's window, cursor and clipboard calls, which replace raylib's calls that wait for the
	window.

	`helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RWindowAsync {
	#if !macro
	/** Asynchronously asks for fullscreen, or for the window back at the size and place it had. See
		`ToggleBorderlessWindowedAsync` for the borderless window, replacing raylib's `ToggleFullscreen`.

		It may wait for the next key press, click or tap, or be refused.

		Called while borderless, it only switches to fullscreen.

		`IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.

		@param done  Optional. Called once the window has changed, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleFullscreenAsync", false, done, failed);
	}

	/** Asynchronously asks for the window to fill the screen without borders, or back to the window. See
		`ToggleFullscreenAsync` for fullscreen, replacing raylib's `ToggleBorderlessWindowed`.

		The window fills the screen without borders.

		It may wait for the next key press, click or tap, as `ToggleFullscreenAsync` may.

		Called while fullscreen, it only switches to borderless.

		As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.

		@param done  Optional. Called once the window has changed, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleBorderlessWindowedAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleBorderlessWindowedAsync", true, done, failed);
	}

	// Asks the screen for fullscreen, or borderless, or the window when it is that already. A fullscreen screen asked for the other of
	// the two only changes which it is. A refusal, or a window that can't be fullscreen, is refused for the request named.
	static function toggleFullscreen(name:String, borderless:Bool, done:Null<Void->Void>, failed:Null<String->Void>):Void {
		var screen = Runtime.screen;
		var leaving = screen.fullscreen && Runtime.borderless == borderless;
		if (screen.fullscreen && !leaving) {
			Runtime.borderless = borderless;
			Runtime.later(answered(done));
			return;
		}
		ask(name, (granted, refused) -> screen.requestFullscreen(!leaving, () -> {
			Runtime.borderless = borderless && !leaving;
			granted();
		}, refused), "the window can't be fullscreen here", done, failed);
	}

	/** Asynchronously asks for the window's size, replacing raylib's `SetWindowSize`. See `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync` for limiting how small or large it can be.

		The window manager may set another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

		Refused while the window is fullscreen or maximized, and where the system doesn't allow it.

		A size under 1 pixel is refused.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param done  Optional. Called once the window has a size from the request, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't resized; when omitted, it is logged. */
	static function SetWindowSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowSizeAsync", (granted, refused) -> Runtime.window.requestSize(width, height, granted, refused), '$width x $height is under 1 pixel',
			done, failed);
	}

	/** Asynchronously asks for the window's place on the desktop, replacing raylib's `SetWindowPosition`. See `SetWindowMonitorAsync` for moving it to another monitor.

		Refused while the window is fullscreen or maximized, and where the system doesn't allow it, as Wayland doesn't.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels.
		@param done  Optional. Called once the window has moved, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it didn't move; when omitted, it is logged. */
	static function SetWindowPositionAsync(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowPositionAsync", (granted, refused) -> Runtime.window.requestPosition(x, y, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window on another monitor, replacing raylib's `SetWindowMonitor`. See `SetWindowPositionAsync` for placing it on the desktop.

		Where the window can't be moved, a monitor other than its own is refused.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`.
		@param done  Optional. Called once the window is on the monitor, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged. */
	static function SetWindowMonitorAsync(monitor:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMonitorAsync", (granted, refused) -> Runtime.window.requestMonitorIndex(monitor, granted, refused), 'there is no monitor $monitor',
			done, failed);
	}

	/** Asynchronously asks for the window maximized, replacing raylib's `MaximizeWindow`. See `RestoreWindowAsync` for bringing it back.

		Refused where the system can't maximize the window.

		@param done  Optional. Called once the window is maximized, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MaximizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MaximizeWindowAsync", (granted, refused) -> Runtime.window.requestMaximized(true, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window minimized, replacing raylib's `MinimizeWindow`. See `RestoreWindowAsync` for bringing it back.

		Refused where the system can't minimize the window.

		@param done  Optional. Called once the window is minimized, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MinimizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MinimizeWindowAsync", (granted, refused) -> Runtime.window.requestMinimized(true, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window back to its size from minimized or maximized, replacing raylib's `RestoreWindow`. See `MaximizeWindowAsync` and
		`MinimizeWindowAsync` for changing it.

		A minimized window is restored from minimized, any other from maximized.

		@param done  Optional. Called once the window is restored, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function RestoreWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		var window = Runtime.window;
		ask("RestoreWindowAsync",
			(granted, refused) -> window.minimized ? window.requestMinimized(false, granted, refused) : window.requestMaximized(false, granted, refused), "",
			done, failed);
	}

	/** Asynchronously asks for the window brought to the front with the keyboard, replacing raylib's `SetWindowFocused`.

		A window manager may only flash it.

		@param done  Optional. Called once the window has the keyboard or the window manager keeps it elsewhere, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowFocusedAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowFocusedAsync", (granted, refused) -> Runtime.window.requestFocus(granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window's opacity, replacing raylib's `SetWindowOpacity`.

		A desktop without a compositor refuses it.

		@param opacity  From 0 (clear) to 1 (opaque).
		@param done  Optional. Called once the window has the opacity, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowOpacityAsync(opacity:Float, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowOpacityAsync", (granted, refused) -> Runtime.window.requestOpacity(opacity, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the smallest size the window may have, replacing raylib's `SetWindowMinSize`. See `SetWindowMaxSizeAsync` for setting the largest.

		Refused where the system doesn't allow it.

		A size under 0 pixels is refused.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMinSizeAsync", (granted, refused) -> Runtime.window.requestMinimumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asynchronously asks for the largest size the window may have, replacing raylib's `SetWindowMaxSize`. See `SetWindowMinSizeAsync` for setting the smallest.

		Refused where the system doesn't allow it.

		A size under 0 pixels is refused.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMaxSizeAsync", (granted, refused) -> Runtime.window.requestMaximumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asynchronously locks the mouse to the window and hides the cursor, for looking around, replacing raylib's `DisableCursor`. See `EnableCursorAsync`
		for letting it go.

		`GetMouseDelta` keeps coming while the position goes on past the window's edges.

		`IsCursorHidden` is true from the call.

		The lock may wait for the next click or key press, or be refused.

		@param done  Optional. Called once the mouse is locked, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function DisableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("DisableCursorAsync", (granted, refused) -> mouse.requestLock(true, granted, refused), "the mouse can't be locked here", done, failed);
		RCore.cursorHidden = true;
	}

	/** Asynchronously lets go of the mouse that `DisableCursorAsync` locked and shows the cursor, replacing raylib's `EnableCursor`.

		`IsCursorHidden` is false from the call.

		@param done  Optional. Called once the mouse is let go, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function EnableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("EnableCursorAsync", (granted, refused) -> mouse.requestLock(false, granted, refused), "the mouse can't be let go here", done, failed);
		mouse.cursorVisible = true;
		RCore.cursorHidden = false;
	}

	/** Asynchronously puts text on the system's clipboard, replacing raylib's `SetClipboardText`. See `GetClipboardTextAsync` for reading it.

		It may be refused unless it comes soon after a key press.

		@param text  The text.
		@param done  Optional. Called once the text is on the clipboard, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it isn't; when omitted, it is logged. */
	static function SetClipboardTextAsync(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		var clipboard = Runtime.clipboard();
		ask("SetClipboardTextAsync", (granted, refused) -> {
			clipboard.setText(text, granted, refused);
			return true;
		}, "", done, failed);
	}

	/** Asynchronously reads the clipboard's text, replacing raylib's `GetClipboardText`. See `GetClipboardImageAsync` for reading an image.

		It may need permission, which the system may ask for.

		@param read  Receives the text at a later poll; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardTextAsync(read:String->Void, ?failed:String->Void):Void {
		Runtime.clipboard().requestText(read, error -> refuse("GetClipboardTextAsync", error, failed));
	}

	/** Asynchronously reads the clipboard's image, replacing raylib's `GetClipboardImage`. See `GetClipboardTextAsync` for reading text.

		It may need permission, which the system may ask for.

		@param loaded  Receives the image once it is decoded, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void):Void {
		Runtime.imaging();
		Runtime.clipboard()
			.requestImage(png -> decoded("GetClipboardImageAsync", ".png", png, loaded, failed), error -> refuse("GetClipboardImageAsync", error, failed));
	}

	// Captures the screen for TakeScreenshot, calling done once it is written or refused, at a later poll. With a frame to read
	// (FrameReads.hasScreen), the screen as drawn so far, the batch drawn first, or between frames the frame last shown. With none yet, the next frame as it is
	// shown: done is called at once, and the screenshot is among Runtime.screenshotsAsked until it is written or refused, so the next
	// EndDrawing waits for it. Once CloseWindow refused it, nothing more is written or logged.
	static function takeScreenshot(fileName:String, done:Void->Void):Void {
		var refused = (error:String) -> {
			Runtime.log(LOG_WARNING, 'TakeScreenshot: $error');
			done();
		};
		if (fileName.indexOf("'") >= 0) {
			Runtime.later(() -> refused('$fileName: Provided fileName could be potentially malicious, avoid [\'] character'));
			return;
		}
		var name = GetFileName(fileName);
		var exporter = Runtime.exporter();
		#if !js
		// raylib 6.2's: a relative name under the working directory, an absolute one as it is.
		var slash = lastSlash(fileName);
		if (slash >= 0) {
			var directory = fileName.substr(0, slash == 0 ? 1 : slash);
			if (!isPathAbsolute(fileName))
				directory = haxe.io.Path.join([Sys.getCwd(), directory]);
			if (!sys.FileSystem.exists(directory) || !sys.FileSystem.isDirectory(directory)) {
				Runtime.later(() -> refused('$fileName: Screenshot could not be saved: $directory isn\'t a directory'));
				return;
			}
			exporter = new helix.platform.adapters.export.filesystem.FileSystemExportAdapter({directory: directory});
		}
		#end
		var frame = Runtime.frame;
		if (frame == null) {
			Runtime.later(() -> refused('$name: Screenshot could not be saved: InitWindow first'));
			return;
		}
		// Writes the pixels read, then calls saved, or failed with why not.
		function save(pixels:haxe.io.Bytes, width:Int, height:Int, saved:Void->Void, failed:String->Void):Void {
			for (i in 0...width * height)
				pixels.set(i * 4 + 3, 255);
			var file = RTextures.encodeImage(new Image(pixels, width, height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8), name);
			if (file == null) {
				failed('$name: Screenshot could not be saved: only .png, .qoi and .raw files are written');
				return;
			}
			var type = IsFileExtension(name, ".png") ? "image/png" : IsFileExtension(name, ".qoi") ? "image/qoi" : "application/octet-stream";
			exporter.export(name, type, file, where -> {
				Runtime.log(LOG_INFO, 'FILEIO: [$where] Image exported successfully');
				Runtime.log(LOG_INFO, 'SYSTEM: [$where] Screenshot taken successfully');
				saved();
			}, error -> failed('$name: Screenshot could not be saved: $error'));
		}
		var framebufferWidth = Runtime.window.framebufferWidth,
			framebufferHeight = Runtime.window.framebufferHeight;
		// The draws waiting in the batch are the frame's too, a frame to read where they are all it has drawn.
		frame.cut();
		if (helix.raylib.internal.Frame.FrameReads.hasScreen(frame)) {
			helix.raylib.internal.Frame.FrameReads.readScreen(frame, framebufferWidth, framebufferHeight,
				(pixels, width, height) -> Runtime.later(() -> save(pixels, width, height, done, refused)),
				error -> Runtime.later(() -> refused('$name: Screenshot could not be saved: $error')));
			return;
		}
		var asked = {fileName: fileName};
		Runtime.screenshotsAsked.push(asked);
		var dropped = () -> Runtime.screenshotsAsked.indexOf(asked) < 0;
		var failed = (error:String) -> {
			if (dropped())
				return;
			Runtime.screenshotsAsked.remove(asked);
			Runtime.log(LOG_WARNING, 'TakeScreenshot: $error');
		};
		helix.raylib.internal.Frame.FrameReads.readNext(frame, (pixels, width, height) -> {
			if (!dropped())
				save(pixels, width, height, () -> Runtime.screenshotsAsked.remove(asked), failed);
		}, error -> failed('$name: Screenshot could not be saved: $error'));
		Runtime.later(done);
	}
	#end
}
