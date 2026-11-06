package helix.platform.adapters.window.dom;

import haxe.io.Bytes;
import helix.platform.IWindow;
import helix.platform.Orientation;
import helix.platform.adapters.shared.dom.DomActivation;
import helix.platform.adapters.shared.PollAnswers;
import helix.platform.adapters.shared.dom.DomPage;
import js.Browser;
import js.html.CanvasElement;

/** Provides `IWindow` in a browser page: the page is the window.

	Its title is the document's, its size the viewport's, and fullscreen and visibility are the canvas's, whose drawing size follows the
	viewport and the pixel ratio. A page can't move, size, maximize or minimize its window, choose a monitor, or close; it sees one screen.
	Those requests fail at the next `DomEventsAdapter` poll, saying so, and what a page can do answers there too; fullscreen and the
	orientation answer as the browser does. A dropped file is the File the canvas's drop gave, read later. */
class DomWindowAdapter implements IWindow {
	var canvas:CanvasElement;
	var closed = false;

	/** Creates the page's window over the canvas the program draws in, sizing its drawing buffer to the viewport.

		@param options  The canvas's id.
		@throws String  No canvas has that id. */
	public function new(options:DomWindowAdapterOptions) {
		canvas = DomPage.canvas(options.canvasId);
		DomPage.fit(canvas);
		Browser.window.addEventListener("pagehide", _ -> {
			if (closed)
				return;
			closed = true;
			if (onClose != null)
				onClose();
		});
	}

	public var framebufferWidth(get, never):Int;

	function get_framebufferWidth():Int
		return canvas.width;

	public var framebufferHeight(get, never):Int;

	function get_framebufferHeight():Int
		return canvas.height;

	public var pixelRatio(get, never):Float;

	function get_pixelRatio():Float
		return Browser.window.devicePixelRatio;

	public var focused(get, never):Bool;

	function get_focused():Bool
		return DomPage.focused;

	public var title(get, set):String;

	function get_title():String
		return Browser.document.title;

	function set_title(title:String):String {
		Browser.document.title = title;
		return title;
	}

	public var width(get, never):Int;

	function get_width():Int
		return Math.round(DomPage.logicalWidth(canvas));

	public var height(get, never):Int;

	function get_height():Int
		return Math.round(DomPage.logicalHeight(canvas));

	// An element out of sight whose padding is the page's safe-area insets, made at the first read: a script reads env() only through
	// a style.
	var insets:Null<js.html.DivElement> = null;

	// The safe-area inset on a side, in CSS pixels, rounded out.
	function inset(side:String):Int {
		if (insets == null) {
			insets = Browser.document.createDivElement();
			insets.style.cssText = "position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;pointer-events:none;"
				+ "padding:env(safe-area-inset-top,0px) env(safe-area-inset-right,0px) env(safe-area-inset-bottom,0px) env(safe-area-inset-left,0px)";
			Browser.document.body.appendChild(insets);
		}
		var value = Std.parseFloat(Browser.window.getComputedStyle(insets).getPropertyValue('padding-$side'));
		return Math.isNaN(value) || value <= 0 ? 0 : Math.ceil(value);
	}

	public var safeAreaX(get, never):Int;

	function get_safeAreaX():Int
		return Std.int(Math.min(inset("left"), width));

	public var safeAreaY(get, never):Int;

	function get_safeAreaY():Int
		return Std.int(Math.min(inset("top"), height));

	public var safeAreaWidth(get, never):Int;

	function get_safeAreaWidth():Int
		return Std.int(Math.max(0, width - safeAreaX - inset("right")));

	public var safeAreaHeight(get, never):Int;

	function get_safeAreaHeight():Int
		return Std.int(Math.max(0, height - safeAreaY - inset("bottom")));

	// Answers at the next events' poll: done when reached says the request is done by then, else failed with the reason.
	function answer(reached:Void->Bool, reason:String, done:Null<Void->Void>, failed:Null<String->Void>):Bool {
		PollAnswers.add(() -> {
			if (reached()) {
				if (done != null)
					done();
			} else if (failed != null)
				failed(reason);
			return true;
		});
		return true;
	}

