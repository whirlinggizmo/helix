package helix.platform.adapters.imagedecoder.stb;

import haxe.io.Bytes;
import helix.platform.IDecodedImage;
import helix.platform.IImageDecoder;
import helix.platform.adapters.imagedecoder.stb.internal.ImageBridge;
import helix.platform.adapters.shared.Mailbox;
import helix.platform.adapters.shared.PixelsImage;
import sys.thread.Thread;

/** Provides `IImageDecoder` natively over stb_image, each decode on a worker thread. */
class StbImageDecoderAdapter implements IImageDecoder {
	var mailbox = new Mailbox();
	var closed = false;

	/** Creates the decoder. */
	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void
		Thread.create(() -> {
			var image = ImageBridge.decode(cast cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
			if (image == null) {
				var message:String = ImageBridge.error();
				mailbox.post(() -> failed("Image decode failed: " + message));
				return;
			}
			var width = ImageBridge.width(cast image),
				height = ImageBridge.height(cast image);
			var pixels = Bytes.alloc(width * height * 4);
			ImageBridge.copy(cast image, cast cpp.Pointer.arrayElem(pixels.getData(), 0).raw);
			ImageBridge.free(image);
			mailbox.post(() -> decoded(pixels, width, height));
		});

	public function decodeForGpu(encoded:Bytes, decoded:IDecodedImage->Void, failed:String->Void):Void
		decode(encoded, (pixels, width, height) -> decoded(new PixelsImage(width, height, pixels)), failed);

	public function poll():Void
		if (!closed)
			mailbox.deliver();

	/** Closes the decoder: a decode still running on its worker finishes, and its answer is dropped. */
	public function dispose():Void
		closed = true;
}
