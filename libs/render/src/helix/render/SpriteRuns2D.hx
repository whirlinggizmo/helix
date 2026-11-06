package helix.render;

import haxe.io.Bytes;
import helix.math.Matrix3D;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderSampler;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;
import helix.services.shaders.ShaderVertexLayout;

/** Draws runs of quads from records a program writes itself: `Batch2D`'s sprite path, for what writes thousands of quads a frame and wants
	nothing between it and the buffer: a particle system, a tile map, a layer with a batch of its own.

	A quad is one record of `RECORD_BYTES` and is drawn as an instance of one quad, so a frame of them is one buffer and as few GPU draws as
	it has textures. A record holds the quad's four corners in order round it as x and y floats, its texture's rectangle as u0, v0, u1 and v1
	floats, and its color as red, green, blue and alpha bytes. u0 and v0 are read at the first corner, u0 and v1 at the second, u1 and v1 at
	the third and u1 and v0 at the fourth, and the corners make the triangles first, second, third and first, third, fourth.

	`reserve` makes room in the frame's records and `writeFloat` and `writeColor` fill it. `draw` then draws a range of the frame's records
	into the renderer's current pass, at the point it is called. The records are read when the frame is drawn, so they may be written in any
	order, and a range drawn twice is one upload. They are emptied by `Renderer.endFrame`.

	```haxe
	var runs = new SpriteRuns2D(renderer);
	// each frame, between Renderer.beginFrame and endFrame:
	var first = runs.count;
	for (spark in sparks) {
		var at = runs.reserve(1);
		runs.writeFloat(at, spark.x);
		runs.writeFloat(at + 4, spark.y);
		runs.writeFloat(at + 8, spark.x);
		runs.writeFloat(at + 12, spark.y + 4);
		runs.writeFloat(at + 16, spark.x + 4);
		runs.writeFloat(at + 20, spark.y + 4);
		runs.writeFloat(at + 24, spark.x + 4);
		runs.writeFloat(at + 28, spark.y);
		runs.writeFloat(at + 32, 0);
		runs.writeFloat(at + 36, 0);
		runs.writeFloat(at + 40, 1);
		runs.writeFloat(at + 44, 1);
		runs.writeColor(at + 48, spark.color);
	}
	runs.draw(first, runs.count - first, sheet.handle, sheet.sampling, screenMatrix);
	``` */
class SpriteRuns2D {
	/** The bytes of a quad's record. */
	public static inline final RECORD_BYTES = 52;

	/** Gets the number of records written this frame. */
	public var count(get, never):Int;

	/** Gets the frame's records, for a program reading back what it wrote. A later `reserve` may replace it, so it is read after the
		last. */
	public var bytes(get, never):Bytes;

	/** Creates the runs over a renderer. Every `SpriteRuns2D` over one renderer writes into one frame's records.

		@param renderer  The renderer it records into. */
	public function new(renderer:Renderer) {
		this.renderer = renderer;
		if (layout == null)
			layout = new ShaderVertexLayout([
				{stride: 4, placements: [{name: "spriteCorner", offset: 0}]},
				{
					stride: RECORD_BYTES,
					instanced: true,
					placements: [
						{name: "spriteCornersAB", offset: 0},
						{name: "spriteCornersCD", offset: 16},
						{name: "spriteRegion", offset: 32},
						{name: "spriteColor", offset: 48, format: UByte4Norm}
					]
				}
			]);
		shader = RenderShaders.compileOwn("batch2d-sprite.vert", "batch2d.frag");
		values = new ShaderValues(shader);
		modelViewProjection = shader.getUniform("modelViewProjection");
		linearTarget = shader.getUniform("linearTarget");
		fontKind = shader.getUniform("fontKind");
		baseColorTexture = shader.getSampler("baseColorTexture");
		stream = renderer.stream("batch2d-sprites", RECORD_BYTES, layout);
	}

	/** Makes room for records in the frame's and returns the byte offset of the first, for `writeFloat` and `writeColor`.

		@param count  How many.
		@return  The first's byte offset. */
	public function reserve(count:Int):Int {
		var at = stream.reserve(count);
		#if js
		if (stream.bytes != written) {
			written = stream.bytes;
			floats = new js.lib.Float32Array(written.getData());
			ints = new js.lib.Int32Array(written.getData());
		}
		#end
		return at;
	}

	/** Takes the last records back out of the frame's, for a shape left short.

		@param count  How many, at most those written. */
	public function drop(count:Int):Void {
		stream.used -= count * RECORD_BYTES;
	}

