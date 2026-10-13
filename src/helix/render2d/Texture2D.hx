package helix.render2d;

import helix.graphics.IGraphics;
import haxe.io.Bytes;

/** A GPU texture with its size. getWhiteU/getWhiteV name an opaque white texel, -1 when it has none, for untextured shapes. */
class Texture2D {
	var handle:Int;
	var width:Int;
	var height:Int;
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

	/** U of the center of an opaque white texel, or -1 when it has none. */
	public function getWhiteU():Float
		return whiteU;

	/** V of the center of an opaque white texel, or -1 when it has none. */
	public function getWhiteV():Float
		return whiteV;

	function new(handle:Int, width:Int, height:Int) {
		this.handle = handle;
		this.width = width;
		this.height = height;
	}

	/** Uploads width x height RGBA8 pixels, rows top first; whiteX, whiteY name an opaque white texel for untextured shapes, -1 for none. mipmaps adds
		a chain (Mipmaps.build), so a linear texture drawn smaller than itself doesn't shimmer. The caller destroys it. */
	public static function fromRgba(gpu:IGraphics, width:Int, height:Int, rgba:Bytes, linear = false, whiteX = -1, whiteY = -1, mipmaps = false):Texture2D {
		var texture = new Texture2D(gpu.createTexture(width, height, mipmaps ? helix.graphics.Mipmaps.build(width, height, rgba) : [rgba], linear), width,
			height);
		if (whiteX >= 0) {
			texture.whiteU = (whiteX + .5) / width;
			texture.whiteV = (whiteY + .5) / height;
		}
		return texture;
	}

	/** A new image in place of this one (a hot reload): the same object, a new GPU texture. */
	@:allow(helix.render2d.Textures)
	function replace(gpu:IGraphics, width:Int, height:Int, rgba:Bytes, linear:Bool):Void {
		var old = handle;
		handle = gpu.createTexture(width, height, linear ? helix.graphics.Mipmaps.build(width, height, rgba) : [rgba], linear);
		this.width = width;
		this.height = height;
		gpu.destroyTexture(old);
	}

	/** Frees the GPU texture on gpu, the adapter that made it. */
	public function destroy(gpu:IGraphics):Void
		gpu.destroyTexture(handle);
}
