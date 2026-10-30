package helix.ray.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.platform.IGraphics;
import helix.platform.Sampling;

/** Records a frame's drawing in the order it is asked for, and draws it at the frame's end: each render texture's pass, then the
	screen's.

	Shapes, text and textures are immediate vertices, collected in one buffer, uploaded once in each pass; a mesh draws from its own
	buffers. Each draw keeps a copy of its program's values as they were when it was asked for. */
@:noCompletion
class Frame {
	static inline final FLOATS = 12;
	static inline final STRIDE = FLOATS * 4;

	/** Each raylib attribute's place in an immediate vertex, in floats, and its size. */
	static final OFFSETS = [
		"vertexPosition" => 0,
		"vertexTexCoord" => 3,
		"vertexNormal" => 5,
		"vertexColor" => 8
	];

	static final SIZES = [
		"vertexPosition" => 3,
		"vertexTexCoord" => 2,
		"vertexNormal" => 3,
		"vertexColor" => 4
	];

	final graphics:IGraphics;
	var data = Bytes.alloc(STRIDE * 6 * 1024);
	var vertices = 0;
	var buffer = 0;
	var capacity = 0;
	final passes:Array<Pass> = [];
	var pass:Pass;
	var open:Null<Draw> = null;

	/** raylib's default shader. */
	public final defaultProgram:Program;

	/** The white texture shapes draw with, and a texture without an image reads as. */
	public final white:Int;

	/** The program drawn with outside a material, `BeginShaderMode`'s or the default. */
	public var program:Program;

	/** The matrices drawn with: in 2D the screen's (or `BeginMode2D`'s camera's), in 3D the camera's. */
	public var view:Matrix3D;

	public var projection:Matrix3D;

	/** Whether drawing is in `BeginMode3D`. */
	public var in3D = false;

	/** The normal the next immediate vertices carry, as raylib's `rlNormal3f` sets it. */
	public var nx = 0.;

	public var ny = 0.;
	public var nz = 1.;

	/** Creates the frame, with raylib's default shader and the white texture.

		@param graphics  The graphics. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
		defaultProgram = new Program(graphics, Defaults.shader());
		program = defaultProgram;
		var texel = Bytes.alloc(4);
		texel.fill(0, 4, 255);
		white = graphics.createTexture(1, 1, [texel]);
		view = new Matrix3D();
		projection = new Matrix3D();
		pass = {
			target: 0,
			clear: 0xff000000,
			width: 1,
			height: 1,
			draws: []
		};
		reset();
	}

	/** Starts the frame's drawing on the screen, at its size now. Render textures drawn into before it, as raylib allows, are kept.

		@param width  The screen's width, in the pixels drawing is in.
		@param height  The screen's height. */
	public function begin(width:Float, height:Float):Void {
		var screen = passes[passes.length - 1];
		screen.width = width;
		screen.height = height;
		pass = screen;
		in3D = false;
		program = defaultProgram;
		screen2D();
	}

	// After a frame is drawn: nothing recorded, the screen's pass alone.
	function reset():Void {
		var screen = passes.length > 0 ? passes[passes.length - 1] : null;
		passes.resize(0);
		vertices = 0;
		pass = {
			target: 0,
			clear: 0xff000000,
			width: screen == null ? 1 : screen.width,
			height: screen == null ? 1 : screen.height,
			draws: []
		};
		passes.push(pass);
		open = null;
		in3D = false;
		program = defaultProgram;
		screen2D();
	}

	/** Gets the current pass's size. */
	public var width(get, never):Float;

	function get_width():Float
		return pass.width;

	public var height(get, never):Float;

	function get_height():Float
		return pass.height;

	/** Sets the matrices to 2D over the current pass: pixels from its top left. */
	public function screen2D():Void {
		view = new Matrix3D();
		projection = new Matrix3D().makeOrthographic(0, pass.width, pass.height, 0, 0, 1);
		open = null;
	}

