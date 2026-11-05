package helix.platform.adapters.imagedecoder.canvas;

import haxe.io.Bytes;
import helix.platform.IDecodedImage;
import helix.platform.adapters.shared.dom.DomImages;
import js.html.ImageBitmap;
import helix.platform.IImageDecoder;

/** Provides `IImageDecoder` in a page over its own decoder (`createImageBitmap`, with no color conversion or premultiplying).

	`decodeForGpu` gives the bitmap itself, which the graphics adapter uploads as it is. `decode` reads it back through an
	`OffscreenCanvas`, which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's
	value. */
class CanvasImageDecoderAdapter implements IImageDecoder {
	var closed = false;

	/** Creates the decoder. */
	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void
		decodeForGpu(encoded, image -> {
			var pixels = image.pixels();
			image.dispose();
			decoded(pixels, image.width, image.height);
		}, failed);

	public function decodeForGpu(encoded:Bytes, decoded:IDecodedImage->Void, failed:String->Void):Void {
		var blob = new js.html.Blob([encoded.getData()]);
		var options:Dynamic = {premultiplyAlpha: "none", colorSpaceConversion: "none"};
		js.Syntax.code("createImageBitmap({0}, {1})", blob, options).then((bitmap:ImageBitmap) -> {
			if (closed)
				bitmap.close();
			else
				decoded(new BitmapImage(bitmap));
		},
			(error:Dynamic) -> if (!closed) failed("Image decode failed: " + Std.string(error)));
	}

	/** Does nothing: the page's promises already resolve on the main thread. */
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}

/** The browser's decoded image, registered with the page's images (`DomImages`) for the graphics adapter, its pixels read back through a
	canvas when asked for. */
private class BitmapImage implements IDecodedImage {
	public var width(get, never):Int;

	final w:Int;

	function get_width():Int
		return w;

	public var height(get, never):Int;

	final h:Int;

	function get_height():Int
		return h;

	public var bitmapHandle(get, never):Int;

	var id:Int;

	function get_bitmapHandle():Int
		return id;

	var image:Null<ImageBitmap>;
	var rgba:Null<Bytes> = null;

	/** Wraps the browser's decoded image, registering it. */
	public function new(bitmap:ImageBitmap) {
		image = bitmap;
		w = bitmap.width;
		h = bitmap.height;
		id = DomImages.register(bitmap);
	}

	public function pixels():Bytes {
		if (rgba != null)
			return rgba;
		if (image == null)
			throw "The image was disposed";
		var canvas:Dynamic = js.Syntax.code("new OffscreenCanvas({0}, {1})", w, h);
		var context:Dynamic = canvas.getContext("2d", {willReadFrequently: true});
		context.drawImage(image, 0, 0);
		var data:js.lib.Uint8ClampedArray = context.getImageData(0, 0, w, h).data;
		return rgba = Bytes.ofData(data.buffer);
	}

	public function dispose():Void {
		if (image != null) {
			DomImages.forget(id);
			image.close();
		}
		id = 0;
		image = null;
		rgba = null;
	}
}
