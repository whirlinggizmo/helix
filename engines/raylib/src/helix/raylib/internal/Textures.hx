package helix.raylib.internal;

import helix.services.images.Image;

/** Holds every texture a program has, by the id its `Texture2D` carries: one GPU texture for each file however often it is loaded,
	counted by its holders (docs/DECISIONS.md 25) and freed when the last lets go, and sent to the GPU when first drawn rather than when
	loaded; a cubemap (`fromCube`) is one too. A holder is the program, from each load of it (`fromImage`, `fromHandle`, `fromCube`) until `releaseHeld`, or a material map given it
	(`retain`, `release`); the program's holds are counted apart too, so `UnloadTexture` on a map's copy lets go of one of them first. */
@:noCompletion
class Textures {
	/** The id of raylib's default texture, rlgl's 1x1 white pixel (`rlGetTextureIdDefault`): the frame's white texture, which
		`LoadMaterialDefault`'s diffuse map and the shapes draw with. It is never freed: `release` and `retain` leave it. */
	public static inline final DEFAULT = 1;

	static var next = DEFAULT + 1;
	static final entries = new Map<Int, Entry>();
	static final byPath = new Map<String, Int>();

	/** Returns the id of a file's texture, shared with its earlier loads while any holds it, held by the program: the image goes to the
		GPU when first drawn.

		@param path  The file (or a key of its own, as a model's image's), or "" for an image of no file, which is never shared.
		@param image  Its pixels, used when no load of the file is held.
		@param levels  Optional. Its mipmaps, 8-bit RGBA, each half the size of the last; none when omitted.
		@return  The id. */
	public static function fromImage(path:String, image:Image, ?levels:Array<haxe.io.Bytes>):Int {
		if (path != "" && byPath.exists(path)) {
			var id = byPath.get(path), e = entries.get(id);
			e.refs++;
			e.held++;
			return id;
		}
		var id = next++;
		entries.set(id, {
			path: path,
			image: image,
			gpu: 0,
			refs: 1,
			held: 1,
			levels: levels
		});
		if (path != "")
			byPath.set(path, id);
		return id;
	}

	/** Returns an id for a texture already on the GPU, held by the program: a render texture's, or the default font's.

		@param gpu  Its handle.
		@return  The id. */
	public static function fromHandle(gpu:Int):Int {
		var id = next++;
		entries.set(id, {
			path: "",
			image: null,
			gpu: gpu,
			refs: 1,
			held: 1
		});
		return id;
	}

	/** Returns the id of a cubemap, held by the program: its faces go to the GPU when first drawn. It is sampled linearly, through its
		mipmaps when it has them, as rlgl's cubemaps are, and `setSampling` leaves it so.

		@param size  Each face's width and height, in pixels.
		@param levels  Its levels, each half the size of the last and at least 1: each its six faces, 8-bit RGBA, in the order +X, -X, +Y,
			-Y, +Z, -Z, rows top first.
		@return  The id. */
	public static function fromCube(size:Int, levels:Array<haxe.io.Bytes>):Int {
		var id = next++;
		entries.set(id, {
			path: "",
			image: null,
			gpu: 0,
			refs: 1,
			held: 1,
			cube: {size: size, levels: levels},
			sampling: new helix.platform.Sampling(Linear, Clamp, Clamp, levels.length > 1 ? Linear : None)
		});
		return id;
	}

	/** Returns whether a texture is a cubemap (`fromCube`).

		@param id  The texture's id.
		@return  True when it is. */
	public static function isCube(id:Int):Bool {
		var e = entries.get(id);
		return e != null && e.cube != null;
	}

	/** Returns whether a GPU texture is a cubemap's, so a draw binds it only where a program samples a cube.

		@param gpu  The GPU handle.
		@return  True when it is. */
	public static function isCubeHandle(gpu:Int):Bool
		return cubeHandles.exists(gpu);

	static final cubeHandles = new Map<Int, Bool>();

	/** Returns whether a file's texture (or a key's, as `fromImage` takes it) is held, so a load of it shares it.

		@param path  The file, or the key.
		@return  True when it is. */
	public static function hasPath(path:String):Bool
		return byPath.exists(path);

	/** Returns whether the program holds a texture: whether a load of it hasn't been let go of (`releaseHeld`).

		@param id  The texture's id.
		@return  True when it does. */
	public static function isHeld(id:Int):Bool {
		var e = entries.get(id);
		return e != null && e.held > 0;
	}

	/** Lets go of one of the program's holds on a texture, freeing it when it was the last holder.

		@param id  The texture's id.
		@return  True when the texture is gone, as `release` answers. */
	public static function releaseHeld(id:Int):Bool {
		var e = entries.get(id);
		if (e != null && e.held > 0)
			e.held--;
		return release(id);
	}

	/** Sets how a texture is sampled, by its GPU handle when it has one, or once it is sent.

		@param id  The texture's id.
		@param sampling  The sampling. */
	public static function setSampling(id:Int, sampling:helix.platform.Sampling):Void {
		var e = entries.get(id);
		if (e == null || e.cube != null)
			return;
		e.sampling = sampling;
		if (e.gpu != 0)
			samplings.set(e.gpu, sampling);
	}

