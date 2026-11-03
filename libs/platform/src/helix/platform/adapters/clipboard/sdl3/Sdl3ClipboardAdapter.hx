package helix.platform.adapters.clipboard.sdl3;

import haxe.io.Bytes;
import helix.platform.IClipboard;
import helix.platform.adapters.shared.PollAnswers;
import helix.platform.adapters.clipboard.sdl3.internal.ClipboardBridge;

/** Provides `IClipboard` on SDL3, natively: the system's clipboard, its text and an image as `image/png`. SDL reads and writes during
	the call, and the answer comes at the next `Sdl3EventsAdapter` poll. It is made after the window, as SDL's clipboard needs its video. */
class Sdl3ClipboardAdapter implements IClipboard {
	/** Uses SDL's clipboard. */
	public function new() {}

	public function requestText(read:String->Void, ?failed:String->Void):Bool {
		var text = ClipboardBridge.text().toString();
		later(() -> read(text));
		return true;
	}

	public function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void
		answer(ClipboardBridge.setText(text) != 0, done, failed, "SDL couldn't put the text on the clipboard");

	public function requestImage(read:Bytes->Void, ?failed:String->Void):Bool {
		var size = ClipboardBridge.imageSize();
		if (size <= 0) {
			answer(false, null, failed, "The clipboard holds no image");
			return true;
		}
		var png = Bytes.alloc(size);
		ClipboardBridge.imageCopy(cast cpp.Pointer.arrayElem(png.getData(), 0).raw);
		later(() -> read(png));
		return true;
	}

	public function setImage(png:Bytes, ?done:Void->Void, ?failed:String->Void):Void
		answer(png.length > 0 && ClipboardBridge.setImage(cast cpp.Pointer.arrayElem(png.getData(), 0).raw, png.length) != 0, done, failed,
			"SDL couldn't put the image on the clipboard");

	public function dispose():Void
		ClipboardBridge.dispose();

	// Calls f at the next poll, never during the call.
	static function later(f:Void->Void):Void
		PollAnswers.add(() -> {
			f();
			return true;
		});

	// Answers at the next poll: done where it was done, else failed with why.
	static function answer(succeeded:Bool, done:Null<Void->Void>, failed:Null<String->Void>, why:String):Void
		later(() -> if (succeeded) {
			if (done != null)
				done();
		} else if (failed != null) failed(why));
}