	/** Starts drawing into a render target, as its own pass, until `toScreen`.

		@param target  The render target's handle.
		@param width  Its width.
		@param height  Its height. */
	public function toTarget(target:Int, width:Int, height:Int):Void {
		pass = {
			target: target,
			clear: 0,
			width: width,
			height: height,
			draws: []
		};
		passes.insert(passes.length - 1, pass);
		in3D = false;
		screen2D();
	}

	/** Goes back to drawing on the screen. */
	public function toScreen():Void {
		pass = passes[passes.length - 1];
		in3D = false;
		screen2D();
	}

	/** Clears the current pass to a color, dropping what was drawn into it.

		@param color  0xAARRGGBB. */
	public function clear(color:Int):Void {
		pass.clear = color;
		pass.draws.resize(0);
		open = null;
	}

	/** Ends the run of immediate vertices, so the next starts a draw of its own (the matrices or the program changed). */
	public function cut():Void {
		open = null;
	}

	/** Adds an immediate vertex.

		@param texture  The texture.
		@param lines  Whether it makes lines rather than triangles.
		@param x  Position.
		@param y  Position.
		@param z  Position.
		@param u  Texture coordinate.
		@param v  Texture coordinate.
		@param color  Its color. */
	public function vertex(texture:Int, lines:Bool, x:Float, y:Float, z:Float, u:Float, v:Float, color:helix.ray.Color):Void {
		if (open == null || open.texture != texture || open.lines != lines) {
			open = immediate(texture, lines);
			pass.draws.push(open);
		}
		open.count++;
		var at = vertices * STRIDE;
		if (at + STRIDE > data.length) {
			var grown = Bytes.alloc(data.length * 2);
			grown.blit(0, data, 0, at);
			data = grown;
		}
		data.setFloat(at, x);
		data.setFloat(at + 4, y);
		data.setFloat(at + 8, z);
		data.setFloat(at + 12, u);
		data.setFloat(at + 16, v);
		data.setFloat(at + 20, nx);
		data.setFloat(at + 24, ny);
		data.setFloat(at + 28, nz);
		data.setFloat(at + 32, color.r / 255);
		data.setFloat(at + 36, color.g / 255);
		data.setFloat(at + 40, color.b / 255);
		data.setFloat(at + 44, color.a / 255);
		vertices++;
	}

	// A run of immediate vertices, through the current program and matrices.
	function immediate(texture:Int, lines:Bool):Draw {
		var p = program, depth = in3D;
		var key = 'i${lines ? "l" : "t"}${depth ? "d" : ""}';
		var pipeline = p.pipeline(key, () -> graphics.createPipeline({
			shader: p.handle,
			buffers: [
				{
					stride: STRIDE,
					instanced: false,
					attributes: [
						for (i => name in p.attributes)
							{slot: i, componentCount: SIZES.get(name), offset: OFFSETS.get(name) * 4}
					]
				}
			],
			primitive: lines ? Lines : Triangles,
			indexed: false,
			blend: Alpha,
			depthTest: depth ? LessEqual : Off,
			depthWrite: depth,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale
		}));
		var textures = p.textures.copy();
		if (p.texture0 >= 0)
			textures[p.texture0] = texture;
		var model = new Matrix3D();
		return {
			pipeline: pipeline,
			buffers: null,
			indices: 0,
			first: vertices,
			count: 0,
			texture: texture,
			lines: lines,
			textures: textures,
			uniforms: values(p, model, [1, 1, 1, 1])
		};
	}

