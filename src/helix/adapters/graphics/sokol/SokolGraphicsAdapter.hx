package helix.adapters.graphics.sokol;

import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.graphics.IGraphics;
import haxe.io.Bytes;

/** IGraphics on sokol_gfx for native hxcpp builds; a call the bridge refuses throws. */
class SokolGraphicsAdapter implements IGraphics {
	/** Sets up sokol_gfx; the window and its GL context must already exist. */
	public function new() {
		GraphicsBridge.setup();
	}

	static function pointer(data:Bytes):cpp.RawPointer<cpp.UInt8>
		return cpp.Pointer.arrayElem(data.getData(), 0).raw;

	static function valid(handle:Int):Int {
		if (handle == 0)
			throw "Sokol resource creation failed";
		return handle;
	}

	public function createTexture(width:Int, height:Int, rgba:Bytes, linear:Bool = false):Int
		return valid(GraphicsBridge.texture(width, height, pointer(rgba), rgba.length, linear ? 1 : 0));

	public function setClearColor(color:Int):Void
		GraphicsBridge.clearColor(color);

	public function createBuffer(capacityBytes:Int):Int
		return valid(GraphicsBridge.buffer(capacityBytes));

	public function createPipeline(alpha:Bool):Int
		return valid(GraphicsBridge.pipeline(alpha ? 1 : 0));

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		if (usedBytes > data.length || usedBytes < 0 || GraphicsBridge.update(handle, pointer(data), usedBytes) != 1)
			throw "Invalid native upload";
	}

	public function beginFrame(width:Int, height:Int, x:Int, y:Int, w:Int, h:Int):Void {
		if (GraphicsBridge.begin(width, height, x, y, w, h) != 1)
			throw "Invalid native pass";
	}

	public function draw(pipeline:Int, buffer:Int, texture:Int, vertices:Int, firstVertex:Int):Void {
		if (GraphicsBridge.draw(pipeline, buffer, texture, vertices, firstVertex) != 1)
			throw "Invalid native draw";
	}

	public function endFrame():Void
		GraphicsBridge.end();

	public function destroy(kind:String, handle:Int):Void {
		var n = switch (kind) {
			case "buffer": 0;
			case "texture": 1;
			case "pipeline": 2;
			default: -1;
		};
		if (GraphicsBridge.destroy(n, handle) != 1)
			throw "Invalid native resource";
	}

	public function shutdown():Void
		GraphicsBridge.shutdown();
}
