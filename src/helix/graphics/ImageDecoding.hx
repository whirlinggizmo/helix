package helix.graphics;

import haxe.io.Bytes;
import helix.assets.IRequest;
import helix.core.Jobs;

/** How a decode ended: the image as 8-bit RGBA, rows top to bottom, not premultiplied; or why not; or cancellation. */
enum ImageDecodeResult {
	Decoded(width:Int, height:Int, rgba:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Image decoding over a platform's IImageDecoder, the same on every platform: at most two at once, each completing exactly once on the host
	thread, cancelled ones and those still queued at shutdown completing Cancelled. A browser decodes with the page's own decoder (through a
	canvas, which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's exact value), native
	with stb_image, exactly. Textures and environments decode through it. */
class ImageDecoding {
	var decoder:IImageDecoder;
	var jobs = new Jobs(2);

	/** Decodes with decoder. */
	public function new(decoder:IImageDecoder)
		this.decoder = decoder;

	/** Decodes encoded; complete runs exactly once on the host thread at a later poll. Failed for no bytes, a closed service, or bytes the
		decoder can't read. */
	public function decode(encoded:Bytes, complete:ImageDecodeResult->Void):IRequest
		return jobs.add(job -> {
			if (encoded.length == 0)
				job.finish(Failed("No image bytes"));
			else
				decoder.decode(encoded, job.finish);
		}, complete, Cancelled, Failed("The image decoder is shut down"));

	/** Delivers finished decodes, starts queued ones and runs completions. Call once per frame. */
	public function poll():Void {
		decoder.poll();
		jobs.poll();
	}

	/** Cancels every pending decode (each completes Cancelled) and refuses later ones. */
	public function shutdown():Void
		jobs.shutdown();
}
