package helix.render;

import haxe.io.Bytes;
import helix.platform.IGraphics;
import helix.services.shaders.ShaderVertexLayout;

/** A frame's vertices of one layout, written on the CPU as draws are recorded and uploaded at the start of each pass that draws from
	them: a stream buffer on the GPU, grown before the frame's first pass when the frame holds more than it can. */
@:noCompletion
@:allow(helix.render)
class RenderStream {
	/** Gets the bytes a record takes. */
	final stride:Int;

	/** Gets the layout a pipeline reads it by. */
	final layout:ShaderVertexLayout;

	final graphics:IGraphics;
	var bytes:Bytes;
	var used = 0;
	var handle = 0;
	var capacity = 0;

	function new(graphics:IGraphics, stride:Int, layout:ShaderVertexLayout) {
		this.graphics = graphics;
		this.stride = stride;
		this.layout = layout;
		bytes = Bytes.alloc(stride * 1024);
	}

	/** Gets the number of records written this frame. */
	var count(get, never):Int;

	inline function get_count():Int
		return Std.int(used / stride);

	/** Makes room for records and returns the byte offset of the first. */
	function reserve(records:Int):Int {
		var at = used;
		var need = used + records * stride;
		if (need > bytes.length) {
			var size = bytes.length;
			while (size < need)
				size *= 2;
			var grown = Bytes.alloc(size);
			grown.blit(0, bytes, 0, used);
			bytes = grown;
		}
		used = need;
		return at;
	}

	/** Grows the GPU buffer to hold the frame's records, outside a pass. */
	function prepare():Void {
		if (used == 0 || used <= capacity)
			return;
		if (handle != 0)
			graphics.disposeBuffer(handle);
		capacity = 4096;
		while (capacity < used)
			capacity *= 2;
		handle = graphics.createBuffer(capacity);
	}

	/** Uploads the frame's records, inside a pass. */
	function upload():Void {
		if (used > 0)
			graphics.updateBuffer(handle, bytes, used);
	}

	function dispose():Void {
		if (handle != 0)
			graphics.disposeBuffer(handle);
		handle = 0;
		capacity = 0;
	}
}
