package helix.graphics;

import haxe.io.Bytes;
import helix.assets.IRequest;

/** How a decode ended: the image as 8-bit RGBA, rows top to bottom, not premultiplied; or why not. */
enum ImageDecodeResult {
	Decoded(width:Int, height:Int, rgba:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Image decoding, adapter level: PNG, JPEG, BMP, TGA and GIF (its first frame) bytes to RGBA. The browser decodes with the page's own decoder
	through a canvas, which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's exact value;
	native decodes with stb_image, exactly. Textures loads and owns textures above it. */
interface IImages {
	/** Decodes encoded off the frame where the platform can; complete runs once, on the host thread, at a later poll(). */
	function decode(encoded:Bytes, complete:ImageDecodeResult->Void):IRequest;

	/** Delivers finished decodes; the host calls it once a frame. */
	function poll():Void;

	/** Cancels what's still decoding; decode refuses (Failed) after. */
	function shutdown():Void;
}
