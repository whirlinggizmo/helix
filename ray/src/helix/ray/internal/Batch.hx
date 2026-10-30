package helix.ray.internal;

import haxe.io.Bytes;
import helix.platform.IGraphics;
import helix.platform.Sampling;
import helix.platform.tools.ShaderCompiler;

/** Collects a frame's 2D drawing as textured, colored triangles in screen pixels, and draws them at the frame's end in the order given,
	with one upload. Shapes draw with a white texel. */
@:noCompletion
class Batch {
	static inline final FLOATS = 8;
	static inline final STRIDE = FLOATS * 4;

	final graphics:IGraphics;
	final shader:Int;
	final pipeline:Int;
	final screen = Bytes.alloc(16);
	final sampling = new Sampling(Nearest);
	var data = Bytes.alloc(STRIDE * 6 * 1024);
	var vertices = 0;
	var buffer = 0;
	var capacity = 0;
	// Each run of one texture: its texture, then its first vertex and count.
	final runs:Array<Int> = [];

	/** Gets the white texture shapes draw with. */
	public final white:Int;

	/** Creates the batch's program, pipeline and white texture.

		@param graphics  The graphics it draws with. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
		shader = graphics.createShader(ShaderCompiler.compile("batch.vert", "batch.frag"));
		pipeline = graphics.createPipeline({
			shader: shader,
			buffers: [
				{
					stride: STRIDE,
					instanced: false,
					attributes: [
						{slot: 0, componentCount: 2, offset: 0},
						{slot: 1, componentCount: 2, offset: 8},
						{slot: 2, componentCount: 4, offset: 16}
					]
				}
			],
			primitive: Triangles,
			indexed: false,
			blend: Alpha,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: None
		});
		var texel = Bytes.alloc(4);
		texel.fill(0, 4, 255);
		white = graphics.createTexture(1, 1, [texel]);
	}

	/** Drops what was collected, for a new frame. */
	public function clear():Void {
		vertices = 0;
		runs.resize(0);
	}

	/** Adds one vertex.

		@param texture  The texture its triangle samples.
		@param x  Across the screen, in pixels.
		@param y  Down the screen, in pixels.
		@param u  Across the texture, 0 to 1.
		@param v  Down the texture, 0 to 1.
		@param color  Its color, RGBA, 0 to 255 each. */
	public function vertex(texture:Int, x:Float, y:Float, u:Float, v:Float, color:helix.ray.Color):Void {
		var n = runs.length;
		if (n == 0 || runs[n - 3] != texture) {
			runs.push(texture);
			runs.push(vertices);
			runs.push(0);
		}
		runs[runs.length - 1]++;
		var at = vertices * STRIDE;
		if (at + STRIDE > data.length) {
			var grown = Bytes.alloc(data.length * 2);
			grown.blit(0, data, 0, at);
			data = grown;
		}
		data.setFloat(at, x);
		data.setFloat(at + 4, y);
		data.setFloat(at + 8, u);
		data.setFloat(at + 12, v);
		data.setFloat(at + 16, color.r / 255);
		data.setFloat(at + 20, color.g / 255);
		data.setFloat(at + 24, color.b / 255);
		data.setFloat(at + 28, color.a / 255);
		vertices++;
	}

	/** Uploads what was collected, inside the frame's screen pass and before `draw`. */
	public function upload():Void {
		if (vertices == 0)
			return;
		var bytes = vertices * STRIDE;
		if (bytes > capacity) {
			if (buffer != 0)
				graphics.disposeBuffer(buffer);
			capacity = data.length;
			buffer = graphics.createBuffer(capacity);
		}
		graphics.updateBuffer(buffer, data, bytes);
	}

	/** Draws what was uploaded, inside the frame's screen pass.

		@param width  The screen's width, in the pixels positions are in.
		@param height  The screen's height. */
	public function draw(width:Float, height:Float):Void {
		if (vertices == 0)
			return;
		screen.setFloat(0, width);
		screen.setFloat(4, height);
		var i = 0;
		while (i < runs.length) {
			var count = runs[i + 2] - runs[i + 2] % 3;
			if (count > 0)
				graphics.draw(pipeline, [buffer], 0, runs[i + 1], count, 0, 1, [runs[i]], [sampling], [screen]);
			i += 3;
		}
	}

	/** Frees the program, the pipeline, the buffer and the white texture. */
	public function dispose():Void {
		if (buffer != 0)
			graphics.disposeBuffer(buffer);
		graphics.disposeTexture(white);
		graphics.disposePipeline(pipeline);
		graphics.disposeShader(shader);
	}
}
