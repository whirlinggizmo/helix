import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.VertexBuffer;
import helix.platform.VertexFormat;
import helix.platform.IWindow;
import helix.platform.Sampling;
import helix.platform.tools.ShaderCompiler;

/** Represents one case: what it draws, what it reads back and what it expects there. */
typedef Case = {
	/** The case's name, in a failure's message. */
	final name:String;

	/** Draws its target passes, before the frame. */
	final ?before:() -> Void;

	/** The screen's clear color. */
	final ?clear:Int;

	/** Draws in the screen's pass, given its size. */
	final ?screen:(width:Int, height:Int) -> Void;

	/** The texture or render target read back; 0 for the screen. */
	final target:Int;

	/** Checks the pixels read back. */
	final check:Pixels->Void;
}

/** Checks helix-platform's graphics on the GPU, with the library alone: each case draws, reads the result back with `readPixels` and checks
	its pixels against what arithmetic says they are.

	The cases: points a pixel each, unindexed and by index, and refused over a program without the point size; a clear, a triangle's
	colors interpolated, eight vertex buffers read and a ninth refused, each vertex format read (a signed 0 as 0, fewer and more components
	than the input, formats mixed in one record, instances from the second), layouts with a gap of slots and layouts the platform refuses, a texture sampled nearest and linear, uniform blocks in both stages, alpha and
	additive blending, each blend factor and operation and a color write mask, a texture's rectangles replaced, and replaced
	between passes, targets kept from pass to pass and frame to frame (their depth and samples too) and one never cleared, targets'
	multisampling chosen apart from their depth (one sample with depth, the screen's, no depth and the most, a count rounded down
	to the most and a negative one refused) on a window asking for 4 samples, textures read
	back, instances placed by a mat4 vertex input, mipmaps under each mipmap filter, a render target drawn to the screen, viewport and scissor in a target and on the screen, a data texture's floats read
	texel by texel, a cubemap's six faces, declared textures left unbound reading clear, and, in a page, the context lost and given back:
	frames taken while it is lost, then a texture and a buffer made again drawn into a render target the adapter remade, and that to the
	screen. The shaders are `shaders/*.vert` and `*.frag`,
	compiled by the build, so it checks the shader compiler's dialects too. One case runs a frame; on a GPU that reads back later, the next
	waits for it.

	Built from the hxml files beside it: in a page it runs on WebGL2, natively on GL, or SDL_GPU with `-D sdl_gpu`. It ends with
	`{passed, checks, failures}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null until then.
	Run by `tools/platform_checks.py`. */