	/** Writes a float into the records `reserve` made room for: natively without `Bytes.setFloat`'s bounds check and call, in a page
		through a float view.

		@param at  Its byte offset, a multiple of 4.
		@param value  The value. */
	public inline function writeFloat(at:Int, value:Float):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(stream.bytes.getData(), at, value);
		#elseif js
		floats[at >> 2] = value;
		#else
		stream.bytes.setFloat(at, value);
		#end
	}

	/** Writes a record's color as `writeFloat` writes a float.

		@param at  Its byte offset, a multiple of 4.
		@param color  Its red, green, blue and alpha bytes, red the lowest: one little-endian int. */
	public inline function writeColor(at:Int, color:Int):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_i32(stream.bytes.getData(), at, color);
		#elseif js
		ints[at >> 2] = color;
		#else
		stream.bytes.setInt32(at, color);
		#end
	}

	/** Draws a range of the frame's records into the current pass as one GPU draw, instances of one quad.

		@param first  The first record.
		@param count  How many.
		@param texture  The platform's handle of the texture they read (`Texture2D.handle`).
		@param sampling  How it is sampled.
		@param viewProjection  What their corners are moved by. It is read now.
		@param blend  Optional. How they are combined with what is under them; `Blend.ALPHA` by default.
		@param depthTest  Optional. How they are tested against the depth; `DepthTest.Off` by default.
		@param depthWrite  Optional. Whether they write the depth; false by default.
		@param cull  Optional. Which faces are dropped, first, second, third corners counterclockwise on the screen being a front; none by
			default.
		@param colorWrite  Optional. The channels written; all by default.
		@param fontKind  Optional. The kind of font (helix-services' `FontKind`) whose atlas they read, as a number; 0 for any other
			texture.
		@param linear  Optional. Whether the pass holds linear light (an RGBA16F target), their colors decoded as they are drawn; false by
			default. */
	public function draw(first:Int, count:Int, texture:Int, sampling:Sampling, viewProjection:Matrix3D, ?blend:Blend, depthTest:DepthTest = Off,
			depthWrite = false, cull:CullFace = None, colorWrite:ColorChannels = All, fontKind = 0, linear = false):Void {
		if (count <= 0)
			return;
		if (quadRestores != renderer.restores) {
			quadRestores = renderer.restores;
			var corners = Bytes.alloc(16);
			for (c in 0...4)
				corners.setFloat(c * 4, c);
			quadCorners = renderer.staticBuffer(corners, false);
			var indices = Bytes.alloc(24);
			for (k => i in [0, 1, 2, 0, 2, 3])
				indices.setInt32(k * 4, i);
			quadIndices = renderer.staticBuffer(indices, true);
		}
		values.writeTexture(baseColorTexture, texture, sampling);
		values.writeMatrix(modelViewProjection, viewProjection);
		values.writeInt(linearTarget, linear ? 1 : 0);
		values.writeInt(this.fontKind, fontKind);
		var state = renderer.stateFor(Triangles, true, blend == null ? Blend.ALPHA : blend, depthTest, depthWrite, cull, colorWrite);
		var d = renderer.makeDraw(renderer.pipelineFor(shader, state, layout));
		d.setBuffer(0, quadCorners);
		d.setBuffer(1, 0, stream);
		d.indexBuffer = quadIndices;
		d.first = 0;
		d.count = 6;
		d.firstInstance = first;
		d.instanceCount = count;
		values.capture(d.snapshot);
		renderer.record(d);
	}

	inline function get_count():Int
		return stream.count;

	inline function get_bytes():Bytes
		return stream.bytes;

	// The renderer, the shader drawing a quad a record, its values and the names it fills, the frame's records, and the quad they are
	// instances of, its four corner numbers and six indices (made as the first run is drawn, and the first after a lost context).
	final renderer:Renderer;
	final shader:Shader;
	final values:ShaderValues;
	final modelViewProjection:ShaderUniform;
	final linearTarget:ShaderUniform;
	final fontKind:ShaderUniform;
	final baseColorTexture:ShaderSampler;
	final stream:RenderStream;
	var quadCorners = 0;
	var quadIndices = 0;
	var quadRestores = -1;
	#if js
	// The records' bytes, and their floats and ints written through views rather than Bytes' calls; remade when the stream grows.
	var written:Null<Bytes> = null;
	var floats:Null<js.lib.Float32Array> = null;
	var ints:Null<js.lib.Int32Array> = null;
	#end

	// The records' buffers: the quad's corner numbers, and the records.
	static var layout:Null<ShaderVertexLayout> = null;
}
