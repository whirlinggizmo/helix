package helix.ray.internal;

import helix.services.images.Image;

/** Holds every texture a program has, by the id its `Texture2D` carries: one GPU texture for each file however often it is loaded,
	released when its last load is unloaded, and sent to the GPU when first drawn rather than when loaded. */
@:noCompletion
class Textures {
	static var next = 1;
	static final entries = new Map<Int, Entry>();
	static final byPath = new Map<String, Int>();

	/** Returns the id of a file's texture, shared with its earlier loads: the image goes to the GPU when first drawn.

		@param path  The file, or "" for an image of no file, which is never shared.
		@param image  Its pixels.
		@return  The id. */
	public static function fromImage(path:String, image:Image):Int {
		if (path != "" && byPath.exists(path)) {
			var id = byPath.get(path);
			entries.get(id).refs++;
			return id;
		}
		var id = next++;
		entries.set(id, {
			path: path,
			image: image,
			gpu: 0,
			refs: 1
		});
		if (path != "")
			byPath.set(path, id);
		return id;
	}

	/** Returns an id for a texture already on the GPU: a render texture's, or the default font's.

		@param gpu  Its handle.
		@return  The id. */
	public static function fromHandle(gpu:Int):Int {
		var id = next++;
		entries.set(id, {
			path: "",
			image: null,
			gpu: gpu,
			refs: 1
		});
		return id;
	}

	/** Sets how a texture is sampled, by its GPU handle when it has one, or once it is sent.

		@param id  The texture's id.
		@param sampling  The sampling. */
	public static function setSampling(id:Int, sampling:helix.platform.Sampling):Void {
		var e = entries.get(id);
		if (e == null)
			return;
		e.sampling = sampling;
		if (e.gpu != 0)
			samplings.set(e.gpu, sampling);
	}

	/** Returns how a texture is drawn, by its GPU handle: as `setSampling` set, else nearest, raylib's point filter.

		@param gpu  The GPU handle.
		@return  The sampling. */
	public static function samplingOf(gpu:Int):helix.platform.Sampling {
		var s = samplings.get(gpu);
		return s == null ? helix.platform.Sampling.NEAREST : s;
	}

	static final samplings = new Map<Int, helix.platform.Sampling>();

	/** Returns a texture's GPU handle, sending it to the GPU if this is its first use.

		@param id  The texture's id.
		@return  The handle, or 0 for an id with no texture. */
	public static function handle(id:Int):Int {
		var e = entries.get(id);
		if (e == null)
			return 0;
		if (e.gpu == 0 && e.image != null) {
			e.gpu = Runtime.graphics.createTexture(e.image.width, e.image.height, [e.image.pixels]);
			if (e.sampling != null)
				samplings.set(e.gpu, e.sampling);
			// Its pixels are on the GPU now; the copy here isn't needed again.
			e.image = null;
		}
		return e.gpu;
	}

	/** Releases one load of a texture, freeing it when it was the last.

		@param id  The texture's id. */
	public static function release(id:Int):Void {
		var e = entries.get(id);
		if (e == null || --e.refs > 0)
			return;
		if (e.gpu != 0) {
			Runtime.graphics.disposeTexture(e.gpu);
			samplings.remove(e.gpu);
		}
		entries.remove(id);
		if (e.path != "" && byPath.get(e.path) == id)
			byPath.remove(e.path);
	}

	/** Takes one more load of a texture, as a model loaded again shares its textures.

		@param id  The texture's id. */
	public static function retain(id:Int):Void {
		var e = entries.get(id);
		if (e != null)
			e.refs++;
	}
}

private typedef Entry = {
	final path:String;
	var image:Null<Image>;
	var gpu:Int;
	var refs:Int;
	var ?sampling:helix.platform.Sampling;
}
