package helix.platform.adapters.clipboard.dom;

import haxe.io.Bytes;
import helix.platform.IClipboard;
import helix.platform.adapters.shared.PollAnswers;

/** Provides `IClipboard` in a browser page, over the Clipboard API (`navigator.clipboard`): text, and an image as `image/png`.

	The browser may ask the player before a read, and lets the page write only while it has the keyboard, soon after a press. A page
	served without HTTPS (other than from localhost) has no clipboard, so every call fails, at the next `DomEventsAdapter` poll.
	Chromium re-encodes an image it puts on the clipboard, so one read back is the same picture in another PNG. */
class DomClipboardAdapter implements IClipboard {
	/** Uses the page's clipboard. */
	public function new() {}

	public function requestText(read:String->Void, ?failed:String->Void):Bool {
		var clipboard = api();
		if (clipboard == null) {
			refuse(failed, null);
			return true;
		}
		clipboard.readText().then((text:String) -> read(text != null ? text : ""), (error:Dynamic) -> refuse(failed, error));
		return true;
	}

	public function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		var clipboard = api();
		if (clipboard == null) {
			refuse(failed, null);
			return;
		}
		clipboard.writeText(text).then(_ -> if (done != null) done(), (error:Dynamic) -> refuse(failed, error));
	}

	public function requestImage(read:Bytes->Void, ?failed:String->Void):Bool {
		var clipboard = api();
		if (clipboard == null || clipboard.read == null) {
			refuse(failed, null);
			return true;
		}
		clipboard.read().then((items:Array<Dynamic>) -> {
			for (item in items)
				if ((item.types : Array<String>).indexOf("image/png") >= 0) {
					item.getType("image/png")
						.then((blob:Dynamic) -> blob.arrayBuffer())
						.then((buffer:js.lib.ArrayBuffer) -> read(Bytes.ofData(buffer)), (error:Dynamic) -> refuse(failed, error));
					return;
				}
			if (failed != null)
				failed("The clipboard holds no image");
		}, (error:Dynamic) -> refuse(failed, error));
		return true;
	}

	public function setImage(png:Bytes, ?done:Void->Void, ?failed:String->Void):Void {
		var clipboard = api();
		var Item:Dynamic = js.Syntax.code("globalThis.ClipboardItem");
		if (clipboard == null || clipboard.write == null || Item == null) {
			refuse(failed, null);
			return;
		}
		var blob = new js.html.Blob([new js.lib.Uint8Array(png.getData(), 0, png.length)], {type: "image/png"});
		var item:Dynamic = js.Syntax.construct(Item, {"image/png": blob});
		clipboard.write([item]).then(_ -> if (done != null) done(), (error:Dynamic) -> refuse(failed, error));
	}

	public function dispose():Void {}

	// The page's clipboard, or null where it has none (a page not served securely).
	static function api():Null<Dynamic> {
		var navigator:Dynamic = js.Browser.navigator;
		return navigator.clipboard;
	}

	// Fails with the browser's error; with none, the page has no clipboard, which is known during the call and answered at the next poll.
	static function refuse(failed:Null<String->Void>, error:Dynamic):Void {
		if (failed == null)
			return;
		if (error == null)
			PollAnswers.add(() -> {
				failed("The page has no clipboard");
				return true;
			});
		else
			failed(error.message != null ? Std.string(error.message) : Std.string(error));
	}
}
