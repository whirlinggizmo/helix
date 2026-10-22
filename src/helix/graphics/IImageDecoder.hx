package helix.graphics;

import haxe.io.Bytes;
import helix.graphics.ImageDecoding.ImageDecodeResult;

/** Image decoding on a platform: PNG, JPEG, BMP, TGA and GIF (its first frame) to 8-bit RGBA, rows top to bottom, not premultiplied. Queuing,
	cancellation and shutdown are the shared ImageDecoding's. */
@:noCompletion
interface IImageDecoder {
	/** Decodes encoded off the frame where the platform can; done runs once on the host thread, never during this call: Decoded or Failed. */
	public function decode(encoded:Bytes, done:ImageDecodeResult->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll; the shared ImageDecoding calls it once a frame. */
	public function poll():Void;
}
