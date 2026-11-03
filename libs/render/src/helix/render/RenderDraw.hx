package helix.render;

import helix.services.shaders.Shader;
import helix.services.shaders.ShaderPipeline;
import helix.services.shaders.ShaderPipelineState;
import helix.services.shaders.ShaderSnapshot;
import helix.services.shaders.ShaderVertexLayout;

/** One GPU draw recorded in a pass: its pipeline, buffers, range and the values captured as it was made, submitted at the frame's end. */
@:noCompletion
@:allow(helix.render)
class RenderDraw {
	var pipeline:RenderPipeline;
	// Each buffer by its index in the pipeline's layout, a stream's when streams holds one there.
	final buffers:Array<Int> = [];
	final streams:Array<Null<RenderStream>> = [];
	var indexBuffer = 0;
	var first = 0;
	var count = 0;
	var firstInstance = 0;
	var instanceCount = 1;
	final snapshot = new ShaderSnapshot();

	function new() {}

	/** Forgets the buffers, for a draw made again from the pool. */
	function resetBuffers():Void {
		buffers.resize(0);
		streams.resize(0);
		indexBuffer = 0;
		firstInstance = 0;
		instanceCount = 1;
	}

	/** Sets a buffer by its index: a stream, or a buffer's handle when the stream is null. */
	function setBuffer(index:Int, handle:Int, ?stream:RenderStream):Void {
		while (buffers.length <= index) {
			buffers.push(0);
			streams.push(null);
		}
		buffers[index] = handle;
		streams[index] = stream;
	}

	/** Sets the one buffer a batch draw reads, its stream. */
	function setStream(stream:RenderStream):Void {
		buffers.resize(1);
		streams.resize(1);
		buffers[0] = 0;
		streams[0] = stream;
	}

	/** The handles the draw submits, its streams' as they are now. */
	function resolveBuffers():Array<Int> {
		for (i in 0...streams.length)
			if (streams[i] != null)
				buffers[i] = streams[i].handle;
		return buffers;
	}
}

/** A shader, a state and a layout a draw is made with, its pipeline built at the frame's end, before the first pass. */
@:noCompletion
@:allow(helix.render)
class RenderPipeline {
	final shader:Shader;
	final state:ShaderPipelineState;
	final layout:ShaderVertexLayout;
	var built:Null<ShaderPipeline> = null;

	function new(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout) {
		this.shader = shader;
		this.state = state;
		this.layout = layout;
	}
}