	public function requestSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 1 || height < 1)
			return false;
		return answer(() -> false, "a page's canvas follows the page's size", done, failed);
	}

	public function canMove():Bool
		return false;

	public var x(get, never):Int;

	function get_x():Int
		return Browser.window.screenX;

	public var y(get, never):Int;

	function get_y():Int
		return Browser.window.screenY;

	public function requestPosition(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Bool
		return answer(() -> false, "a page can't move its window", done, failed);

	public var orientation(get, never):Orientation;

	// The lock last granted; a browser releases it as the page leaves fullscreen.
	var locked:Orientation = Any;

	function get_orientation():Orientation
		return Browser.document.fullscreenElement == null ? Any : locked;

	public function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool {
		var lock:Dynamic = js.Syntax.code("(screen.orientation && screen.orientation.lock) ? screen.orientation : null");
		if (lock == null)
			return false;
		var refused = (error:Dynamic) -> {
			var reason = error != null && error.message != null ? Std.string(error.message) : Std.string(error);
			if (failed != null)
				failed(reason);
			return null;
		};
		if (orientation == Any) {
			try
				lock.unlock()
			catch (_:Dynamic) {}
			locked = Any;
			if (done != null)
				done();
			return true;
		}
		var asked:Dynamic = try lock.lock(orientation == Landscape ? "landscape" : "portrait") catch (e:Dynamic) {
			refused(e);
			return true;
		};
		asked.then(_ -> {
			locked = orientation;
			if (done != null)
				done();
			return null;
		}, refused);
		return true;
	}

	public function canFullscreen():Bool
		return Browser.document.fullscreenEnabled;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return Browser.document.fullscreenElement != null;

	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		if (!canFullscreen())
			return false;
		// The browser may refuse (no recent key press or click): the page stays as it was, and failed says why.
		var refused = (error:Dynamic) -> {
			var reason = error != null && error.message != null ? Std.string(error.message) : Std.string(error);
			if (failed != null)
				failed(reason);
			return null;
		};
		var granted = (_:Dynamic) -> {
			if (done != null)
				done();
			return null;
		};
		var ask = () -> {
			// The browser's promise of the change, granted or refused.
			var asked:Dynamic = enabled
				&& !this.fullscreen ? canvas.requestFullscreen() : !enabled && this.fullscreen ? Browser.document.exitFullscreen() : null;
			if (asked != null)
				asked.then(granted, refused);
			else
				granted(null);
		};
		// Going fullscreen wants a fresh press; leaving it doesn't.
		if (enabled)
			DomActivation.ask(ask);
		else
			ask();
		return true;
	}

	public var maximized(get, never):Bool;

	function get_maximized():Bool
		return false;

	public function requestMaximized(maximized:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return answer(() -> !maximized, "a page can't maximize its window", done, failed);

	public var minimized(get, never):Bool;

	function get_minimized():Bool
		return false;

	public function requestMinimized(minimized:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return answer(() -> !minimized, "a page can't minimize its window", done, failed);

	public function requestFocus(?done:Void->Void, ?failed:String->Void):Bool {
		Browser.window.focus();
		canvas.focus();
		return answer(() -> Browser.document.hasFocus(), "the browser keeps the keyboard in another window", done, failed);
	}

	// The page's icon: a link the adapter adds, its picture drawn on a canvas of the icon's size.
	var iconLink:Null<js.html.LinkElement> = null;

	public function setIcon(width:Int, height:Int, pixels:Bytes):Void {
		if (width <= 0 || height <= 0 || pixels.length < width * height * 4)
			throw "The icon's size isn't positive or its pixels are fewer than it needs";
		var picture = Browser.document.createCanvasElement();
		picture.width = width;
		picture.height = height;
		var context = picture.getContext2d();
		var data = context.createImageData(width, height);
		data.data.set(new js.lib.Uint8ClampedArray(pixels.getData(), 0, width * height * 4));
		context.putImageData(data, 0, 0);
		// The page's own icons give way to it, as the page's newest icon is the one shown.
		if (iconLink == null) {
			iconLink = Browser.document.createLinkElement();
			iconLink.rel = "icon";
			Browser.document.head.appendChild(iconLink);
		}
		iconLink.href = picture.toDataURL("image/png");
	}

	public var opacity(get, never):Float;

	function get_opacity():Float
		return canvas.style.opacity == "" ? 1 : Std.parseFloat(canvas.style.opacity);

	public function requestOpacity(opacity:Float, ?done:Void->Void, ?failed:String->Void):Bool {
		canvas.style.opacity = Std.string(opacity < 0 ? 0 : opacity > 1 ? 1 : opacity);
		return answer(() -> true, "", done, failed);
	}

	public function requestMinimumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return answer(() -> false, "a page's canvas follows the page's size", done, failed);
	}

	public function requestMaximumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return answer(() -> false, "a page's canvas follows the page's size", done, failed);
	}

	public function getMonitorRefreshRate(monitorIndex:Int):Float
		return 0;

	public var visible(get, never):Bool;

	function get_visible():Bool
		return canvas.style.visibility != "hidden";

	public function requestVisible(visible:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		canvas.style.visibility = visible ? "" : "hidden";
		return answer(() -> true, "", done, failed);
	}

	public var monitorCount(get, never):Int;

	function get_monitorCount():Int
		return 1;

	public var monitorIndex(get, never):Int;

	function get_monitorIndex():Int
		return 0;

	public function requestMonitorIndex(monitorIndex:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (monitorIndex != 0)
			return false;
		return answer(() -> true, "", done, failed);
	}

	public function getMonitorName(monitorIndex:Int):String
		return monitorIndex == 0 ? "screen" : "";

	public function getMonitorX(monitorIndex:Int):Int
		return 0;

	public function getMonitorY(monitorIndex:Int):Int
		return 0;

	public function getMonitorWidth(monitorIndex:Int):Int
		return monitorIndex == 0 ? Browser.window.screen.width : 0;

	public function getMonitorHeight(monitorIndex:Int):Int
		return monitorIndex == 0 ? Browser.window.screen.height : 0;

	public function readDroppedFile(fileIndex:Int, maxBytes:Int, read:(name:String, bytes:Bytes) -> Void, failed:String->Void):Void {
		var file = DomPage.dropped[fileIndex];
		if (fileIndex < 0 || file == null || file.size > maxBytes) {
			var reason = file == null || fileIndex < 0 ? 'No dropped file $fileIndex' : "File exceeds byte limit";
			PollAnswers.add(() -> {
				failed(reason);
				return true;
			});
			return;
		}
		(cast file : Dynamic).arrayBuffer().then(data -> {
			read(file.name, Bytes.ofData(data));
			return null;
		}, error -> {
			failed(Std.string(error));
			return null;
		});
	}

	public function canClose():Bool
		return false;

	public function close():Void {}

	public var onClose:Null<Void->Void>;
}