	/** How a texture is sampled until `setSampling` says otherwise: raylib's point filter, its mipmaps not read, repeating past its
		edges as rlLoadTexture sets on desktop GL. */
	public static final DEFAULT_SAMPLING = new helix.platform.Sampling(Nearest, Repeat, Repeat, None);

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
			e.gpu = Runtime.graphics.createTexture(e.image.width, e.image.height, e.levels == null ? [e.image.pixels] : [e.image.pixels].concat(e.levels));
			if (e.sampling != null)
				samplings.set(e.gpu, e.sampling);
			// Its pixels are on the GPU now; the copy here isn't needed again.
			e.image = null;
			e.levels = null;
		} else if (e.gpu == 0 && e.cube != null) {
			e.gpu = Runtime.graphics.createCubeTexture(e.cube.size, e.cube.levels, helix.platform.TextureFormat.Rgba8);
			cubeHandles.set(e.gpu, true);
			samplings.set(e.gpu, e.sampling);
			e.cube = {size: e.cube.size, levels: null};
		}
		return e.gpu;
	}

	/** Replaces a rectangle of a texture's pixels: in memory while it isn't on the GPU yet, else on the GPU in the frame's order
		(`Frame.updateTexture`).

		@param id  The texture's id.
		@param x  The rectangle's left edge, in pixels.
		@param y  Its top edge.
		@param width  Its width.
		@param height  Its height.
		@param rgba  Its pixels, 8-bit RGBA, rows top first. */
	public static function update(id:Int, x:Int, y:Int, width:Int, height:Int, rgba:haxe.io.Bytes):Void {
		var e = entries.get(id);
		if (e == null || e.cube != null)
			return;
		if (e.gpu == 0 && e.image != null) {
			// Its own copy: a file's image may be shared with other loads, and the decoded file kept.
			if (!e.owned) {
				e.image = new Image(e.image.path, e.image.width, e.image.height, e.image.pixels.sub(0, e.image.pixels.length));
				e.owned = true;
			}
			for (row in 0...height)
				e.image.pixels.blit(((y + row) * e.image.width + x) * 4, rgba, row * width * 4, width * 4);
			return;
		}
		if (e.gpu != 0)
			Runtime.frame.updateTexture(e.gpu, x, y, width, height, rgba);
	}

	/** Returns a texture's GPU handle when it is on the GPU, without sending it there.

		@param id  The texture's id.
		@return  The handle, the frame's white texture for `DEFAULT`, or 0 while it is only in memory. */
	public static function onGpu(id:Int):Int {
		if (id == DEFAULT)
			return 0;
		var e = entries.get(id);
		return e == null ? 0 : e.gpu;
	}

	/** Makes a texture's mipmaps, as GL's `glGenerateMipmap` makes them (`Mipmaps`): in memory while it isn't on the GPU yet; else from its
		pixels read back from the GPU, a texture of them taking its place, the old one freed once the frame is drawn (draws asked for
		before read the old). One updated this frame (`update`) is read once the frame is drawn, so the update is in its mipmaps.

		@param id  The texture's id. */
	public static function generateMipmaps(id:Int):Void {
		var e = entries.get(id);
		if (e == null || id == DEFAULT || e.cube != null)
			return;
		if (e.gpu == 0) {
			if (e.image != null)
				e.levels = Mipmaps.build(e.image.width, e.image.height, e.image.pixels);
			return;
		}
		function remake():Void {
			var gpu = e.gpu;
			Runtime.graphics.readPixels(gpu, (pixels, width, height) -> {
				if (entries.get(id) != e || e.gpu != gpu)
					return;
				var made = Runtime.graphics.createTexture(width, height, [pixels].concat(Mipmaps.build(width, height, pixels)));
				var sampling = samplings.get(gpu);
				if (sampling != null)
					samplings.set(made, sampling);
				e.gpu = made;
				Runtime.frame.afterDraw(() -> {
					Runtime.graphics.disposeTexture(gpu);
					samplings.remove(gpu);
				});
			}, _ -> {});
		}
		if (Runtime.frame.isUpdating(e.gpu))
			Runtime.frame.afterDraw(remake);
		else
			remake();
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
			cubeHandles.remove(e.gpu);
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

@:structInit
private class Entry {
	public final path:String;
	public var image:Null<Image>;
	// Its mipmaps while it isn't on the GPU, or null for none.
	public var levels:Null<Array<haxe.io.Bytes>> = null;
	// Whether image is its own, so changing it changes no one else's (a file's image is shared with its other loads).
	public var owned:Bool = false;
	public var gpu:Int;
	public var refs:Int;
	public var held:Int;
	public var sampling:Null<helix.platform.Sampling> = null;
	// A cubemap's size, and its levels while it isn't on the GPU (null once it is); null for a 2D texture.
	public var cube:Null<{size:Int, levels:Null<Array<haxe.io.Bytes>>}> = null;
}
