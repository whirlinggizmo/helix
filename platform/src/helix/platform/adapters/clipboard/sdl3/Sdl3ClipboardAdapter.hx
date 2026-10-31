package helix.platform.adapters.clipboard.sdl3;

import haxe.io.Bytes;
import helix.platform.IClipboard;
import helix.platform.adapters.clipboard.sdl3.internal.ClipboardBridge;

/** Provides `IClipboard` on SDL3, natively: the system's clipboard, its text and an image as `image/png`. SDL answers at once, so each
	call's lambda is called during it. It is made after the window, as SDL's clipboard needs its video. */
class Sdl3ClipboardAdapter implements IClipboard {
	/** Uses SDL's clipboard. */
	public function new() {}

	public function requestText(read:String->Void, ?failed:String->Void):Bool {
		read(ClipboardBridge.text().toString());
		return true;
	}

	public function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		if (ClipboardBridge.setText(text) != 0) {
			if (done != null)
				done();
		} else if (failed != null)
			failed("SDL couldn't put the text on the clipboard");
	}

	public function requestImage(read:Bytes->Void, ?failed:String->Void):Bool {
		var size = ClipboardBridge.imageSize();
		if (size <= 0) {
			if (failed != null)
				failed("The clipboard holds no image");
			return true;
		}
		var png = Bytes.alloc(size);
		ClipboardBridge.imageCopy(cast cpp.Pointer.arrayElem(png.getData(), 0).raw);
		read(png);
		return true;
	}

	public function setImage(png:Bytes, ?done:Void->Void, ?failed:String->Void):Void {
		if (png.length > 0 && ClipboardBridge.setImage(cast cpp.Pointer.arrayElem(png.getData(), 0).raw, png.length) != 0) {
			if (done != null)
				done();
		} else if (failed != null)
			failed("SDL couldn't put the image on the clipboard");
	}

	public function dispose():Void
		ClipboardBridge.dispose();
}
