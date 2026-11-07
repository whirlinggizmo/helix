package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
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

/** Holds the async versions of rcore's window, cursor, clipboard and screenshot calls, which replace raylib's calls that wait for the
	window.

	`helix.raylib.extras.Window` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RWindowAsync {
	#if !macro
	/** Asynchronously asks for fullscreen, or for the window back at the size and place it had. See
		`ToggleBorderlessWindowedAsync` for the borderless window.

		It replaces raylib's `ToggleFullscreen`.

		In a page the browser grants it only soon after a key press, click or tap. Without one, it waits for the player's next, or refuses.

		Called while borderless, it only switches to fullscreen.

		`IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.

		@param done  Optional. Called once the window has changed, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleFullscreenAsync", false, done, failed);
	}

	/** Asynchronously asks for the window to fill the screen without borders, or back to the window. See
		`ToggleFullscreenAsync` for fullscreen.

		It replaces raylib's `ToggleBorderlessWindowed`.

		The screen goes fullscreen. Natively a fullscreen window is borderless and the size of the desktop.

		In a page it waits for a key press, click or tap, as `ToggleFullscreenAsync` does.

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

	/** Asynchronously asks for the window's size. See `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync` for limiting the sizes the player can make it.

		It replaces raylib's `SetWindowSize`.

		The window manager may give another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

		It is refused while the window is fullscreen or maximized, and in a page, whose canvas follows the page.

		A size under 1 pixel is refused.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param done  Optional. Called once the window has a size from the request, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't resized; when omitted, it is logged. */
	static function SetWindowSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowSizeAsync", (granted, refused) -> Runtime.window.requestSize(width, height, granted, refused), '$width x $height is under 1 pixel',
			done, failed);
	}

	/** Asynchronously asks for the window's place on the desktop. See `SetWindowMonitorAsync` for moving it to another monitor.

		It replaces raylib's `SetWindowPosition`.

		It is refused in a page, under Wayland, and while the window is fullscreen or maximized.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels.
		@param done  Optional. Called once the window has moved, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it didn't move; when omitted, it is logged. */
	static function SetWindowPositionAsync(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowPositionAsync", (granted, refused) -> Runtime.window.requestPosition(x, y, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window on another monitor. See `SetWindowPositionAsync` for placing it on the desktop.

		It replaces raylib's `SetWindowMonitor`.

		Where the window can't be moved, a monitor other than its own is refused.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`.
		@param done  Optional. Called once the window is on the monitor, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged. */
	static function SetWindowMonitorAsync(monitor:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMonitorAsync", (granted, refused) -> Runtime.window.requestMonitorIndex(monitor, granted, refused), 'there is no monitor $monitor',
			done, failed);
	}

	/** Asynchronously asks for the window maximized. See `RestoreWindowAsync` for bringing it back.

		It replaces raylib's `MaximizeWindow`.

		It is refused in a page, which can't maximize its window.

		@param done  Optional. Called once the window is maximized, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MaximizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MaximizeWindowAsync", (granted, refused) -> Runtime.window.requestMaximized(true, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window minimized. See `RestoreWindowAsync` for bringing it back.

		It replaces raylib's `MinimizeWindow`.

		It is refused in a page, which can't minimize its window.

		@param done  Optional. Called once the window is minimized, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MinimizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MinimizeWindowAsync", (granted, refused) -> Runtime.window.requestMinimized(true, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window back to its size from minimized or maximized. See `MaximizeWindowAsync` and
		`MinimizeWindowAsync` for changing it.

		It replaces raylib's `RestoreWindow`.

		A minimized window is restored from minimized, any other from maximized.

		@param done  Optional. Called once the window is restored, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function RestoreWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		var window = Runtime.window;
		ask("RestoreWindowAsync",
			(granted, refused) -> window.minimized ? window.requestMinimized(false, granted, refused) : window.requestMaximized(false, granted, refused), "",
			done, failed);
	}

	/** Asynchronously asks for the window brought to the front with the keyboard.

		It replaces raylib's `SetWindowFocused`.

		A window manager may only flash it.

		In a page the canvas takes the keyboard.

		@param done  Optional. Called once the window has the keyboard or the window manager keeps it elsewhere, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowFocusedAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowFocusedAsync", (granted, refused) -> Runtime.window.requestFocus(granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the window's opacity.

		It replaces raylib's `SetWindowOpacity`.

		In a page the canvas fades.

		A desktop without a compositor refuses it.

		@param opacity  From 0 (clear) to 1 (opaque).
		@param done  Optional. Called once the window has the opacity, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowOpacityAsync(opacity:Float, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowOpacityAsync", (granted, refused) -> Runtime.window.requestOpacity(opacity, granted, refused), "", done, failed);
	}

	/** Asynchronously asks for the smallest size the player can make the window. See `SetWindowMaxSizeAsync` for setting the largest.

		It replaces raylib's `SetWindowMinSize`.

		It is refused in a page, whose canvas follows the page.

		A size under 0 pixels is refused.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMinSizeAsync", (granted, refused) -> Runtime.window.requestMinimumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asynchronously asks for the largest size the player can make the window. See `SetWindowMinSizeAsync` for setting the smallest.

		It replaces raylib's `SetWindowMaxSize`.

		It is refused in a page, whose canvas follows the page.

		A size under 0 pixels is refused.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMaxSizeAsync", (granted, refused) -> Runtime.window.requestMaximumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asynchronously locks the mouse to the window and hides the cursor, for looking around. See `EnableCursorAsync`
		for letting it go.

		It replaces raylib's `DisableCursor`.

		`GetMouseDelta` keeps coming while the position goes on past the window's edges.

		`IsCursorHidden` is true from the call.

		In a page the browser locks it only soon after a click or key press. Without one, it locks at the player's next. Escape lets it go.

		@param done  Optional. Called once the mouse is locked, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function DisableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("DisableCursorAsync", (granted, refused) -> mouse.requestLock(true, granted, refused), "the mouse can't be locked here", done, failed);
		RCore.cursorHidden = true;
	}

	/** Asynchronously lets go of the mouse that `DisableCursorAsync` locked and shows the cursor.

		It replaces raylib's `EnableCursor`.

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

	/** Asynchronously puts text on the system's clipboard. See `GetClipboardTextAsync` for reading it.

		It replaces raylib's `SetClipboardText`.

		A page writes it only while it has the keyboard, soon after a press.

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

	/** Asynchronously reads the clipboard's text. See `GetClipboardImageAsync` for reading an image.

		It replaces raylib's `GetClipboardText`.

		A page reads it only with the player's permission, which the browser may ask for.

		@param read  Receives the text at a later poll; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardTextAsync(read:String->Void, ?failed:String->Void):Void {
		Runtime.clipboard().requestText(read, error -> refuse("GetClipboardTextAsync", error, failed));
	}

	/** Asynchronously reads the clipboard's image. See `GetClipboardTextAsync` for reading text.

		It replaces raylib's `GetClipboardImage`.

		A page reads it only with the player's permission.

		@param loaded  Receives the image once it is decoded, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void):Void {
		Runtime.imaging();
		Runtime.clipboard()
			.requestImage(png -> decoded("GetClipboardImageAsync", ".png", png, loaded, failed), error -> refuse("GetClipboardImageAsync", error, failed));
	}

	/** Asynchronously takes a screenshot of the next frame and saves it as a file. See `LoadImageFromScreenAsync` for
		the screen as an `Image`.

		It replaces raylib's `TakeScreenshot`.

		The name's extension picks the format, as `ExportImageAsync` does: ".png", ".qoi" or ".raw". Any other is refused.

		In a page it is downloaded under the name's file name, as raylib's web build does.

		Natively it is written where the name says, as raylib 6.2 writes it. A relative name is under the working directory, its directories
		kept. An absolute one is where it is.

		A directory that isn't there isn't made, and the screenshot is refused.

		It is taken as the next frame ends, not from the frame drawn last as raylib's is.

		Its alpha is opaque, as raylib's is.

		It is refused before `InitWindow`.

		@param fileName  The file's name, or its path; a name with `'` is refused, as raylib's is.
		@param done  Optional. Called once the file is written or downloaded, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function TakeScreenshotAsync(fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		var refused = (error:String) -> refuse("TakeScreenshotAsync", error, failed);
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
		if (Runtime.frame == null) {
			Runtime.later(() -> refused('$name: Screenshot could not be saved: InitWindow first'));
			return;
		}
		Runtime.screenshots().captureFrame(captured -> {
			var pixels = captured.pixels;
			for (i in 0...captured.width * captured.height)
				pixels.set(i * 4 + 3, 255);
			var file = RTextures.encodeImage(new Image(pixels, captured.width, captured.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8), name);
			if (file == null) {
				refused('$name: Screenshot could not be saved: only .png, .qoi and .raw files are written');
				return;
			}
			var type = IsFileExtension(name, ".png") ? "image/png" : IsFileExtension(name, ".qoi") ? "image/qoi" : "application/octet-stream";
			exporter.export(name, type, file, where -> {
				Runtime.log(LOG_INFO, 'FILEIO: [$where] Image exported successfully');
				Runtime.log(LOG_INFO, 'SYSTEM: [$where] Screenshot taken successfully');
				if (done != null)
					done();
			}, error -> refused('$name: Screenshot could not be saved: $error'));
		}, error -> refused('$name: Screenshot could not be saved: $error'));
	}
	#end
}
