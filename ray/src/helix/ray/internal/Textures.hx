package helix.ray.internal;

import helix.services.images.Image;

/** Holds every texture a program has, by the id its `Texture2D` carries: one GPU texture for each file however often it is loaded,
	counted by its holders (the program's loads of it and the material maps given it, docs/DECISIONS.md 25) and freed when the last lets
	go, and sent to the GPU when first drawn rather than when loaded. */
@:noCompletion
class Textures {
	/** The id of raylib's default texture, rlgl's 1x1 white pixel (`rlGetTextureIdDefault`): the frame's white texture, which
		`LoadMaterialDefault`'s diffuse map and the shapes draw with. It is never freed: `release` and `retain` leave it. */
	public static inline final DEFAULT = 1;

	static var next = DEFAULT + 1;
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

	/** How a texture is sampled until `setSampling` says otherwise: raylib's point filter, repeating past its edges as rlLoadTexture sets
		on desktop GL. */
	public static final DEFAULT_SAMPLING = new helix.platform.Sampling(Nearest, Repeat, Repeat);

	/** Returns how a texture is drawn, by its GPU handle: as `setSampling` set, else `DEFAULT_SAMPLING`.

		@param gpu  The GPU handle.
		@return  The sampling. */
	public static function samplingOf(gpu:Int):helix.platform.Sampling {
		var s = samplings.get(gpu);
		return s == null ? DEFAULT_SAMPLING : s;
	}

	static final samplings = new Map<Int, helix.platform.Sampling>();

	/** Returns how a texture is sampled, by its id: as `setSampling` set, else `DEFAULT_SAMPLING`.

		@param id  The texture's id.
		@return  The sampling. */
	public static function samplingOfId(id:Int):helix.platform.Sampling {
		var e = entries.get(id);
		return e == null || e.sampling == null ? DEFAULT_SAMPLING : e.sampling;
	}

	/** Returns a texture's pixels while they are in memory: those not yet sent to the GPU, or the image file it was loaded from.

		@param id  The texture's id.
		@return  The image (`DEFAULT`'s its white pixel), or null when its pixels are only on the GPU. */
	public static function imageOf(id:Int):Null<Image> {
		if (id == DEFAULT) {
			var white = haxe.io.Bytes.alloc(4);
			white.fill(0, 4, 255);
			return new Image("", 1, 1, white);
		}
		var e = entries.get(id);
		if (e == null)
			return null;
		return e.image != null ? e.image : e.path != "" ? Runtime.image(e.path) : null;
	}

	/** Returns a texture's GPU handle, sending it to the GPU if this is its first use.

		@param id  The texture's id.
		@return  The handle, the frame's white texture for `DEFAULT`, or 0 for an id with no texture. */
	public static function handle(id:Int):Int {
		if (id == DEFAULT)
			return Runtime.frame.white;
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

	/** Releases one of a texture's holders, freeing it when it was the last.

		@param id  The texture's id.
		@return  True when the texture is gone: freed now, or already; false while others hold it, and for `DEFAULT` and 0. */
	public static function release(id:Int):Bool {
		if (id == DEFAULT || id == 0)
			return false;
		var e = entries.get(id);
		if (e == null)
			return true;
		if (--e.refs > 0)
			return false;
		if (e.gpu != 0) {
			Runtime.graphics.disposeTexture(e.gpu);
			samplings.remove(e.gpu);
		}
		entries.remove(id);
		if (e.path != "" && byPath.get(e.path) == id)
			byPath.remove(e.path);
		return true;
	}

	/** Takes one more holder of a texture: a load of its file again, or a material map given it.

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
