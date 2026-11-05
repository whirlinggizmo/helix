package helix.platform;

import haxe.io.Bytes;

/** Defines image decoding from a file into 8-bit RGBA pixels.

	It reads PNG, JPEG, BMP, TGA and GIF files, and a GIF's first frame only. The pixels are not premultiplied, and rows run top to
	bottom. */
interface IImageDecoder extends IPollable {
	/** Decodes a file, off the main thread where the platform can.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param decoded  Receives the pixels, `width * height * 4` bytes, and the image's width and height.
		@param failed  Receives why the file can't be read. */
	function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void;

	/** Decodes a file for the GPU, off the main thread where the platform can: in a page the browser's own decoded image, with no
		readback, which `IGraphics.createTextureFromImage` uploads as it is; natively the pixels.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param decoded  Receives the image. The receiver disposes it once it is uploaded, or when it isn't wanted.
		@param failed  Receives why the file can't be read. */
	function decodeForGpu(encoded:Bytes, decoded:IDecodedImage->Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the decoder. A decode still running finishes without calling back. */
	function dispose():Void;
}
