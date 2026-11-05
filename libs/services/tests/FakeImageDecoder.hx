import haxe.io.Bytes;
import helix.platform.IImageDecoder;

/** Decodes "W x H" text as a W by H image of that many pixels, all its bytes 7, and anything else as a failure, at its next poll. */
class FakeImageDecoder implements IImageDecoder {
	final pending:Array<Void->Void> = [];

	/** Creates the decoder. */
	public function new() {}

	/** Answers at the next poll. */
	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var size = ~/^(\d+)x(\d+)$/;
		var text = encoded.toString();
		pending.push(() -> if (size.match(text)) {
			var w = Std.parseInt(size.matched(1)),
				h = Std.parseInt(size.matched(2));
			var pixels = Bytes.alloc(w * h * 4);
			pixels.fill(0, pixels.length, 7);
			decoded(pixels, w, h);
		} else failed("not an image"));
	}

	/** Delivers what was decoded. */
	public function decodeForGpu(encoded:Bytes, decoded:helix.platform.IDecodedImage->Void, failed:String->Void):Void
		decode(encoded, (pixels, width, height) -> decoded(new helix.platform.adapters.shared.PixelsImage(width, height, pixels)), failed);

	public function poll():Void {
		var now = pending.copy();
		pending.resize(0);
		for (f in now)
			f();
	}

	/** Does nothing. */
	public function dispose():Void {}
}
