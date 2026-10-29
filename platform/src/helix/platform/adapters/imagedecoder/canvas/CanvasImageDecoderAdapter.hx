package helix.platform.adapters.imagedecoder.canvas;

import haxe.io.Bytes;
import helix.platform.IImageDecoder;

/** Provides `IImageDecoder` in a page over its own decoder (`createImageBitmap`, with no color conversion or premultiplying), read back
	through an `OffscreenCanvas`.

	The canvas stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's value. */
class CanvasImageDecoderAdapter implements IImageDecoder {
	var closed = false;

	/** Creates the decoder. */
	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var blob = new js.html.Blob([encoded.getData()]);
		var options:Dynamic = {premultiplyAlpha: "none", colorSpaceConversion: "none"};
		js.Syntax.code("createImageBitmap({0}, {1})", blob, options).then((bitmap:Dynamic) -> {
			var width:Int = bitmap.width, height:Int = bitmap.height;
			var canvas:Dynamic = js.Syntax.code("new OffscreenCanvas({0}, {1})", width, height);
			var context:Dynamic = canvas.getContext("2d", {willReadFrequently: true});
			context.drawImage(bitmap, 0, 0);
			bitmap.close();
			var pixels:js.lib.Uint8ClampedArray = context.getImageData(0, 0, width, height).data;
			if (!closed)
				decoded(Bytes.ofData(pixels.buffer), width, height);
		},
			(error:Dynamic) -> if (!closed) failed("Image decode failed: " + Std.string(error)));
	}

	/** Does nothing: the page's promises already resolve on the main thread. */
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}
