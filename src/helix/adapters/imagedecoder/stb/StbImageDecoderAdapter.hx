package helix.adapters.imagedecoder.stb;

import haxe.io.Bytes;
import helix.adapters.imagedecoder.stb.internal.ImageBridge;
import helix.adapters.shared.Mailbox;
import helix.graphics.IImageDecoder;
import helix.graphics.ImageDecoding.ImageDecodeResult;
import sys.thread.Thread;

/** IImageDecoder natively over stb_image, each decode on a worker thread. */
class StbImageDecoderAdapter implements IImageDecoder {
	var mailbox = new Mailbox();

	/** A decoder with no work. */
	public function new() {}

	public function decode(encoded:Bytes, done:ImageDecodeResult->Void):Void
		Thread.create(() -> {
			var result = decodeNow(encoded);
			mailbox.post(() -> done(result));
		});

	static function decodeNow(encoded:Bytes):ImageDecodeResult {
		var image = ImageBridge.decode(cast cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
		if (image == null)
			return Failed("Image decode failed: " + (ImageBridge.error() : String));
		var width = ImageBridge.width(cast image),
			height = ImageBridge.height(cast image);
		var rgba = Bytes.alloc(width * height * 4);
		ImageBridge.copy(cast image, cast cpp.Pointer.arrayElem(rgba.getData(), 0).raw);
		ImageBridge.free(image);
		return Decoded(width, height, rgba);
	}

	public function poll():Void
		mailbox.deliver();
}
