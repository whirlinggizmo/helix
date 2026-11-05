package helix.platform;

import haxe.io.Bytes;

/** Represents an image decoded for the GPU: what `IImageDecoder.decodeForGpu` gives and `IGraphics.createTextureFromImage` uploads, so a
	program draws a file without ever holding its pixels.

	In a page it is the browser's decoded image (`bitmapHandle` names it), uploaded as it is. Natively it is the pixels. Either can
	give its pixels (`pixels`) when a program wants them after all, at the cost a page's readback has. */
interface IDecodedImage {
	/** Gets its width, in pixels. */
	var width(get, never):Int;

	/** Gets its height, in pixels. */
	var height(get, never):Int;

	/** Gets the handle of the browser's decoded image in a page (an `ImageBitmap`, which `IGraphics.createTextureFromImage` uploads as
		it is), or 0 natively, where `pixels` holds the image, and once disposed. */
	var bitmapHandle(get, never):Int;

	/** Returns its pixels, 8-bit RGBA with rows top to bottom, not premultiplied, `width * height * 4` bytes, made once and kept.

		In a page they are read back from the bitmap through a canvas, which stores pixels premultiplied, so a partly transparent pixel
		may come back a level or two from the file's value.
		@return  The pixels. */
	function pixels():Bytes;

	/** Frees it: the bitmap closed, the pixels let go. It isn't uploaded or read after this. */
	function dispose():Void;
}