	/** Draws a mesh.

		@param mesh  The mesh, uploaded.
		@param p  The program.
		@param model  Its transform.
		@param diffuse  The diffuse color, 0 to 1 each.
		@param textures  The textures for raylib's slots 0 to 2 (0 for white). */
	public function mesh(mesh:helix.ray.Mesh, p:Program, model:Matrix3D, diffuse:Array<Float>, textures:Array<Int>):Void {
		open = null;
		var indexed = mesh.gpu.indexBuffer != 0, depth = in3D;
		var key = 'm${indexed ? "x" : ""}${depth ? "d" : ""}';
		var pipeline = p.pipeline(key, () -> graphics.createPipeline({
			shader: p.handle,
			buffers: [
				for (i => name in p.attributes)
					{
						stride: SIZES.get(name) * 4,
						instanced: false,
						attributes: [{slot: i, componentCount: SIZES.get(name), offset: 0}]
					}
			],
			primitive: Triangles,
			indexed: indexed,
			blend: Alpha,
			depthTest: depth ? LessEqual : Off,
			depthWrite: depth,
			cull: depth ? Back : None,
			clockwise: false,
			depthOnly: false,
			flip: ClipScale
		}));
		var bound = p.textures.copy();
		for (k => slot in [p.texture0, p.texture1, p.texture2])
			if (slot >= 0)
				bound[slot] = textures[k] == 0 ? white : textures[k];
		for (i in 0...bound.length)
			if (bound[i] == 0)
				bound[i] = white;
		var buffers = [
			for (name in p.attributes)
				mesh.gpu.buffers[
					["vertexPosition", "vertexTexCoord", "vertexNormal", "vertexColor"].indexOf(name)
				]
		];
		pass.draws.push({
			pipeline: pipeline,
			buffers: buffers,
			indices: mesh.gpu.indexBuffer,
			first: 0,
			count: indexed ? mesh.triangleCount * 3 : mesh.vertexCount,
			texture: 0,
			lines: false,
			textures: bound,
			uniforms: values(p, model, diffuse)
		});
	}

	// The program's blocks as they are now, with raylib's own values set: the matrices and the diffuse color.
	function values(p:Program, model:Matrix3D, diffuse:Array<Float>):Array<Null<Bytes>> {
		var modelView = new Matrix3D().compose(model, view);
		p.writeNamed("mvp", new Matrix3D().compose(modelView, projection).values);
		p.writeNamed("matModel", model.values);
		p.writeNamed("matView", view.values);
		p.writeNamed("matProjection", projection.values);
		if (p.declares("matNormal")) {
			var normal = new Matrix3D().copyFrom(model);
			normal.invert();
			p.writeNamed("matNormal", normal.transpose().values);
		}
		p.writeNamed("colDiffuse", diffuse);
		return [for (b in p.blocks) b == null ? null : b.sub(0, b.length)];
	}

	/** Draws the frame: each render texture's pass, then the screen's, then shows it.

		@param framebufferWidth  The screen's framebuffer width.
		@param framebufferHeight  Its height. */
	public function draw(framebufferWidth:Int, framebufferHeight:Int):Void {
		var sampling = new Sampling(Nearest);
		for (p in passes) {
			if (p.target == 0)
				graphics.beginFrame(framebufferWidth, framebufferHeight, p.clear);
			else
				graphics.beginTargetPass(p.target, (p.clear >> 16 & 255) / 255, (p.clear >> 8 & 255) / 255, (p.clear & 255) / 255, (p.clear >>> 24) / 255);
			upload();
			for (d in p.draws) {
				if (d.count == 0)
					continue;
				var count = d.lines ? d.count - d.count % 2 : d.count - d.count % 3;
				var samplings = [for (_ in d.textures) sampling];
				graphics.draw(d.pipeline, d.buffers == null ? [buffer] : d.buffers, d.indices, d.first, count, 0, 1, d.textures, samplings, d.uniforms);
			}
			if (p.target == 0) {
				graphics.endFrame();
				graphics.present();
			} else
				graphics.endTargetPass();
		}
		reset();
	}

	function upload():Void {
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

	/** Frees the buffer, the white texture and the default program. */
	public function dispose():Void {
		if (buffer != 0)
			graphics.disposeBuffer(buffer);
		graphics.disposeTexture(white);
		defaultProgram.dispose();
	}
}

private typedef Pass = {
	final target:Int;
	var clear:Int;
	var width:Float;
	var height:Float;
	final draws:Array<Draw>;
}

private typedef Draw = {
	final pipeline:Int;
	final buffers:Null<Array<Int>>;
	final indices:Int;
	final first:Int;
	var count:Int;
	final texture:Int;
	final lines:Bool;
	final textures:Array<Int>;
	final uniforms:Array<Null<Bytes>>;
}
