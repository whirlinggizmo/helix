package helix.adapters.imagedecoder.canvas;

import haxe.io.Bytes;
import helix.graphics.IImageDecoder;
import helix.graphics.ImageDecoding.ImageDecodeResult;

/** IImageDecoder in a browser: the page's own decoder (createImageBitmap, without colour conversion or premultiplying), read back as RGBA
	through an OffscreenCanvas, which stores pixels premultiplied: a partly transparent pixel may come back a level or two from the file. */
class CanvasImagesAdapter implements IImageDecoder {
	/** The page's decoder. */
	public function new() {}

	public function decode(encoded:Bytes, done:ImageDecodeResult->Void):Void {
		var blob = new js.html.Blob([encoded.getData()]);
		var options:Dynamic = {premultiplyAlpha: "none", colorSpaceConversion: "none"};
		js.Syntax.code("createImageBitmap({0}, {1})", blob, options).then((bitmap:Dynamic) -> {
			var width:Int = bitmap.width, height:Int = bitmap.height;
			var canvas:Dynamic = js.Syntax.code("new OffscreenCanvas({0}, {1})", width, height);
			var context:Dynamic = canvas.getContext("2d", {willReadFrequently: true});
			context.drawImage(bitmap, 0, 0);
			bitmap.close();
			var pixels:js.lib.Uint8ClampedArray = context.getImageData(0, 0, width, height).data;
			done(Decoded(width, height, Bytes.ofData(pixels.buffer)));
		}, (error:Dynamic) -> done(Failed("Image decode failed: " + Std.string(error))));
	}

	/** Nothing to deliver: the page's promises already resolve on the host thread. */
	public function poll():Void {}
}
