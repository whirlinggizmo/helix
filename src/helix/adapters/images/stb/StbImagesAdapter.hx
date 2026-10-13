package helix.adapters.images.stb;

import haxe.io.Bytes;
import helix.adapters.images.stb.internal.ImageBridge;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IImages;
import sys.thread.Deque;
import sys.thread.Thread;

/** Native IImages (adapter level) over stb_image, decoding on worker threads, two at once. */
class StbImagesAdapter implements IImages {
	var done = new Deque<Void->Void>();
	var waiting:Array<Void->Void> = [];
	var running = 0;
	var live = true;

	/** A decoder with no work. */
	public function new() {}

	public function decode(encoded:Bytes, complete:ImageDecodeResult->Void):IRequest {
		var request:Request = null;
		request = new Request(() -> done.add(() -> complete(Cancelled)));
		if (!live || encoded.length == 0) {
			request.finish();
			done.add(() -> complete(Failed(live ? "No image bytes" : "The image decoder is shut down")));
			return request;
		}
		waiting.push(() -> {
			if (request.isSettled())
				return;
			running++;
			Thread.create(() -> {
				var result = decodeNow(encoded);
				done.add(() -> {
					running--;
					if (request.finish())
						complete(result);
				});
			});
		});
		start();
		return request;
	}

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

	function start():Void
		while (running < 2 && waiting.length > 0)
			waiting.shift()();

	public function poll():Void {
		var next:Null<Void->Void>;
		while ((next = done.pop(false)) != null)
			next();
		start();
	}

	public function shutdown():Void {
		live = false;
		waiting = [];
	}
}