class GraphicsTests {
	// The render targets' size, in texels.
	static inline final SIZE = 16;
	// How many frames a read back may take before the case fails.
	static inline final READ_FRAMES = 60;

	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var cases:Array<Case>;
	static var next = 0;
	static var waiting = 0;
	static var checks = 0;
	static var failures:Array<String> = [];
	static var current = "";
	// What setup made, disposed by dispose.
	static var shaders:Array<Int> = [];
	static var pipelines:Array<Int> = [];
	static var buffers:Array<Int> = [];
	static var textures:Array<Int> = [];
	// Of those, the ones a lost context leaves (render targets, data textures, stream buffers): the rest are gone at the restore.
	static var surviving:Array<Int> = [];
	// The lost context case: 0 none, 1 asked for, 2 lost, 3 given back; the frames since it was asked for; what a call threw meanwhile.
	static var losing = 0;
	static var lostFrames = 0;
	static var lostThrew:Null<String> = null;
	static var loseExtension:Dynamic = null;

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas", msaaSampleCount: 4});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		#if sdl_gpu
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gpu, msaaSampleCount: 4});
		graphics = new helix.platform.adapters.graphics.sdl3gpu.Sdl3GpuGraphicsAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl, msaaSampleCount: 4});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		#end
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		setup();
		while (tick()) {}
		finish();
		#end
	}

	/** Runs one frame: the next case, or an empty frame while a read back is awaited. False once every case has been read. */
	static function tick():Bool {
		events.poll();
		for (event in events.events)
			switch event {
				case GraphicsLost if (losing == 1):
					losing = 2;
				case GraphicsRestored if (losing == 2):
					losing = 3;
				case CloseRequested | GraphicsLost | GraphicsRestored:
					fail('stopped by $event, ${cases.length - next} cases not run');
					return false;
				case _:
			}
		var width = window.framebufferWidth, height = window.framebufferHeight;
		if (losing == 1 || losing == 2) {
			// Frames while the context is lost: every call taken, drawing nothing; the context asked back after 30 of them.
			if (++lostFrames > READ_FRAMES * 4) {
				fail('the context never came back');
				return false;
			}
			try {
				graphics.beginFrame(width, height, 0xff000000);
				graphics.endFrame();
				graphics.present();
			} catch (error:Dynamic)
				lostThrew = Std.string(error);
			if (losing == 2 && lostFrames == 30)
				loseExtension.restoreContext();
			return true;
		}
		if (losing == 3) {
			// Given back: the textures and static buffers made before are gone, not to be disposed.
			losing = 0;
			textures = textures.filter(t -> surviving.indexOf(t) >= 0);
			buffers = buffers.filter(b -> surviving.indexOf(b) >= 0);
		}
		if (waiting > 0) {
			if (++waiting > READ_FRAMES) {
				fail('no read back after $READ_FRAMES frames');
				return false;
			}
			graphics.beginFrame(width, height, 0xff000000);
			graphics.endFrame();
			graphics.present();
			return true;
		}
		if (next == cases.length)
			return false;
		var c = cases[next++];
		current = c.name;
		waiting = 1;
		try {
			if (c.before != null)
				c.before();
			if (losing == 1) {
				// The case that loses the context: nothing drawn or read this frame.
				waiting = 0;
				return true;
			}
			graphics.beginFrame(width, height, c.clear == null ? 0xff000000 : c.clear);
			if (c.screen != null)
				c.screen(width, height);
			graphics.endFrame();
			graphics.readPixels(c.target, (pixels, w, h) -> {
				waiting = 0;
				current = c.name;
				c.check(new Pixels(pixels, w, h));
			}, why -> {
				waiting = 0;
				current = c.name;
				fail('not read back: $why');
			});
		} catch (error:Dynamic) {
			waiting = 0;
			fail('threw: $error');
		}
		graphics.present();
		return true;
	}

	/** Records a check's outcome. */
	public static function check(value:Bool, message:String):Void {
		checks++;
		if (!value)
			fail(message);
	}

	static function fail(message:String):Void
		failures.push('$current: $message');

	/** Makes the programs, pipelines, buffers and textures, and the cases over them. */
	static function setup():Void {
		window.title = "helix-platform: graphics tests";
		var color = shader(ShaderCompiler.compile("shaders/color.vert", "shaders/color.frag"));
		var texture = shader(ShaderCompiler.compile("shaders/texture.vert", "shaders/texture.frag"));
		var data = shader(ShaderCompiler.compile("shaders/texture.vert", "shaders/data.frag"));
		var cube = shader(ShaderCompiler.compile("shaders/texture.vert", "shaders/cube.frag"));
		var tint = shader(ShaderCompiler.compile("shaders/offset.vert", "shaders/tint.frag"));
		var eight = shader(ShaderCompiler.compile("shaders/eight.vert", "shaders/color.frag"));
		var matrices = shader(ShaderCompiler.compile("shaders/instanced.vert", "shaders/color.frag"));
		var pointProgram = shader(ShaderCompiler.compile("shaders/color.vert", "shaders/color.frag", {points: true}));
		var signed = shader(ShaderCompiler.compile("shaders/signed.vert", "shaders/color.frag"));
		var zero = shader(ShaderCompiler.compile("shaders/zero.vert", "shaders/color.frag"));
		var three = shader(ShaderCompiler.compile("shaders/three.vert", "shaders/color.frag"));
		var mixed = shader(ShaderCompiler.compile("shaders/mixed.vert", "shaders/color.frag"));
		var integer = shader(ShaderCompiler.compile("shaders/integer.vert", "shaders/color.frag"));
		var gap = shader(ShaderCompiler.compile("shaders/gap.vert", "shaders/color.frag"));
		var sharedSource = ShaderCompiler.compile("shaders/shared.vert", "shaders/shared.frag");
		var sharing = shader(sharedSource);

		// Vertex layouts: a position and a color (24 bytes), a position and a texture coordinate (16), a position (8).
		var colored:VertexBuffer = {
			stride: 24,
			instanced: false,
			attributes: [
				{slot: 0, format: Float2, offset: 0},
				{
					slot: 1,
					format: Float4,
					offset: 8
				}
			]
		};
		var textured:VertexBuffer = {
			stride: 16,
			instanced: false,
			attributes: [
				{slot: 0, format: Float2, offset: 0},
				{
					slot: 1,
					format: Float2,
					offset: 8
				}
			]
		};
		var plain:VertexBuffer = {stride: 8, instanced: false, attributes: [{slot: 0, format: Float2, offset: 0}]};
		var opaque = pipeline(color, colored, Blend.OPAQUE),
			alpha = pipeline(color, colored, Blend.ALPHA),
			additive = pipeline(color, colored, Blend.ADDITIVE);
		var sampled = pipeline(texture, textured, Blend.OPAQUE),
			fetched = pipeline(data, textured, Blend.OPAQUE),
			looked = pipeline(cube, textured, Blend.OPAQUE);
		var tinted = pipeline(tint, plain, Blend.OPAQUE);
		// The shared block's program, flipped through block 0's second vec4 (its first is another value, left as it is).
		var shared = graphics.createPipeline({
			shader: sharing,
			buffers: [plain],
			primitive: Triangles,
			indexed: false,
			blend: Blend.OPAQUE,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale,
			flipBlockSlot: 0,
			flipOffset: 16
		});
		pipelines.push(shared);
		// The colored program with its color unfed: read as a constant, or as (0, 0, 0, 1) where none is given.
		var constant = graphics.createPipeline({
			shader: color,
			buffers: [plain],
			primitive: Triangles,
			indexed: false,
			blend: Blend.OPAQUE,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale,
			attributeConstants: [
				{
					slot: 1,
					values: [0, 1]
				}
			]
		});
		pipelines.push(constant);
		var unfed = pipeline(color, plain, Blend.OPAQUE);
		// Layouts with a gap of slots: a position and a color at slots 0 and 2, the tint at 1 between them read as its constant, or as
		// (0, 0, 0, 1) where none is given.
		function gapped(?constants:Array<{slot:Int, values:Array<Float>}>):Int {
			var handle = graphics.createPipeline({
				shader: gap,
				buffers: [
					{
						stride: 24,
						instanced: false,
						attributes: [{slot: 0, format: Float2, offset: 0}, {slot: 2, format: Float4, offset: 8}]
					}
				],
				primitive: Triangles,
				indexed: false,
				blend: Blend.OPAQUE,
				depthTest: Off,
				depthWrite: false,
				cull: None,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale,
				attributeConstants: constants
			});
			pipelines.push(handle);
			return handle;
		}
		var tintedGap = gapped([{slot: 1, values: [0, 1, .5, 1]}]),
			blackGap = gapped();
		// Instances of a square, each placed by a matrix (slots 1 to 4) and colored (slot 5), from one instanced buffer.
		var placed = graphics.createPipeline({
			shader: matrices,
			buffers: [
				plain,
				{
					stride: 80,
					instanced: true,
					attributes: [for (column in 0...5) {slot: column + 1, format: Float4, offset: column * 16}]
				}
			],
			primitive: Triangles,
			indexed: false,
			blend: Blend.OPAQUE,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale
		});
		pipelines.push(placed);
		// The same, testing and writing depth.
		var deep = graphics.createPipeline({
			shader: tint,
			buffers: [plain],
			primitive: Triangles,
			indexed: false,
			blend: Blend.OPAQUE,
			depthTest: LessEqual,
			depthWrite: true,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale
		});
		pipelines.push(deep);
		// Each blend over the target's (.25, .5, .75, .25) with (1, .5, 0, .5), and what it leaves there, red, green, blue and alpha.
		var blends:Array<{blend:Blend, expected:Array<Float>}> = [
			{blend: new Blend(DestinationColor, OneMinusSourceAlpha), expected: [.375, .5, .375, .25]},
			{blend: new Blend(One, One), expected: [1, 1, .75, .75]},
			{blend: new Blend(One, One, Subtract), expected: [.75, 0, 0, .25]},
			{blend: new Blend(One, One, ReverseSubtract), expected: [0, 0, .75, 0]},
			{blend: new Blend(One, One, Min), expected: [.25, .5, 0, .25]},
			{blend: new Blend(One, One, Max), expected: [1, .5, .75, .5]},
			{blend: new Blend(SourceAlpha, OneMinusSourceAlpha, Add, Zero, One), expected: [.625, .5, .375, .25]},
			// The same factors for alpha as for the color: alpha * alpha + the target's * (1 - alpha).
			{blend: new Blend(SourceAlpha, OneMinusSourceAlpha), expected: [.625, .5, .375, .375]}
		];
		var blended = [for (b in blends) pipeline(color, colored, b.blend)];
		var masked = pipeline(color, colored, Blend.OPAQUE, Red | Alpha),
			saturated = pipeline(color, colored, new Blend(SourceAlphaSaturated, One));
		// Eight buffers, the most a pipeline reads: a position, then a number from each of seven; a ninth is refused.
		var single:Array<VertexBuffer> = [
			for (slot in 1...9)
				{stride: 4, instanced: false, attributes: [{slot: slot, format: Float1, offset: 0}]}
		];
		function many(layouts:Array<VertexBuffer>):Int
			return graphics.createPipeline({
				shader: eight,
				buffers: layouts,
				primitive: Triangles,
				indexed: false,
				blend: Blend.OPAQUE,
				depthTest: Off,
				depthWrite: false,
				cull: None,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale
			});
		var eightBuffers = many([plain].concat(single.slice(0, 7)));
		pipelines.push(eightBuffers);
		var nineRefused = try {
			pipelines.push(many([plain].concat(single)));
			false;
		} catch (e:Dynamic)
			true;

		// The vertex formats: a position from one buffer and a value at slot 1 from another, its format's bytes a record; a layout of two
		// buffers, or refused.
		function formatted(program:Int, layouts:Array<VertexBuffer>):Int {
			var handle = graphics.createPipeline({
				shader: program,
				buffers: layouts,
				primitive: Triangles,
				indexed: false,
				blend: Blend.OPAQUE,
				depthTest: Off,
				depthWrite: false,
				cull: None,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale
			});
			pipelines.push(handle);
			return handle;
		}
		function fed(program:Int, format:VertexFormat):Int
			return formatted(program, [
				plain,
				{stride: format.bytes, instanced: false, attributes: [{slot: 1, format: format, offset: 0}]}
			]);
		function refused(program:Int, layout:VertexBuffer):Bool
			return try {
				formatted(program, [plain, layout]);
				false;
			} catch (e:Dynamic)
				true;
		var refusals = [
			"an offset not a multiple of 4" => refused(color, {stride: 8, instanced: false, attributes: [{slot: 1, format: Float1, offset: 2}]}),
			"a stride not a multiple of 4" => refused(color, {stride: 10, instanced: false, attributes: [{slot: 1, format: Float2, offset: 0}]}),
			"a stride over 255" => refused(color, {stride: 256, instanced: false, attributes: [{slot: 1, format: Float4, offset: 0}]}),
			"a format's bytes past the stride" => refused(color, {stride: 8, instanced: false, attributes: [{slot: 1, format: UShort4Norm, offset: 4}]}),
			"a number no format has" => refused(color, {stride: 16, instanced: false, attributes: [{slot: 1, format: cast 12, offset: 0}]}),
			"a format into an ivec4 input" => refused(integer, {stride: 4, instanced: false, attributes: [{slot: 1, format: UByte4Norm, offset: 0}]})
		];
		var widest = !refused(color, {stride: 252, instanced: false, attributes: [{slot: 1, format: Float4, offset: 236}]});
		var unsignedBytes = fed(color, UByte4Norm),
			signedBytes = fed(signed, Byte4Norm),
			unsignedShorts2 = fed(color, UShort2Norm),
			signedShorts2 = fed(signed, Short2Norm),
			unsignedShorts4 = fed(color, UShort4Norm),
			signedShorts4 = fed(signed, Short4Norm),
			zeroBytes = fed(zero, Byte4Norm),
			zeroShorts = fed(zero, Short2Norm),
			threeBytes = fed(three, Byte4Norm),
			oneFloat = fed(color, Float1),
			threeFloats = fed(color, Float3),
			twoHalves = fed(color, Half2),
			fourHalves = fed(color, Half4);
		// One 16-byte record: a position as two floats, a color as four bytes, a texture coordinate as two shorts.
		var interleaved = formatted(mixed, [
			{
				stride: 16,
				instanced: false,
				attributes: [
					{slot: 0, format: Float2, offset: 0},
					{slot: 1, format: UByte4Norm, offset: 8},
					{slot: 2, format: UShort2Norm, offset: 12}
				]
			}
		]);
		// Instances placed by a matrix (slots 1 to 4) from one instanced buffer and colored (slot 5) as bytes from another.
		var byteInstances = formatted(matrices, [
			plain,
			{
				stride: 64,
				instanced: true,
				attributes: [for (column in 0...4) {slot: column + 1, format: Float4, offset: column * 16}]
			},
			{stride: 4, instanced: true, attributes: [{slot: 5, format: UByte4Norm, offset: 0}]}
		]);

		// Points, unindexed and indexed, through the points program; culling asked for, which points ignore. Over a program compiled
		// without the point size, refused.
		function points(indexed:Bool):Int {
			var handle = graphics.createPipeline({
				shader: pointProgram,
				buffers: [colored],
				primitive: Points,
				indexed: indexed,
				blend: Blend.OPAQUE,
				depthTest: Off,
				depthWrite: false,
				cull: Back,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale
			});
			pipelines.push(handle);
			return handle;
		}
		var dotted = points(false), dottedIndexed = points(true);
		var pointsRefused = try {
			pipelines.push(graphics.createPipeline({
				shader: color,
				buffers: [colored],
				primitive: Points,
				indexed: false,
				blend: Blend.OPAQUE,
				depthTest: Off,
				depthWrite: false,
				cull: None,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale
			}));
			false;
		} catch (e:Dynamic)
			true;

		// Clip space's square as two triangles; a texture coordinate's v runs down, as a texture's rows do.
		var square = [-1., -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1];
		function quad(r:Float, g:Float, b:Float, a:Float):Int {
			var values = [];
			for (i in 0...6)
				values = values.concat([square[i * 2], square[i * 2 + 1], r, g, b, a]);
			return buffer(values);
		}
		var white = quad(1, 1, 1, 1),
			red = quad(1, 0, 0, 1),
			halfRed = quad(1, 0, 0, .5),
			halfOrange = quad(1, .5, 0, .5);
		var uvSquare = [];
		for (i in 0...6)
			uvSquare = uvSquare.concat([
				square[i * 2],
				square[i * 2 + 1],
				(square[i * 2] + 1) / 2,
				(1 - square[i * 2 + 1]) / 2
			]);
		var uvQuad = buffer(uvSquare);
		// Half the square, centered on the origin, for block 1 to move.
		var half = buffer([for (v in square) v / 2]);
		// One triangle over the whole square: red at (-1, -1), green at (3, -1), blue at (-1, 3).
		var triangle = buffer([-1., -1, 1, 0, 0, 1, 3, -1, 0, 1, 0, 1, -1, 3, 0, 0, 1, 1]);
		// A red triangle whose long edge slants across texels, partly covering those it crosses.
		var slanted = buffer([-1., -1, 1, 0, 0, 1, 1, -1, 1, 0, 0, 1, -1, .37, 1, 0, 0, 1]);

		var positions = buffer(square);
		// Three instances: a matrix moving half the square to a quarter, column by column, then a color: red top left, green bottom right,
		// blue top right.
		function instance(x:Float, y:Float, color:Array<Float>):Array<Float>
			return [.5, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1, 0, x, y, 0, 1].concat(color);
		var instances = buffer(instance(-.5, .5, [1, 0, 0, 1]).concat(instance(.5, -.5, [0, 1, 0, 1])).concat(instance(.5, .5, [0, 0, 1, 1])));
		var numbers = [for (value in [.25, .25, .5, .25, .125, .5, 1]) buffer([for (_ in 0...6) value])];
		// A value for each of the square's six vertices, as bytes, as 16-bit integers (or half floats' bits), or as floats.
		function bytesFed(values:Array<Int>):Int {
			var record = Bytes.alloc(values.length);
			for (i => v in values)
				record.set(i, v);
			return repeated(record);
		}
		function shortsFed(values:Array<Int>):Int {
			var record = Bytes.alloc(values.length * 2);
			for (i => v in values)
				record.setUInt16(i * 2, v & 0xffff);
			return repeated(record);
		}
		function floatsFed(values:Array<Float>):Int
			return repeated(floatBytes(values));
		var mixedRecords = Bytes.alloc(16 * 6);
		for (i in 0...6) {
			mixedRecords.setFloat(i * 16, square[i * 2]);
			mixedRecords.setFloat(i * 16 + 4, square[i * 2 + 1]);
			for (k => v in [255, 102, 0, 255])
				mixedRecords.set(i * 16 + 8 + k, v);
			mixedRecords.setUInt16(i * 16 + 12, 13107);
			mixedRecords.setUInt16(i * 16 + 14, 65535);
		}
		var mixedBuffer = graphics.createStaticBuffer(mixedRecords, mixedRecords.length, false);
		buffers.push(mixedBuffer);
		var placements = buffer([
			for (at in [[-.5, .5], [.5, -.5], [.5, .5]])
				for (v in [.5, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1, 0, at[0], at[1], 0, 1])
					v
		]);
		var instanceColors = Bytes.alloc(12);
		for (i => v in [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255])
			instanceColors.set(i, v);
		var instanceColorBuffer = graphics.createStaticBuffer(instanceColors, 12, false);
		buffers.push(instanceColorBuffer);

		// Single-sampled, so the cases' edges fall on whole texels.
		var target = graphics.createRenderTarget(SIZE, SIZE, Rgba8, false, 1),
			second = graphics.createRenderTarget(SIZE, SIZE, Rgba8, false, 1);
		// With depth, multisampled as the screen is, kept from one frame to the next; and one never cleared.
		var kept = graphics.createRenderTarget(SIZE, SIZE),
			fresh = graphics.createRenderTarget(SIZE, SIZE, Rgba8, false, 1);
		for (t in [target, second, kept, fresh]) {
			textures.push(t);
			surviving.push(t);
		}
		// Multisampling chosen apart from depth: depth and one sample (raylib's render textures), depth and the screen's samples, no depth
		// and the most the format takes, and far more than any GPU takes, rounded down to that most.
		var most = graphics.getMaxRenderTargetMsaaSampleCount(Rgba8);
		var singleDepth = graphics.createRenderTarget(SIZE, SIZE, Rgba8, true, 1),
			screenDepth = graphics.createRenderTarget(SIZE, SIZE, Rgba8, true),
			mostFlat = graphics.createRenderTarget(SIZE, SIZE, Rgba8, false, most),
			clamped = graphics.createRenderTarget(SIZE, SIZE, Rgba8, false, 1000);
		for (t in [singleDepth, screenDepth, mostFlat, clamped]) {
			textures.push(t);
			surviving.push(t);
		}
		var mostHalf = graphics.getMaxRenderTargetMsaaSampleCount(Rgba16f);
		if (graphics.canRender(Rgba16f)) {
			var halfTarget = graphics.createRenderTarget(SIZE, SIZE, Rgba16f, true, 1000);
			textures.push(halfTarget);
			surviving.push(halfTarget);
		}
		var negativeRefused = try {
			textures.push(graphics.createRenderTarget(SIZE, SIZE, Rgba8, true, -1));
			false;
		} catch (_:Dynamic)
			true;
		// 4 x 4, red, its rectangles replaced by the cases; and 2 x 1 of half floats.
		var patched = texture2D(4, 4, [for (_ in 0...16) 0xff0000ff]);
		var halves = Bytes.alloc(16);
		for (i in 0...8)
			halves.setUInt16(i * 2, 0x3c00);
		var halfTexture = graphics.createTexture(2, 1, [halves], Rgba16f);
		textures.push(halfTexture);
		// 8 x 8 with its mipmaps, each level one color: red, green, blue, white.
		var levels = [
			for (i => rgba in [0xff0000ff, 0x00ff00ff, 0x0000ffff, 0xffffffff])
				rgbaTexels([for (_ in 0...(64 >> (i * 2))) rgba])
		];
		var mipmapped = graphics.createTexture(8, 8, levels);
		textures.push(mipmapped);
		// 2 x 2, rows top first: red, green, then blue, white.
		var checker = texture2D(2, 2, [0xff0000ff, 0x00ff00ff, 0x0000ffff, 0xffffffff]);
		// One texel a face: +X red, -X green, +Y blue, -Y yellow, +Z magenta, -Z cyan.
		var faces = Bytes.alloc(24);
		for (i => rgba in [0xff0000ff, 0x00ff00ff, 0x0000ffff, 0xffff00ff, 0xff00ffff, 0x00ffffff])
			faces.setInt32(i * 4, rgbaBytes(rgba));
		var sky = graphics.createCubeTexture(1, [faces], Rgba8);
		textures.push(sky);
		// Floats beyond 0 to 1, which only a float texture keeps.
		var table = graphics.createDataTexture(4, 1);
		textures.push(table);
		surviving.push(table);
		var floats = [1., -.25, .5, 0, 3, -.5, .25, 0, 5, -.75, 1, 0, 7, 0, 0, 0];
		graphics.updateTexture(table, 0, 0, 4, 1, floatBytes(floats));

		var clip = floatBytes([1, 1, 0, 0]);
		function fedDraw(pipeline:Int, values:Int):Void
			graphics.draw(pipeline, [positions, values], null, 0, 0, 6, 0, 1, [], [], [clip]);
		// The shared block's bytes, each member written at the place the reflection gives it.
		var sharedBlock = Lambda.find(sharedSource.uniformBlocks, b -> b.glslName == "Shared");
		var sharedBytes = Bytes.alloc(sharedBlock.size);
		function put(path:String, element:Int, values:Array<Float>, integer:Bool):Void {
			var m = Lambda.find(sharedBlock.members, m -> m.glslName == path);
			if (m == null)
				throw 'the shared block has no $path';
			for (i => v in values) {
				// A matrix's column is 16 bytes, its rows floats in it.
				var at = m.offset + element * m.stride + (m.type == "mat3" ? Std.int(i / 3) * 16 + (i % 3) * 4 : i * 4);
				if (integer)
					sharedBytes.setInt32(at, Std.int(v));
				else
					sharedBytes.setFloat(at, v);
			}
		}
		put("scale", 0, [1, 1, 0, 0], false);
		put("lights.color", 0, [1, 1, 1], false);
		put("lights.color", 1, [.25, 0, 0], false);
		put("lights.color", 2, [1, 1, 1], false);
		put("lights.on", 1, [1], true);
		put("pick", 0, [1], true);
		put("bright", 0, [1], true);
		put("mask", 0, [3], true);
		put("weights", 2, [1], false);
		put("turn", 0, [0, 0, 0, 0, 0, .75, 0, 0, 0], false);
		var sharedVertexBlock = floatBytes([7, 7, 7, 7, 0, 0, 0, 0]);
		function draw(pipeline:Int, buffer:Int, count:Int, ?textures:Array<Int>, ?samplings:Array<Sampling>, ?uniforms:Array<Null<Bytes>>):Void
			graphics.draw(pipeline, [buffer], null, 0, 0, count, 0, 1, textures == null ? [] : textures, samplings == null ? [] : samplings,
				uniforms == null ? [clip] : uniforms);
		function into(r:Float, g:Float, b:Float, a:Float, draws:() -> Void):() -> Void
			return () -> {
				graphics.beginTargetPass(target, r, g, b, a);
				draws();
				graphics.endTargetPass();
			};
		// A texel's center in clip space.
		function clipX(x:Int):Float
			return (x + .5) / SIZE * 2 - 1;
		function clipY(y:Int):Float
			return 1 - (y + .5) / SIZE * 2;
		// Five points at texels' centers, each a color: red, green, blue, white, yellow; and indices drawing the fourth and the first.
		var spots = [[2, 3], [13, 1], [7, 7], [0, 15], [15, 10]],
			spotColors = [[1., 0, 0], [0., 1, 0], [0., 0, 1], [1., 1, 1], [1., 1, 0]];
		var dotFloats = [
			for (i => s in spots)
				for (v in [clipX(s[0]), clipY(s[1])].concat(spotColors[i]).concat([1]))
					v
		];
		var dots = buffer(dotFloats);
		// A junk point (magenta, at 10, 12) and then the five, to be drawn from an offset of one point (24 bytes); and a junk instance (white,
		// at the center, which reaches 6, 10) and then the three instances, from an offset of one record (80 bytes).
		var dotsAfterJunk = buffer([clipX(10), clipY(12), 1, 0, 1, 1].concat(dotFloats));
		var instancesAfterJunk = buffer(instance(0, 0,
			[1, 1, 1, 1]).concat(instance(-.5, .5, [1, 0, 0, 1])).concat(instance(.5, -.5, [0, 1, 0, 1])).concat(instance(.5, .5, [0, 0, 1, 1])));
		// A stream buffer the five points are appended to, two and then three, each range drawn right after it is written.
		var appendedDots = graphics.createBuffer(dotFloats.length * 4);
		buffers.push(appendedDots);
		surviving.push(appendedDots);
		var dotIndices = Bytes.alloc(8);
		dotIndices.setInt32(0, 3);
		dotIndices.setInt32(4, 0);
		var dotIndexBuffer = graphics.createStaticBuffer(dotIndices, 8, true);
		buffers.push(dotIndexBuffer);
		// The texel a point at s lights, and none of its neighbors.
		function expectSpot(p:Pixels, s:Array<Int>, color:Array<Float>):Void {
			p.expect(s[0], s[1], color, 0);
			for (d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
				var x = s[0] + d[0], y = s[1] + d[1];
				if (x >= 0 && x < SIZE && y >= 0 && y < SIZE)
					p.expect(x, y, [0, 0, 0, 1], 0);
			}
		}
		// The 2 x 2 texture sampled linearly at a texel's center of the target, clamped to its edge.
		function bilinear(x:Int, y:Int):Array<Float> {
			var u = Math.min(Math.max((x + .5) / SIZE * 2 - .5, 0), 1),
				v = Math.min(Math.max((y + .5) / SIZE * 2 - .5, 0), 1);
			var top = [for (i in 0...3) [1., 0, 0][i] * (1 - u) + [0., 1, 0][i] * u];
			var bottom = [for (i in 0...3) [0., 0, 1][i] * (1 - u) + [1., 1, 1][i] * u];
			return [for (i in 0...3) top[i] * (1 - v) + bottom[i] * v];
		}

		// The slanted triangle drawn into a target over black, its edge texels partly red where the target is multisampled.
		function slantedCase(name:String, into:Int, multisampled:Bool):Case
			return {
				name: name,
				before: () -> {
					graphics.beginTargetPass(into, 0, 0, 0, 1);
					draw(opaque, slanted, 3);
					graphics.endTargetPass();
				},
				target: into,
				check: p -> checkEdge(p, multisampled)
			};

		cases = [
			{
				name: "points, a pixel each, five drawn",
				before: into(0, 0, 0, 1, () -> draw(dotted, dots, 5)),
				target: target,
				check: p -> {
					if (!pointsRefused)
						throw "points over a program without the point size: the pipeline was made";
					for (i => s in spots)
						expectSpot(p, s, spotColors[i].concat([1]));
				}
			},
			{
				name: "points by index",
				before: into(0, 0, 0, 1, () -> graphics.draw(dottedIndexed, [dots], null, dotIndexBuffer, 0, 2, 0, 1, [], [], [clip])),
				target: target,
				check: p -> {
					expectSpot(p, spots[3], [1, 1, 1, 1]);
					expectSpot(p, spots[0], [1, 0, 0, 1]);
					for (s in [spots[1], spots[2], spots[4]])
						p.expect(s[0], s[1], [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a target cleared",
				before: into(.25, .5, .75, 1, () -> {}),
				target: target,
				check: p -> for (at in [[0, 0], [15, 0], [0, 15], [15, 15], [8, 8]])
					p.expect(at[0], at[1], [.25, .5, .75, 1], 1)
			},
			{
				name: "the screen cleared",
				clear: 0xff336699,
				target: 0,
				check: p -> for (at in [
					[0, 0],
					[p.width - 1, 0],
					[0, p.height - 1],
					[p.width - 1, p.height - 1],
					[p.width >> 1, p.height >> 1]
				])
					p.expect(at[0], at[1], [0x33 / 255, 0x66 / 255, 0x99 / 255], 0)
			},
			{
				name: "a triangle's colors interpolated",
				before: into(0, 0, 0, 0, () -> draw(opaque, triangle, 3)),
				target: target,
				// Green grows along x and blue along y, each a quarter a unit; red is what's left. Row 0 is the top: blue's side.
				check: p -> for (at in [[0, 0], [5, 10], [10, 3], [15, 15], [8, 8], [15, 0]]) {
					var green = (clipX(at[0]) + 1) / 4,
						blue = (clipY(at[1]) + 1) / 4;
					p.expect(at[0], at[1], [1 - green - blue, green, blue, 1], 2);
				}
			},
			{
				name: "eight buffers read, a ninth refused",
				before: into(0, 0, 0, 0, () -> graphics.draw(eightBuffers, [positions].concat(numbers), null, 0, 0, 6, 0, 1, [], [], [clip])),
				target: target,
				check: p -> {
					if (!nineRefused)
						throw "eight buffers read, a ninth refused: a pipeline of nine was made";
					for (at in [[0, 0], [8, 8], [15, 15]])
						p.expect(at[0], at[1], [.5, .75, .625, 1], 1);
				}
			},
			{
				name: "UByte4Norm read as each byte over 255",
				before: into(0, 0, 0, 0, () -> fedDraw(unsignedBytes, bytesFed([0, 128, 255, 64]))),
				target: target,
				check: p -> {
					for (name => refusedIt in refusals)
						check(refusedIt, '$name: the pipeline was made');
					check(widest, "a stride of 252, a Float4 at 236: refused");
					for (at in [[0, 0], [8, 8], [15, 15]])
						p.expect(at[0], at[1], [0, 128 / 255, 1, 64 / 255], 0);
				}
			},
			{
				name: "Byte4Norm read as each byte over 127, -128 as -1",
				before: into(0, 0, 0, 0, () -> fedDraw(signedBytes, bytesFed([128, 129, 0, 127]))),
				target: target,
				check: p -> p.expect(8, 8, [0, 0, .5, 1], 1)
			},
			{
				name: "UShort2Norm into a vec4 reads (x, y, 0, 1)",
				before: into(1, 1, 1, 0, () -> fedDraw(unsignedShorts2, shortsFed([13107, 65535]))),
				target: target,
				check: p -> p.expect(8, 8, [.2, 1, 0, 1], 1)
			},
			{
				name: "Short2Norm read as each over 32767, -32768 as -1",
				before: into(0, 0, 0, 0, () -> fedDraw(signedShorts2, shortsFed([-32768, 32767]))),
				target: target,
				// (-1, 1, 0, 1) halved and raised by a half.
				check: p -> p.expect(8, 8, [0, 1, .5, 1], 1)
			},
			{
				name: "UShort4Norm read as each over 65535",
				before: into(0, 0, 0, 0, () -> fedDraw(unsignedShorts4, shortsFed([0, 21845, 65535, 32768]))),
				target: target,
				check: p -> p.expect(8, 8, [0, 1 / 3, 1, .5], 1)
			},
			{
				name: "Short4Norm read as each over 32767",
				before: into(0, 0, 0, 0, () -> fedDraw(signedShorts4, shortsFed([-32768, -16384, 16384, 32767]))),
				target: target,
				check: p -> p.expect(8, 8, [0, (1 - 16384 / 32767) / 2, (1 + 16384 / 32767) / 2, 1], 1)
			},
			{
				name: "a signed normalized 0 reads 0",
				// Left, Byte4Norm zeros; right, Short2Norm zeros, read as (0, 0, 0, 1): each component 1 where it reads 0.
				before: into(.5, .5, .5, .5, () -> {
					graphics.applyViewport(0, 0, 8, SIZE);
					fedDraw(zeroBytes, bytesFed([0, 0, 0, 0]));
					graphics.applyViewport(8, 0, 8, SIZE);
					fedDraw(zeroShorts, shortsFed([0, 0]));
				}),
				target: target,
				check: p -> {
					p.expect(3, 8, [1, 1, 1, 1], 0);
					p.expect(12, 8, [1, 1, 1, 0], 0);
				}
			},
			{
				name: "Byte4Norm into a vec3 reads its first three",
				before: into(0, 0, 0, 0, () -> fedDraw(threeBytes, bytesFed([129, 0, 127, 50]))),
				target: target,
				check: p -> p.expect(8, 8, [0, .5, 1, 1], 1)
			},
			{
				name: "Float1, Float3, Half2 and Half4 into a vec4",
				// A column of four texels each: (.5, 0, 0, 1); (.25, .5, .75, 1); (.75, .25, 0, 1); (1, .5, .25, .5).
				before: into(0, 0, 0, 0, () -> {
					graphics.applyViewport(0, 0, 4, SIZE);
					fedDraw(oneFloat, floatsFed([.5]));
					graphics.applyViewport(4, 0, 4, SIZE);
					fedDraw(threeFloats, floatsFed([.25, .5, .75]));
					graphics.applyViewport(8, 0, 4, SIZE);
					fedDraw(twoHalves, shortsFed([0x3a00, 0x3400]));
					graphics.applyViewport(12, 0, 4, SIZE);
					fedDraw(fourHalves, shortsFed([0x3c00, 0x3800, 0x3400, 0x3800]));
				}),
				target: target,
				check: p -> {
					p.expect(2, 8, [.5, 0, 0, 1], 1);
					p.expect(6, 8, [.25, .5, .75, 1], 1);
					p.expect(10, 8, [.75, .25, 0, 1], 1);
					p.expect(14, 8, [1, .5, .25, .5], 1);
				}
			},
			{
				name: "one interleaved record of Float2, UByte4Norm and UShort2Norm",
				before: into(0, 0, 0, 0, () -> graphics.draw(interleaved, [mixedBuffer], null, 0, 0, 6, 0, 1, [], [], [clip])),
				target: target,
				check: p -> for (at in [[0, 0], [8, 8], [15, 15]])
					p.expect(at[0], at[1], [1, .4, .2, 1], 1)
			},
			{
				name: "instances colored by UByte4Norm, from the second",
				// Of three instances, the second and third: green bottom right, blue top right; the first's top left stays clear.
				before: into(0, 0, 0, 1, () -> graphics.draw(byteInstances, [positions, placements, instanceColorBuffer], null, 0, 0, 6, 1, 2, [], [], [clip])),
				target: target,
				check: p -> {
					p.expect(4, 4, [0, 0, 0, 1], 0);
					p.expect(12, 12, [0, 1, 0, 1], 0);
					p.expect(12, 4, [0, 0, 1, 1], 0);
					p.expect(4, 12, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a texture sampled nearest",
				before: into(0, 0, 0, 0, () -> draw(sampled, uvQuad, 6, [checker], [Sampling.NEAREST])),
				target: target,
				check: p -> {
					p.expect(3, 3, [1, 0, 0, 1], 0);
					p.expect(7, 7, [1, 0, 0, 1], 0);
					p.expect(12, 3, [0, 1, 0, 1], 0);
					p.expect(3, 12, [0, 0, 1, 1], 0);
					p.expect(8, 8, [1, 1, 1, 1], 0);
					p.expect(12, 12, [1, 1, 1, 1], 0);
				}
			},
			{
				name: "a texture sampled linearly",
				before: into(0, 0, 0, 0, () -> draw(sampled, uvQuad, 6, [checker], [Sampling.LINEAR])),
				target: target,
				check: p -> for (at in [[0, 0], [7, 7], [8, 8], [5, 10], [15, 0], [10, 6]])
					p.expect(at[0], at[1], bilinear(at[0], at[1]).concat([1]), 3)
			},
			{
				name: "uniform blocks in both stages",
				// Half the square moved up and right by a quarter of the target: its top right quarter, in block 2's color.
				before: into(0, 0, 0, 1, () -> draw(tinted, half, 6, null, null, [
					clip,
					floatBytes([.5, .5, 0, 0]),
					null,
					null,
					null,
					null,
					floatBytes([.2, .4, .6, 1])
				])),
				target: target,
				check: p -> {
					p.expect(12, 3, [.2, .4, .6, 1], 1);
					p.expect(3, 3, [0, 0, 0, 1], 0);
					p.expect(12, 12, [0, 0, 0, 1], 0);
					p.expect(3, 12, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a block both stages read, of floats, integers, a bool, a struct array, a float array and a mat3",
				// Over the whole target, read back right way up through a flip at an offset; the block shared by both stages at slot 1,
				// passed at both its indices.
				before: into(0, 0, 0, 0, () -> draw(shared, positions, 6, null, null, [sharedVertexBlock, sharedBytes, null, null, null, sharedBytes])),
				target: target,
				check: p -> {
					p.expect(3, 3, [.5, .25, .75, 1], 1);
					p.expect(12, 12, [.5, .25, .75, 1], 1);
					if (sharedVertexBlock.getFloat(16) != 0 || sharedVertexBlock.getFloat(0) != 7)
						throw "a block's flip uniform was written into the caller's bytes";
				}
			},
			{
				name: "unfed attributes read their constants",
				// Left half: the color's constant, green; right half: none given, (0, 0, 0, 1).
				before: into(1, 0, 0, 1, () -> {
					graphics.applyViewport(0, 0, 8, SIZE);
					draw(constant, positions, 6);
					graphics.applyViewport(8, 0, 8, SIZE);
					draw(unfed, positions, 6);
				}),
				target: target,
				check: p -> {
					p.expect(3, 8, [0, 1, 0, 1], 0);
					p.expect(12, 8, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a layout with a gap of slots",
				// Left half: white tinted by the constant between its fed slots, green and half blue; right half: the tint given no
				// constant, (0, 0, 0, 1), black. Red where nothing drew.
				before: into(1, 0, 0, 1, () -> {
					graphics.applyViewport(0, 0, 8, SIZE);
					draw(tintedGap, white, 6);
					graphics.applyViewport(8, 0, 8, SIZE);
					draw(blackGap, white, 6);
				}),
				target: target,
				check: p -> {
					p.expect(3, 8, [0, 1, .5, 1], 1);
					p.expect(12, 8, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a draw sampling its own pass's target refused",
				before: into(0, 0, 1, 1, () -> {
					var refused = try {
						draw(sampled, uvQuad, 6, [target], [Sampling.NEAREST]);
						false;
					} catch (e:Dynamic)
						true;
					if (!refused)
						fail("a draw sampling the target it draws into was taken");
				}),
				target: target,
				check: p -> p.expect(8, 8, [0, 0, 1, 1], 0)
			},
			{
				name: "alpha and additive blending",
				// Half-transparent red over blue: blended by its alpha on the left, added by it on the right.
				before: into(0, 0, 1, 1, () -> {
					graphics.applyViewport(0, 0, SIZE >> 1, SIZE);
					draw(alpha, halfRed, 6);
					graphics.applyViewport(SIZE >> 1, 0, SIZE >> 1, SIZE);
					draw(additive, halfRed, 6);
				}),
				target: target,
				check: p -> {
					p.expect(3, 8, [.5, 0, .5], 1);
					p.expect(12, 8, [.5, 0, 1], 1);
				}
			},
			{
				name: "blend factors and operations",
				// Eight cells of 4 x 8, each a blend of half-transparent orange over the clear color; the first four on the bottom row.
				before: into(.25, .5, .75, .25, () -> for (i => p in blended) {
					graphics.applyViewport((i % 4) * 4, Std.int(i / 4) * 8, 4, 8);
					draw(p, halfOrange, 6);
				}),
				target: target,
				check: p -> for (i => b in blends)
					p.expect((i % 4) * 4 + 2, i < 4 ? 12 : 3, b.expected, 2)
			},
			{
				name: "the color write mask, and a saturated blend",
				// White written to red and alpha alone on the left; on the right, half-transparent orange times min(alpha, 1 - the target's).
				before: into(.25, .5, .75, .25, () -> {
					graphics.applyViewport(0, 0, SIZE >> 1, SIZE);
					draw(masked, white, 6);
					graphics.applyViewport(SIZE >> 1, 0, SIZE >> 1, SIZE);
					draw(saturated, halfOrange, 6);
				}),
				target: target,
				check: p -> {
					p.expect(3, 8, [1, .5, .75, 1], 1);
					p.expect(12, 8, [.75, .75, .75, .75], 2);
				}
			},
			{
				name: "a texture's rectangle replaced",
				// Rows 1 and 2 of columns 2 and 3 made green, then column 0's top two texels blue; the rest stays red.
				before: () -> {
					graphics.updateTexture(patched, 2, 1, 2, 2, rgbaTexels([0x00ff00ff, 0x00ff00ff, 0x00ff00ff, 0x00ff00ff]));
					graphics.updateTexture(patched, 0, 0, 1, 2, rgbaTexels([0x0000ffff, 0x0000ffff]));
					into(0, 0, 0, 0, () -> draw(sampled, uvQuad, 6, [patched], [Sampling.NEAREST]))();
				},
				target: target,
				// Each texel is 4 x 4 of the target.
				check: p -> {
					p.expect(10, 6, [0, 1, 0, 1], 0);
					p.expect(14, 10, [0, 1, 0, 1], 0);
					p.expect(2, 2, [0, 0, 1, 1], 0);
					p.expect(2, 6, [0, 0, 1, 1], 0);
					p.expect(2, 10, [1, 0, 0, 1], 0);
					p.expect(6, 2, [1, 0, 0, 1], 0);
					p.expect(10, 14, [1, 0, 0, 1], 0);
					p.expect(14, 2, [1, 0, 0, 1], 0);
				}
			},
			{
				name: "a texture replaced between passes",
				// Drawn white into the second target, then made yellow: the first target gets the second's copy on the left, the texture
				// on the right; half floats, a level of 0.5 and of 2, which the target holds as 1.
				before: () -> {
					graphics.updateTexture(patched, 0, 0, 4, 4, rgbaTexels([for (_ in 0...16) 0xffffffff]));
					graphics.beginTargetPass(second, 0, 0, 0, 0);
					draw(sampled, uvQuad, 6, [patched], [Sampling.NEAREST]);
					graphics.endTargetPass();
					graphics.updateTexture(patched, 0, 0, 4, 4, rgbaTexels([for (_ in 0...16) 0xffff00ff]));
					var half = Bytes.alloc(8);
					for (i => value in [0x3800, 0x4000, 0x3800, 0x3c00])
						half.setUInt16(i * 2, value);
					graphics.updateTexture(halfTexture, 1, 0, 1, 1, half);
					into(0, 0, 0, 0, () -> {
						graphics.applyViewport(0, 0, SIZE >> 1, SIZE);
						draw(sampled, uvQuad, 6, [second], [Sampling.NEAREST]);
						graphics.applyViewport(SIZE >> 1, 0, SIZE >> 2, SIZE);
						draw(sampled, uvQuad, 6, [patched], [Sampling.NEAREST]);
						graphics.applyViewport(SIZE * 3 >> 2, 0, SIZE >> 2, SIZE);
						draw(sampled, uvQuad, 6, [halfTexture], [Sampling.NEAREST]);
					})();
				},
				target: target,
				check: p -> {
					p.expect(4, 8, [1, 1, 1, 1], 0);
					p.expect(10, 8, [1, 1, 0, 1], 0);
					p.expect(12, 8, [1, 1, 1, 1], 1);
					p.expect(15, 8, [.5, 1, .5, 1], 1);
				}
			},
			{
				name: "a target kept from pass to pass",
				// Cleared to black with red on the left, then resumed, green drawn on the right.
				before: () -> {
					graphics.beginTargetPass(target, 0, 0, 0, 1);
					graphics.applyViewport(0, 0, SIZE >> 1, SIZE);
					draw(opaque, red, 6);
					graphics.endTargetPass();
					graphics.resumeTargetPass(target);
					graphics.applyViewport(SIZE >> 1, 0, SIZE >> 1, SIZE >> 1);
					draw(tinted, positions, 6, null, null, [clip, floatBytes([0, 0, 0, 0]), null, null, null, null, floatBytes([0, 1, 0, 1])]);
					graphics.endTargetPass();
				},
				target: target,
				check: p -> {
					p.expect(3, 3, [1, 0, 0, 1], 0);
					p.expect(3, 12, [1, 0, 0, 1], 0);
					p.expect(12, 12, [0, 1, 0, 1], 0);
					p.expect(12, 3, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a target with depth, drawn in one frame",
				// Blue, with a red band on the left half's middle at a depth of 0.25.
				before: () -> {
					graphics.beginTargetPass(kept, 0, 0, 1, 1);
					draw(deep, half, 6, null, null, [
						clip,
						floatBytes([-.5, 0, -.5, 0]),
						null,
						null,
						null,
						null,
						floatBytes([1, 0, 0, 1])
					]);
					graphics.endTargetPass();
				},
				target: kept,
				check: p -> {
					p.expect(3, 8, [1, 0, 0, 1], 1);
					p.expect(12, 8, [0, 0, 1, 1], 1);
				}
			},
			{
				name: "the target kept, its depth too, in the next",
				// Resumed: green over the bottom half at a depth of 0.5, hidden behind the band, the blue above it kept.
				before: () -> {
					graphics.resumeTargetPass(kept);
					graphics.applyViewport(0, 0, SIZE, SIZE >> 1);
					draw(deep, positions, 6, null, null, [clip, floatBytes([0, 0, 0, 0]), null, null, null, null, floatBytes([0, 1, 0, 1])]);
					graphics.endTargetPass();
				},
				target: kept,
				check: p -> {
					p.expect(3, 2, [0, 0, 1, 1], 1);
					p.expect(12, 2, [0, 0, 1, 1], 1);
					p.expect(3, 6, [1, 0, 0, 1], 1);
					p.expect(3, 10, [1, 0, 0, 1], 1);
					p.expect(3, 14, [0, 1, 0, 1], 1);
					p.expect(12, 10, [0, 1, 0, 1], 1);
				}
			},
			slantedCase("depth and one sample: every texel one color or the other", singleDepth, false),
			slantedCase('depth and the screen\'s samples (${graphics.msaaSampleCount})', screenDepth, Math.min(graphics.msaaSampleCount, most) > 1),
			slantedCase('no depth and the most samples the format takes ($most)', mostFlat, most > 1),
			{
				name: "a sample count rounded down to what the GPU takes, a negative one refused",
				before: () -> {
					graphics.beginTargetPass(clamped, 0, 0, 0, 1);
					draw(opaque, slanted, 3);
					graphics.endTargetPass();
				},
				target: clamped,
				check: p -> {
					for (m in [most, mostHalf])
						check(m == 1 || m == 2 || m == 4 || m == 8, 'a most of $m samples, not 1, 2, 4 or 8');
					check(graphics.maxMsaaSampleCount >= graphics.msaaSampleCount, 'the window\'s most samples below its own');
					check(negativeRefused, "a target of -1 samples made");
					checkEdge(p, most > 1);
				}
			},
			{
				name: "a target never cleared, resumed",
				before: () -> {
					graphics.resumeTargetPass(fresh);
					graphics.endTargetPass();
				},
				target: fresh,
				check: p -> for (at in [[0, 0], [8, 8], [15, 15]])
					p.expect(at[0], at[1], [0, 0, 0, 0], 0)
			},
			{
				name: "a texture read back",
				target: checker,
				check: p -> {
					if (p.width != 2 || p.height != 2)
						throw 'a texture read back: ${p.width} x ${p.height}, not 2 x 2';
					p.expect(0, 0, [1, 0, 0, 1], 0);
					p.expect(1, 0, [0, 1, 0, 1], 0);
					p.expect(0, 1, [0, 0, 1, 1], 0);
					p.expect(1, 1, [1, 1, 1, 1], 0);
				}
			},
			{
				name: "a texture read back after its rectangle replaced",
				before: () -> graphics.updateTexture(patched, 1, 2, 3, 1, rgbaTexels([0x00ffff80, 0x00ffff80, 0x00ffff80])),
				target: patched,
				// Yellow from the case before, its third row from column 1 a half-transparent cyan.
				check: p -> {
					p.expect(0, 2, [1, 1, 0, 1], 0);
					p.expect(1, 2, [0, 1, 1, 128 / 255], 0);
					p.expect(3, 2, [0, 1, 1, 128 / 255], 0);
					p.expect(2, 3, [1, 1, 0, 1], 0);
				}
			},
			{
				name: "a vertex buffer drawn from an offset",
				before: into(0, 0, 0, 1, () -> graphics.draw(dotted, [dotsAfterJunk], [24], 0, 0, 5, 0, 1, [], [], [clip])),
				target: target,
				check: p -> {
					for (i => s in spots)
						expectSpot(p, s, spotColors[i].concat([1]));
					p.expect(10, 12, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "an indexed draw from an offset",
				before: into(0, 0, 0, 1, () -> graphics.draw(dottedIndexed, [dotsAfterJunk], [24], dotIndexBuffer, 0, 2, 0, 1, [], [], [clip])),
				target: target,
				check: p -> {
					expectSpot(p, spots[3], [1, 1, 1, 1]);
					expectSpot(p, spots[0], [1, 0, 0, 1]);
					for (s in [spots[1], spots[2], spots[4]])
						p.expect(s[0], s[1], [0, 0, 0, 1], 0);
					p.expect(10, 12, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "an instanced buffer drawn from an offset",
				before: into(0, 0, 0, 1, () -> {
					graphics.draw(placed, [positions, instancesAfterJunk], [0, 80], 0, 0, 6, 0, 2, [], [], [clip]);
					graphics.draw(placed, [positions, instancesAfterJunk], [0, 80], 0, 0, 6, 2, 1, [], [], [clip]);
				}),
				target: target,
				check: p -> {
					p.expect(4, 4, [1, 0, 0, 1], 0);
					p.expect(12, 12, [0, 1, 0, 1], 0);
					p.expect(12, 4, [0, 0, 1, 1], 0);
					p.expect(6, 10, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "a stream buffer appended to, each range drawn from its offset",
				before: into(0, 0, 0, 1, () -> {
					var at = graphics.appendBuffer(appendedDots, floatBytes(dotFloats.slice(0, 12)), 48);
					graphics.draw(dotted, [appendedDots], [at], 0, 0, 2, 0, 1, [], [], [clip]);
					var next = graphics.appendBuffer(appendedDots, floatBytes(dotFloats.slice(12)), 72);
					graphics.draw(dotted, [appendedDots], [next], 0, 0, 3, 0, 1, [], [], [clip]);
					// The first range is still there, drawn again after the second was written.
					graphics.draw(dotted, [appendedDots], [at], 0, 0, 5, 0, 1, [], [], [clip]);
					if (at != 0 || next != 48)
						throw 'appended at $at and $next, not 0 and 48';
					var updated = try {
						graphics.updateBuffer(appendedDots, floatBytes(dotFloats), 120);
						true;
					} catch (_:Dynamic)
						false;
					if (updated)
						throw "a buffer appended to this frame was updated";
					var overflowed = try {
						graphics.appendBuffer(appendedDots, floatBytes(dotFloats), 120);
						true;
					} catch (_:Dynamic)
						false;
					if (overflowed)
						throw "an append past the capacity was accepted";
				}),
				target: target,
				check: p -> for (i => s in spots)
					expectSpot(p, s, spotColors[i].concat([1]))
			},
			{
				name: "a draw whose offset is out of range is refused",
				before: into(0, 0, 0, 1, () -> {
					var refused = 0;
					for (offsets in [[-4], [2], [dotFloats.length * 4 + 4], [24]])
						try
							graphics.draw(dotted, [dots], offsets, 0, 0, 5, 0, 1, [], [], [clip])
						catch (_:Dynamic)
							refused++;
					if (refused != 4)
						throw 'offsets out of range refused: $refused of 4';
				}),
				target: target,
				check: p -> p.expect(2, 3, [0, 0, 0, 1], 0)
			},
			{
				name: "instances placed by a matrix input",
				// The first two instances; the third (top right) only from a second draw starting at it.
				before: into(0, 0, 0, 1, () -> {
					graphics.draw(placed, [positions, instances], null, 0, 0, 6, 0, 2, [], [], [clip]);
					graphics.draw(placed, [positions, instances], null, 0, 0, 6, 2, 1, [], [], [clip]);
				}),
				target: target,
				check: p -> {
					p.expect(4, 4, [1, 0, 0, 1], 0);
					p.expect(12, 12, [0, 1, 0, 1], 0);
					p.expect(12, 4, [0, 0, 1, 1], 0);
					p.expect(4, 12, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "mipmaps under each mipmap filter",
				// Drawn into 3 x 3, which reads level 1.415: its top level alone, the nearest level (1, green), the two nearest blended
				// (green and blue), filtered nearest; then linear with an anisotropy of 16.
				before: into(0, 0, 0, 1, () -> for (i => sampling in [
					new Sampling(Nearest, Clamp, Clamp, None),
					new Sampling(Nearest, Clamp, Clamp, Nearest),
					new Sampling(Nearest, Clamp, Clamp, Linear),
					new Sampling(Linear, Clamp, Clamp, Linear, 16)
				]) {
					graphics.applyViewport(i * 4, 0, 3, 3);
					draw(sampled, uvQuad, 6, [mipmapped], [sampling]);
				}),
				target: target,
				check: p -> {
					p.expect(1, 14, [1, 0, 0, 1], 0);
					p.expect(5, 14, [0, 1, 0, 1], 0);
					p.expect(9, 14, [0, .585, .415, 1], 10);
					// Anisotropy may choose its level apart from a square's (lavapipe and SwiftShader do): green and blue blended, whatever
					// their share.
					var at = (14 * p.width + 13) * 4;
					GraphicsTests.check(p.bytes.get(at) <= 2 && Math.abs(p.bytes.get(at + 1) + p.bytes.get(at + 2) - 255) <= 4,
						'at 13,14: ${[for (i in 0...3) p.bytes.get(at + i)]}, expected green and blue blended');
				}
			},
			{
				name: "a render target drawn to the screen",
				// Red with a green top right quarter, drawn over the screen: the quarter stays top right.
				before: into(1, 0, 0, 1, () -> draw(tinted, half, 6, null, null, [
					clip,
					floatBytes([.5, .5, 0, 0]),
					null,
					null,
					null,
					null,
					floatBytes([0, 1, 0, 1])
				])),
				screen: (_, _) -> draw(sampled, uvQuad, 6, [target], [Sampling.NEAREST]),
				target: 0,
				check: p -> {
					var w = p.width, h = p.height;
					p.expect(w * 3 >> 2, h >> 2, [0, 1, 0], 0);
					p.expect(w >> 2, h >> 2, [1, 0, 0], 0);
					p.expect(w >> 2, h * 3 >> 2, [1, 0, 0], 0);
					p.expect(w * 3 >> 2, h * 3 >> 2, [1, 0, 0], 0);
				}
			},
			{
				name: "viewport and scissor in a target",
				// White through the bottom left quarter's viewport, then red clipped to the top right 4 x 4; both measured from the bottom.
				before: into(0, 0, 0, 1, () -> {
					graphics.applyViewport(0, 0, SIZE >> 1, SIZE >> 1);
					draw(opaque, white, 6);
					graphics.applyViewport(0, 0, SIZE, SIZE);
					graphics.applyScissor(SIZE - 4, SIZE - 4, 4, 4);
					draw(opaque, red, 6);
				}),
				target: target,
				check: p -> {
					p.expect(3, 12, [1, 1, 1, 1], 0);
					p.expect(7, 8, [1, 1, 1, 1], 0);
					p.expect(3, 3, [0, 0, 0, 1], 0);
					p.expect(8, 12, [0, 0, 0, 1], 0);
					p.expect(13, 1, [1, 0, 0, 1], 0);
					p.expect(12, 3, [1, 0, 0, 1], 0);
					p.expect(11, 1, [0, 0, 0, 1], 0);
					p.expect(13, 4, [0, 0, 0, 1], 0);
				}
			},
			{
				name: "viewport and scissor on the screen",
				screen: (w, h) -> {
					graphics.applyViewport(0, 0, w >> 1, h >> 1);
					draw(opaque, white, 6);
					graphics.applyViewport(0, 0, w, h);
					graphics.applyScissor(w - (w >> 2), h - (h >> 2), w >> 2, h >> 2);
					draw(opaque, red, 6);
				},
				target: 0,
				check: p -> {
					var w = p.width, h = p.height;
					p.expect(w >> 2, h * 3 >> 2, [1, 1, 1], 0);
					p.expect(w >> 2, h >> 2, [0, 0, 0], 0);
					p.expect(w * 3 >> 2, h * 3 >> 2, [0, 0, 0], 0);
					p.expect(w - (w >> 3), h >> 3, [1, 0, 0], 0);
					p.expect(w * 5 >> 3, h >> 3, [0, 0, 0], 0);
				}
			},
			{
				name: "a data texture's floats",
				// Its sampling asks for linear, which a data texture ignores.
				before: into(0, 0, 0, 0, () -> draw(fetched, uvQuad, 6, [table], [Sampling.LINEAR])),
				target: target,
				check: p -> for (i in 0...4)
					p.expect(i * 4 + 2, 8, [floats[i * 4] / 8, -floats[i * 4 + 1], floats[i * 4 + 2], 1], 1)
			},
			{
				name: "a cubemap's faces",
				before: into(0, 0, 0, 0, () -> draw(looked, uvQuad, 6, [sky], [Sampling.LINEAR])),
				target: target,
				// Each sixth's middle column.
				check: p -> for (face => rgb in [[1., 0, 0], [0., 1, 0], [0., 0, 1], [1., 1, 0], [1., 0, 1], [0., 1, 1]])
					p.expect(Std.int((face + .5) * SIZE / 6), 8, rgb.concat([1]), 1)
			},
			{
				name: "declared textures left unbound read clear",
				// A plain texture, a cubemap and a data texture, each in a third, over white.
				before: into(1, 1, 1, 1, () -> {
					graphics.applyViewport(0, 0, 5, SIZE);
					draw(sampled, uvQuad, 6);
					graphics.applyViewport(5, 0, 5, SIZE);
					draw(looked, uvQuad, 6);
					graphics.applyViewport(10, 0, 6, SIZE);
					draw(fetched, uvQuad, 6);
				}),
				target: target,
				check: p -> {
					p.expect(2, 8, [0, 0, 0, 0], 0);
					p.expect(7, 8, [0, 0, 0, 0], 0);
					p.expect(13, 8, [0, 0, 0, 1], 0);
				}
			}
		];
		#if js
		// Last: the context lost with WEBGL_lose_context and given back, as IGraphics says, then drawn with again. The frames while it is lost
		// are tick's; the case after it is the owner's part, a texture and a buffer made again, into a target the adapter remade.
		cases.push({
			name: "the context lost",
			before: () -> {
				var canvas:Dynamic = js.Browser.document.getElementById("canvas");
				loseExtension = canvas.getContext("webgl2").getExtension("WEBGL_lose_context");
				losing = 1;
				lostFrames = 0;
				loseExtension.loseContext();
			},
			target: 0,
			check: _ -> {}
		});
		cases.push({
			name: "drawn again after the context came back",
			before: () -> {
				check(lostThrew == null, 'a call threw while the context was lost: $lostThrew');
				check(lostFrames >= 30, '$lostFrames frames while lost, 30 or more expected');
				var again = texture2D(2, 2, [0xff0000ff, 0x00ff00ff, 0x0000ffff, 0xffffffff]),
					quadAgain = buffer(uvSquare);
				graphics.beginTargetPass(target, 0, 0, 0, 1);
				draw(sampled, quadAgain, 6, [again], [Sampling.NEAREST]);
				graphics.endTargetPass();
			},
			screen: (_, _) -> draw(sampled, buffer(uvSquare), 6, [target], [Sampling.NEAREST]),
			target: 0,
			check: p -> {
				var w = p.width, h = p.height;
				p.expect(w >> 2, h >> 2, [1, 0, 0], 0);
				p.expect(w * 3 >> 2, h >> 2, [0, 1, 0], 0);
				p.expect(w >> 2, h * 3 >> 2, [0, 0, 1], 0);
				p.expect(w * 3 >> 2, h * 3 >> 2, [1, 1, 1], 0);
			}
		});
		#end
	}

	/** Checks the slanted red triangle over black: some texels wholly red and some black, and texels partly red along its edge exactly when
		the target is multisampled. */
	static function checkEdge(p:Pixels, multisampled:Bool):Void {
		var red = 0, black = 0, partial = 0;
		for (i in 0...p.width * p.height) {
			var r = p.bytes.get(i * 4),
				g = p.bytes.get(i * 4 + 1),
				b = p.bytes.get(i * 4 + 2);
			if (r == 255 && g == 0 && b == 0)
				red++;
			else if (r == 0 && g == 0 && b == 0)
				black++;
			else if (g == 0 && b == 0)
				partial++;
			else
				check(false, 'a texel of $r, $g, $b, neither red nor black');
		}
		check(red > 0 && black > 0, '$red texels red and $black black');
		check(multisampled ? partial > 0 : partial == 0, '$partial texels partly red along the edge, ${multisampled ? "none" : "some"} expected');
	}

	static function shader(source:helix.platform.ShaderSource):Int {
		var handle = graphics.createShader(source);
		shaders.push(handle);
		return handle;
	}

	static function pipeline(shader:Int, layout:VertexBuffer, blend:Blend, ?colorWrite:ColorChannels):Int {
		var handle = graphics.createPipeline({
			shader: shader,
			buffers: [layout],
			primitive: Triangles,
			indexed: false,
			blend: blend,
			colorWrite: colorWrite,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale
		});
		pipelines.push(handle);
		return handle;
	}

	// A static buffer of a record six times, a value for each of the square's vertices.
	static function repeated(record:Bytes):Int {
		var bytes = Bytes.alloc(record.length * 6);
		for (i in 0...6)
			bytes.blit(i * record.length, record, 0, record.length);
		var handle = graphics.createStaticBuffer(bytes, bytes.length, false);
		buffers.push(handle);
		return handle;
	}

	static function buffer(values:Array<Float>):Int {
		var handle = graphics.createStaticBuffer(floatBytes(values), values.length * 4, false);
		buffers.push(handle);
		return handle;
	}

	// An RGBA8 texture from texels given as 0xRRGGBBAA.
	static function texture2D(width:Int, height:Int, texels:Array<Int>):Int {
		var bytes = Bytes.alloc(texels.length * 4);
		for (i => rgba in texels)
			bytes.setInt32(i * 4, rgbaBytes(rgba));
		var handle = graphics.createTexture(width, height, [bytes]);
		textures.push(handle);
		return handle;
	}

	// RGBA8 texels given as 0xRRGGBBAA.
	static function rgbaTexels(texels:Array<Int>):Bytes {
		var bytes = Bytes.alloc(texels.length * 4);
		for (i => rgba in texels)
			bytes.setInt32(i * 4, rgbaBytes(rgba));
		return bytes;
	}

	// 0xRRGGBBAA as the little-endian int whose bytes are R, G, B, A.
	static function rgbaBytes(rgba:Int):Int
		return (rgba >>> 24) | (rgba >> 16 & 0xff) << 8 | (rgba >> 8 & 0xff) << 16 | (rgba & 0xff) << 24;

	static function floatBytes(values:Array<Float>):Bytes {
		var bytes = Bytes.alloc(values.length * 4);
		for (i => v in values)
			bytes.setFloat(i * 4, v);
		return bytes;
	}

	/** Frees what setup made, says how it went and closes the window where the program owns one. */
	static function finish():Void {
		for (p in pipelines)
			graphics.disposePipeline(p);
		for (s in shaders)
			graphics.disposeShader(s);
		for (b in buffers)
			graphics.disposeBuffer(b);
		for (t in textures)
			graphics.disposeTexture(t);
		graphics.dispose();
		events.dispose();
		var result = {passed: failures.length == 0, checks: checks, failures: failures};
		#if js
		js.Syntax.code("window.helixResult = {0}", result);
		#else
		Sys.println(haxe.Json.stringify(result));
		if (window.canClose())
			window.close();
		Sys.exit(result.passed ? 0 : 1);
		#end
	}
}

/** Represents pixels read back: RGBA8, rows top first. */
class Pixels {
	/** The bytes. */
	public final bytes:Bytes;

	/** The width, in pixels. */
	public final width:Int;

	/** The height, in pixels. */
	public final height:Int;

	/** Creates the pixels read back.
		@param bytes  The bytes.
		@param width  The width, in pixels.
		@param height  The height, in pixels. */
	public function new(bytes:Bytes, width:Int, height:Int) {
		this.bytes = bytes;
		this.width = width;
		this.height = height;
	}

	/** Checks one pixel against a color.
		@param x  The column.
		@param y  The row, from the top.
		@param color  The red, green, blue and optionally alpha expected, 0 to 1.
		@param tolerance  How far each channel may be from it, in 0 to 255's steps. */
	public function expect(x:Int, y:Int, color:Array<Float>, tolerance:Int):Void {
		var at = (y * width + x) * 4;
		var found = [for (i in 0...color.length) bytes.get(at + i)];
		var close = true;
		for (i in 0...color.length)
			if (Math.abs(found[i] - color[i] * 255) > tolerance + .5)
				close = false;
		GraphicsTests.check(close, 'at $x,$y: $found, expected ${[for (c in color) Math.round(c * 255)]} within $tolerance');
	}
}
