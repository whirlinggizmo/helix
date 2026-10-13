package helix.adapters.graphics.sokol;

import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.graphics.IGraphics;
import helix.graphics.PipelineKind;
import helix.graphics.Sampling;
import helix.graphics.TextureFormat;
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

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int {
		if (levels.length == 0 || !canSample(format))
			throw "Invalid texture";
		// One buffer, the levels one after another: the bridge points each mip level into it.
		var total = 0;
		for (level in levels)
			total += level.length;
		var packed = Bytes.alloc(total), at = 0;
		for (level in levels) {
			packed.blit(at, level, 0, level.length);
			at += level.length;
		}
		return valid(GraphicsBridge.texture(width, height, pointer(packed), packed.length, levels.length, format));
	}

	public function canSample(format:TextureFormat):Bool
		return GraphicsBridge.canSample(format) == 1;

	public function createBuffer(capacityBytes:Int):Int
		return valid(GraphicsBridge.buffer(capacityBytes));

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int {
		if (bytes <= 0 || bytes > data.length)
			throw "Invalid static buffer";
		return valid(GraphicsBridge.staticBuffer(pointer(data), bytes, index ? 1 : 0));
	}

	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int, baseTexture:Int,
			baseSampling:Sampling, normalTexture:Int, normalSampling:Sampling, vertexUniforms:Bytes, fragmentUniforms:Bytes):Void {
		if (GraphicsBridge.drawMesh(pipeline, vertices, indices, indexCount, instances, firstInstance, instanceCount, baseTexture, baseSampling,
			normalTexture, normalSampling, pointer(vertexUniforms), vertexUniforms.length, pointer(fragmentUniforms), fragmentUniforms.length) != 1)
			throw "Invalid native mesh draw";
	}

	public function createPipeline(kind:PipelineKind, alpha:Bool):Int
		return valid(GraphicsBridge.pipeline(cast kind, alpha ? 1 : 0));

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		if (usedBytes > data.length || usedBytes < 0 || GraphicsBridge.update(handle, pointer(data), usedBytes) != 1)
			throw "Invalid native upload";
	}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (GraphicsBridge.begin(width, height, clearColor) != 1)
			throw "Invalid native pass";
	}

	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void {
		if (GraphicsBridge.viewport(x, y, w, h) != 1)
			throw "Invalid native viewport";
	}

	public function draw(pipeline:Int, buffer:Int, texture:Int, sampling:Sampling, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void {
		var ok = uniforms == null ? GraphicsBridge.draw(pipeline, buffer, texture, sampling, vertices, firstVertex, null,
			0) : GraphicsBridge.draw(pipeline, buffer, texture, sampling, vertices, firstVertex, pointer(uniforms), uniforms.length);
		if (ok != 1)
			throw "Invalid native draw";
	}

	public function endFrame():Void
		GraphicsBridge.end();

	public function destroyBuffer(handle:Int):Void
		if (GraphicsBridge.destroy(0, handle) != 1)
			throw "Invalid buffer";

	public function destroyTexture(handle:Int):Void
		if (GraphicsBridge.destroy(1, handle) != 1)
			throw "Invalid texture";

	public function destroyPipeline(handle:Int):Void
		if (GraphicsBridge.destroy(2, handle) != 1)
			throw "Invalid pipeline";

	public function shutdown():Void
		GraphicsBridge.shutdown();
}
