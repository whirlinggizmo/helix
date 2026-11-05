package helix.services.images;

import haxe.io.Bytes;
import helix.platform.IDecodedImage;
import helix.platform.IImageDecoder;
import helix.platform.IPollable;
import helix.services.assets.Assets;

/** Provides images by path: each file found through the assets, decoded off the main thread where the platform can, into pixels.

	Images draws nothing and holds nothing on the GPU: what a program draws with is its own (`IGraphics.createTexture` takes an image's
	pixels as they are). The program polls it once a frame, as it does the decoder.

	```haxe
	var images = new Images(decoder, assets);
	images.load("player.png", image -> texture = graphics.createTexture(image.width, image.height, [image.pixels]));
	``` */
class Images implements IPollable {
	/** Creates the images over the platform's decoder, finding files through the assets.

		@param decoder  The platform's image decoder.
		@param assets  Where files are found. */
	public function new(decoder:IImageDecoder, assets:Assets) {
		this.decoder = decoder;
		this.assets = assets;
	}

	/** Loads an image file and decodes it: PNG, JPEG, BMP, TGA, or a GIF's first frame.

		One of `loaded` or `failed` is called once, at a later `poll`, never during this call.
		@param path  The file, as the assets name it.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded or decoded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function load(path:String, loaded:Image->Void, ?failed:String->Void):Void->Void {
		var request = new Request(path, failed);
		request.loaded = loaded;
		requests.push(request);
		var abortLoad = assets.load(path, bytes -> if (!request.aborted) decodeInto(request, bytes), message -> if (!request.aborted) {
			request.message = message;
			ready.push(request);
		});
		return () -> {
			request.abort();
			abortLoad();
		};
	}

	/** Decodes an image held in other bytes, such as a model's.

		One of `decoded` or `failed` is called once, at a later `poll`, never during this call.
		@param encoded  The image file's bytes.
		@param decoded  Receives the image, its `path` "".
		@param failed  Optional. Receives why it couldn't be decoded. When omitted, the failure is logged.
		@return  A function that aborts the decode; neither callback is called after it, and once one was, it does nothing. */
	public function decode(encoded:Bytes, decoded:Image->Void, ?failed:String->Void):Void->Void {
		var request = new Request("", failed);
		request.loaded = decoded;
		requests.push(request);
		decodeInto(request, encoded);
		return request.abort;
	}

	/** Decodes an image file for the GPU (`IImageDecoder.decodeForGpu`): in a page the browser's decoded image, uploaded as it is by
		`IGraphics.createTextureFromImage`, so the program never holds its pixels; natively the pixels.

		One of `decoded` or `failed` is called once, at a later `poll`, never during this call.
		@param encoded  The image file's bytes.
		@param decoded  Receives the image, which the receiver disposes once uploaded.
		@param failed  Optional. Receives why it couldn't be decoded. When omitted, the failure is logged.
		@return  A function that aborts the decode; neither callback is called after it, and once one was, it does nothing. An image
			decoded after the abort is disposed. */
	public function decodeForGpu(encoded:Bytes, decoded:IDecodedImage->Void, ?failed:String->Void):Void->Void {
		var request = new Request("", failed);
		request.loadedForGpu = decoded;
		requests.push(request);
		decoder.decodeForGpu(encoded, image -> {
			if (request.aborted || disposed) {
				image.dispose();
				return;
			}
			request.forGpu = image;
			ready.push(request);
		}, message -> {
			if (request.aborted || disposed)
				return;
			request.message = message;
			ready.push(request);
		});
		return request.abort;
	}

	/** Delivers what was loaded and decoded since the last poll. */
	public function poll():Void {
		var now = ready;
		ready = [];
		for (request in now) {
			requests.remove(request);
			if (request.aborted) {
				if (request.forGpu != null)
					request.forGpu.dispose();
				continue;
			}
			request.aborted = true;
			if (request.forGpu != null)
				request.loadedForGpu(request.forGpu);
			else if (request.image != null)
				request.loaded(request.image);
			else if (request.failed != null)
				request.failed(request.message);
			else
				helix.log.Log.warn(request.message, "images");
		}
	}

	/** Aborts every load and decode in flight. The images aren't used after it. */
	public function dispose():Void {
		for (request in requests)
			request.abort();
		for (request in ready)
			if (request.forGpu != null)
				request.forGpu.dispose();
		requests = [];
		ready = [];
		disposed = true;
	}

	final decoder:IImageDecoder;
	final assets:Assets;
	var requests:Array<Request> = [];
	// Answered since the last poll, delivered at the next.
	var ready:Array<Request> = [];
	var disposed = false;

	function decodeInto(request:Request, bytes:Bytes):Void {
		decoder.decode(bytes, (pixels, width, height) -> {
			if (request.aborted || disposed)
				return;
			request.image = new Image(request.path, width, height, pixels);
			ready.push(request);
		}, message -> {
			if (request.aborted || disposed)
				return;
			request.message = request.path == "" ? message : '${request.path}: $message';
			ready.push(request);
		});
	}
}

/** One load or decode in flight: what to call, and its answer once it came. */
private class Request {
	/** Gets the path, or "" for a decode. */
	public final path:String;

	/** Gets what receives a failure, or null to log it. */
	public final failed:Null<String->Void>;

	/** Gets or sets what receives the image. */
	public var loaded:Image->Void = null;

	/** Gets or sets the image, once decoded. */
	public var image:Null<Image> = null;

	/** Gets or sets what receives the image decoded for the GPU (`decodeForGpu`). */
	public var loadedForGpu:IDecodedImage->Void = null;

	/** Gets or sets the image decoded for the GPU, once it is. */
	public var forGpu:Null<IDecodedImage> = null;

	/** Gets or sets why it failed. */
	public var message = "";

	/** Gets or sets whether it was aborted or answered, so nothing more is called. */
	public var aborted = false;

	/** Creates a request. */
	public function new(path:String, failed:Null<String->Void>) {
		this.path = path;
		this.failed = failed;
	}

	/** Aborts it. */
	public function abort():Void
		aborted = true;
}
