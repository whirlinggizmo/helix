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

	public function getHandle():Int
		return handle;

	public function getWidth():Int
		return width;

	public function getHeight():Int
		return height;

	public function getWhiteU():Float
		return whiteU;

	public function getWhiteV():Float
		return whiteV;

	function new(handle:Int, width:Int, height:Int) {
		this.handle = handle;
		this.width = width;
		this.height = height;
	}

	public static function fromRgba(gpu:IGraphics, width:Int, height:Int, rgba:Bytes, linear = false, whiteX = -1, whiteY = -1):Texture2D {
		var texture = new Texture2D(gpu.createTexture(width, height, rgba, linear), width, height);
		if (whiteX >= 0) {
			texture.whiteU = (whiteX + .5) / width;
			texture.whiteV = (whiteY + .5) / height;
		}
		return texture;
	}

	public function destroy(gpu:IGraphics):Void
		gpu.destroy("texture", handle);
}
