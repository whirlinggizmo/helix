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

/** Holds the async versions of rcore's window, cursor, clipboard and screenshot calls, helix-raylib's own in place of raylib's calls
	that wait for the window. Each is written here, and `helix.raylib.extras.Window` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RWindowAsync {
	#if !macro
	/** Asks for fullscreen, or back to the window, the size and place it had, answering once it is granted or refused: helix-raylib's
		own, in place of raylib's `ToggleFullscreen`. In a page the browser grants it only soon after a key press, click or tap; without
		one, it waits for the player's next, or refuses. `IsWindowFullscreen` says the new state once the window has changed, not when
		the call returns.

		@param done  Optional. Called once the window has changed, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleFullscreenAsync", false, done, failed);
	}

	/** Asks for the window to fill the screen without borders, or back to the window, answering once it is granted or refused:
		helix-raylib's own, in place of raylib's `ToggleBorderlessWindowed`. The screen is asked for fullscreen, as a fullscreen window
		natively is borderless and the size of the desktop. As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it
		is, and `IsWindowFullscreen` false.

		@param done  Optional. Called once the window has changed, at a later poll.
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

	/** Asks for the window's size, answering once the window manager has resized it or refused: helix-raylib's own, in place of raylib's
		`SetWindowSize`. The window manager may give another size, which `GetScreenWidth` and `GetScreenHeight` say once it has. A
		fullscreen or maximized window keeps its size, and a page's canvas follows the page, so those are refused.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param done  Optional. Called once the window has a size from the request, at a later poll.
		@param failed  Optional. Receives why it wasn't resized; when omitted, it is logged. */
	static function SetWindowSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowSizeAsync", (granted, refused) -> Runtime.window.requestSize(width, height, granted, refused), '$width x $height is under 1 pixel',
			done, failed);
	}

	/** Asks for the window's place on the desktop, answering once it has moved or the move is refused: helix-raylib's own, in place of
		raylib's `SetWindowPosition`. Where the window can't be moved (in a page, or under Wayland), or while it is fullscreen or
		maximized, it is refused.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels.
		@param done  Optional. Called once the window has moved, at a later poll.
		@param failed  Optional. Receives why it didn't move; when omitted, it is logged. */
	static function SetWindowPositionAsync(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowPositionAsync", (granted, refused) -> Runtime.window.requestPosition(x, y, granted, refused), "", done, failed);
	}

	/** Asks for the window on another monitor, answering once it is there or the move is refused: helix-raylib's own, in place of raylib's
		`SetWindowMonitor`. Where the window can't be moved, a monitor other than its own is refused.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`.
		@param done  Optional. Called once the window is on the monitor, at a later poll.
		@param failed  Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged. */
	static function SetWindowMonitorAsync(monitor:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMonitorAsync", (granted, refused) -> Runtime.window.requestMonitorIndex(monitor, granted, refused), 'there is no monitor $monitor',
			done, failed);
	}

	/** Asks for the window maximized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's
		`MaximizeWindow`. A page can't maximize its window, so it is refused there.

		@param done  Optional. Called once the window is maximized, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MaximizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MaximizeWindowAsync", (granted, refused) -> Runtime.window.requestMaximized(true, granted, refused), "", done, failed);
	}

	/** Asks for the window minimized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's
		`MinimizeWindow`. A page can't minimize its window, so it is refused there.

		@param done  Optional. Called once the window is minimized, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MinimizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MinimizeWindowAsync", (granted, refused) -> Runtime.window.requestMinimized(true, granted, refused), "", done, failed);
	}

	/** Asks for the window back to its size from minimized or maximized, answering once it is or the window manager refuses:
		helix-raylib's own, in place of raylib's `RestoreWindow`.

		@param done  Optional. Called once the window is restored, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function RestoreWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		var window = Runtime.window;
		ask("RestoreWindowAsync",
			(granted, refused) -> window.minimized ? window.requestMinimized(false, granted, refused) : window.requestMaximized(false, granted, refused), "",
			done, failed);
	}

	/** Asks for the window brought to the front with the keyboard, answering once it has the keyboard or the window manager keeps it
		elsewhere: helix-raylib's own, in place of raylib's `SetWindowFocused`. A window manager may only flash it; in a page the canvas
		takes the keyboard.

		@param done  Optional. Called once the window has the keyboard, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowFocusedAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowFocusedAsync", (granted, refused) -> Runtime.window.requestFocus(granted, refused), "", done, failed);
	}

	/** Asks for the window see-through, answering once it is or it is refused: helix-raylib's own, in place of raylib's
		`SetWindowOpacity`. In a page the canvas fades; a desktop without a compositor refuses it.

		@param opacity  From 0 (clear) to 1 (opaque).
		@param done  Optional. Called once the window has the opacity, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowOpacityAsync(opacity:Float, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowOpacityAsync", (granted, refused) -> Runtime.window.requestOpacity(opacity, granted, refused), "", done, failed);
	}

	/** Asks for the smallest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place
		of raylib's `SetWindowMinSize`. A page's canvas follows the page, so it is refused there.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMinSizeAsync", (granted, refused) -> Runtime.window.requestMinimumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asks for the largest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place
		of raylib's `SetWindowMaxSize`. A page's canvas follows the page, so it is refused there.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMaxSizeAsync", (granted, refused) -> Runtime.window.requestMaximumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Locks the mouse to the window and hides the cursor, for looking around, answering once it is locked or refused: helix-raylib's own,
		in place of raylib's `DisableCursor`. `GetMouseDelta` keeps coming while the position goes on past the window's edges. In a page
		the browser locks it only soon after a click or key press, so without one it locks at the player's next, and Escape lets it go.
		`IsCursorHidden` is true from the call.

		@param done  Optional. Called once the mouse is locked, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function DisableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("DisableCursorAsync", (granted, refused) -> mouse.requestLock(true, granted, refused), "the mouse can't be locked here", done, failed);
		RCore.cursorHidden = true;
	}

	/** Lets go of the mouse that `DisableCursorAsync` locked, and shows the cursor, answering once it is let go: helix-raylib's own, in
		place of raylib's `EnableCursor`.

		@param done  Optional. Called once the mouse is let go, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function EnableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("EnableCursorAsync", (granted, refused) -> mouse.requestLock(false, granted, refused), "the mouse can't be let go here", done, failed);
		mouse.cursorVisible = true;
		RCore.cursorHidden = false;
	}

	/** Puts text on the system's clipboard, answering once it is there or refused: helix-raylib's own, in place of raylib's
		`SetClipboardText`. A page writes it only while it has the keyboard, soon after a press.

		@param text  The text.
		@param done  Optional. Called once the text is on the clipboard, at a later poll.
		@param failed  Optional. Receives why it isn't; when omitted, it is logged. */
	static function SetClipboardTextAsync(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		var clipboard = Runtime.clipboard();
		ask("SetClipboardTextAsync", (granted, refused) -> {
			clipboard.setText(text, granted, refused);
			return true;
		}, "", done, failed);
	}

	/** Reads the clipboard's text, answering at a later poll: helix-raylib's own, in place of raylib's `GetClipboardText`, as a page's
		clipboard answers later. A page reads it only with the player's permission, which the browser may ask for.

		@param read  Receives the text; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardTextAsync(read:String->Void, ?failed:String->Void):Void {
		Runtime.clipboard().requestText(read, error -> refuse("GetClipboardTextAsync", error, failed));
	}

	/** Reads the clipboard's image, answering at a later poll once it is decoded: helix-raylib's own, in place of raylib's
		`GetClipboardImage`. A page reads it only with the player's permission.

		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void):Void {
		Runtime.imaging();
		Runtime.clipboard()
			.requestImage(png -> decoded("GetClipboardImageAsync", ".png", png, loaded, failed), error -> refuse("GetClipboardImageAsync", error, failed));
	}

	/** Takes a screenshot of the next frame and hands it to the user as a file, as `ExportImageAsync` writes it by the name's extension
		(".png", ".qoi" or ".raw"), answering once it is saved or refused: helix-raylib's own, in place of raylib's `TakeScreenshot`. In a
		page it is downloaded under the name's file name, as raylib's web build does; natively it is written where the name says, as
		raylib 6.2 writes it: a relative name under the working directory, its directories kept, and an absolute one where it is. A
		directory that isn't there isn't made, and the screenshot isn't saved. raylib's is taken from the frame drawn last, before it is
		shown; this one is taken as the next frame ends, when its pixels can be read back. Its alpha is opaque, as raylib's is.

		@param fileName  The file's name, or its path; a name with `'` is refused, as raylib's is.
		@param done  Optional. Called once the file is written or downloaded, at a later poll.
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
