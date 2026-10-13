package helix.adapters.images.canvas;

import haxe.io.Bytes;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IImages;
import js.Browser;

/** Browser IImages (adapter level): the page's own decoder (createImageBitmap, without colour conversion or premultiplying), read back as RGBA
	through an OffscreenCanvas. The canvas stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file. */
class CanvasImagesAdapter implements IImages {
	var done:Array<Void->Void> = [];
	var live = true;

	/** A decoder with no work. */
	public function new() {}

	public function decode(encoded:Bytes, complete:ImageDecodeResult->Void):IRequest {
		var request:Request = null;
		request = new Request(() -> done.push(() -> complete(Cancelled)));
		function finish(result:ImageDecodeResult)
			done.push(() -> if (request.finish()) complete(result));
		if (!live || encoded.length == 0) {
			finish(Failed(live ? "No image bytes" : "The image decoder is shut down"));
			return request;
		}
		var blob = new js.html.Blob([encoded.getData()]);
		var options:Dynamic = {premultiplyAlpha: "none", colorSpaceConversion: "none"};
		js.Syntax.code("createImageBitmap({0}, {1})", blob, options).then((bitmap:Dynamic) -> {
			var width:Int = bitmap.width, height:Int = bitmap.height;
			var canvas:Dynamic = js.Syntax.code("new OffscreenCanvas({0}, {1})", width, height);
			var context:Dynamic = canvas.getContext("2d", {willReadFrequently: true});
			context.drawImage(bitmap, 0, 0);
			bitmap.close();
			var pixels:js.lib.Uint8ClampedArray = context.getImageData(0, 0, width, height).data;
			finish(Decoded(width, height, Bytes.ofData(pixels.buffer)));
		}, (error:Dynamic) -> finish(Failed("Image decode failed: " + Std.string(error))));
		return request;
	}

	public function poll():Void {
		var ready = done;
		done = [];
		for (next in ready)
			next();
	}

	public function shutdown():Void
		live = false;
}
