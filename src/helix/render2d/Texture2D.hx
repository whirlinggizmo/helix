package helix.render2d;

import helix.graphics.IGraphics;
import helix.graphics.Sampling;
import helix.graphics.TextureFormat;
import haxe.io.Bytes;

/** A GPU texture with its size, its format and how it is sampled (Sampling: linear or nearest, and its wrap), which a draw reads when it
	takes the texture, so one texture can be drawn smooth and then sharp. getWhiteU/getWhiteV name an opaque white texel, -1 when it has none,
	for untextured shapes. */
class Texture2D {
	var handle:Int;
	var width:Int;
	var height:Int;
	var format:TextureFormat;
	var levels:Int;
	var sampling:Sampling;
	var whiteU = -1.;
	var whiteV = -1.;

	/** The IGraphics handle, for draws. */
	public function getHandle():Int
		return handle;

	/** Width in texels. */
	public function getWidth():Int
		return width;

	/** Height in texels. */
	public function getHeight():Int
		return height;

	/** Its texels' format: RGBA8, or a compressed one. */
	public function getFormat():TextureFormat
		return format;

	/** How many levels it has: 1, or the image and its mipmaps. */
	public function getLevelCount():Int
		return levels;

	/** The GPU memory its levels take, in bytes. */
	public function getByteCount():Int {
		var total = 0, w = width, h = height;
		for (_ in 0...levels) {
			total += format.levelBytes(w, h);
			w = w > 1 ? w >> 1 : 1;
			h = h > 1 ? h >> 1 : 1;
		}
		return total;
	}

	/** How draws sample it. */
	public function getSampling():Sampling
		return sampling;

	/** Samples it as value from the next draw that takes it on. */
	public function setSampling(value:Sampling):Void
		sampling = value;

	/** U of the center of an opaque white texel, or -1 when it has none. */
	public function getWhiteU():Float
		return whiteU;

	/** V of the center of an opaque white texel, or -1 when it has none. */
	public function getWhiteV():Float
		return whiteV;

	function new(handle:Int, width:Int, height:Int, format:TextureFormat, levels:Int, sampling:Sampling) {
		this.handle = handle;
		this.width = width;
		this.height = height;
		this.format = format;
		this.levels = levels;
		this.sampling = sampling;
	}

	/** Uploads width x height RGBA8 pixels, rows top first, sampled linear (smooth) or nearest (sharp, for pixel art); whiteX, whiteY name an
		opaque white texel for untextured shapes, -1 for none. mipmaps adds a chain (Mipmaps.build), so it can be drawn smaller than itself without
		shimmering. The caller destroys it. */
	public static function fromRgba(gpu:IGraphics, width:Int, height:Int, rgba:Bytes, linear = false, whiteX = -1, whiteY = -1, mipmaps = false):Texture2D {
		var levels = mipmaps ? helix.graphics.Mipmaps.build(width, height, rgba) : [rgba];
		var texture = new Texture2D(gpu.createTexture(width, height, levels), width, height, Rgba8, levels.length, new Sampling(linear));
		if (whiteX >= 0) {
			texture.whiteU = (whiteX + .5) / width;
			texture.whiteV = (whiteY + .5) / height;
		}
		return texture;
	}

	/** Uploads levels (the image and its mipmaps, each format.levelBytes of its size) of format, width x height, sampled as sampling says. Throws
		when the GPU can't sample format (IGraphics.canSample). The caller destroys it. */
	public static function fromLevels(gpu:IGraphics, width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat, sampling:Sampling):Texture2D
		return new Texture2D(gpu.createTexture(width, height, levels, format), width, height, format, levels.length, sampling);

	/** A render target width x height: a texture drawn into by target passes (IGraphics.beginTargetPass with its handle), sampled linear (smooth)
		or nearest (sharp: a low-resolution view shown larger). The caller destroys it. */
	public static function renderTarget(gpu:IGraphics, width:Int, height:Int, linear = true):Texture2D
		return new Texture2D(gpu.createRenderTarget(width, height), width, height, Rgba8, 1, new Sampling(linear));

	/** A new image in place of this one (a hot reload): the same object and sampling, a new GPU texture of levels. */
	@:allow(helix.render2d.TextureCache)
	function replace(gpu:IGraphics, width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat):Void {
		var old = handle;
		handle = gpu.createTexture(width, height, levels, format);
		this.width = width;
		this.height = height;
		this.format = format;
		this.levels = levels.length;
		gpu.destroyTexture(old);
	}

	/** Frees the GPU texture on gpu, the adapter that made it. */
	public function destroy(gpu:IGraphics):Void
		gpu.destroyTexture(handle);
}
