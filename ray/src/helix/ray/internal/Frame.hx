package helix.ray.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.platform.BlendMode;
import helix.platform.IGraphics;

/** Records a frame's drawing as rlgl orders it, and draws it at the frame's end: each render texture's pass, then the screen's.

	Shapes, text and textures are immediate vertices, collected in one buffer, uploaded once in each pass; a mesh draws from its own
	buffers. As in rlgl, immediate vertices wait in a batch until it is flushed (`flush`: a change of mode, matrices, shader, blending,
	scissor or pass, and the pass's end), and are drawn then with the state and the program's values as they are at that moment: rlgl's
	state calls (wire mode, culling, depth) don't flush, so they reach what is in the batch. A mesh is drawn as it is asked for, with the
	state then, ahead of the batch's vertices still waiting. */
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
		"vertexColor" => 4,
		"vertexTangent" => 4,
		"vertexTexCoord2" => 2,
		"vertexBoneIds" => 4,
		"vertexBoneIndices" => 4,
		"vertexBoneWeights" => 4
	];

	/** Each raylib attribute's buffer in a mesh, by raylib's buffer index: the bone ids by raylib 5.5's name or 6.2's. */
	static final MESH_BUFFERS = [
		"vertexPosition" => 0,
		"vertexTexCoord" => 1,
		"vertexNormal" => 2,
		"vertexColor" => 3,
		"vertexTangent" => 4,
		"vertexTexCoord2" => 5,
		"vertexBoneIds" => 7,
		"vertexBoneIndices" => 7,
		"vertexBoneWeights" => 8
	];

	/** The bytes of the one record of `constants`. */
	static inline final CONSTANT_BYTES = 56;

	/** The attributes immediate vertices don't carry, and where each is in the one record of `constants`, in floats: raylib's batch has
		none, so a shader reads raylib's defaults, 0. */
	static final CONSTANTS = [
		"vertexTangent" => 0,
		"vertexTexCoord2" => 4,
		"vertexBoneIds" => 6,
		"vertexBoneIndices" => 6,
		"vertexBoneWeights" => 10
	];

	final graphics:IGraphics;
	var data = Bytes.alloc(STRIDE * 6 * 1024);
	var vertices = 0;
	var buffer = 0;
	var capacity = 0;
	final passes:Array<Pass> = [];
	var pass:Pass;
	// The batch: runs of immediate vertices waiting to be drawn, and the one being added to.
	final batch:Array<Run> = [];

	var open:Null<Run> = null;

	/** raylib's default shader. */
	public final defaultProgram:Program;

	/** The white texture shapes draw with, and a texture without an image reads as. */
	public final white:Int;

	// One record of zeros, for the attributes in CONSTANTS, read as an instance's so every vertex has it.
	final constants:Int;

	// The buffers replaced while the frame was asked for, freed once it is drawn.
	final retired:Array<Int> = [];

	/** The program drawn with outside a material, `BeginShaderMode`'s or the default. */
	public var program:Program;

	/** The matrices drawn with: in 2D the screen's (or `BeginMode2D`'s camera's), in 3D the camera's. */
	public var view:Matrix3D;

	public var projection:Matrix3D;

	/** Whether the next draws test depth, as rlgl's `rlEnableDepthTest` sets it (`BeginMode3D` does, `EndMode3D` stops it); raylib's
		GL state, kept from frame to frame. */
	public var depthTest = false;

	/** Whether the next draws that test depth write it, rlgl's `rlEnableDepthMask`. */
	public var depthMask = true;

	/** Whether the next triangles' backs (or fronts, with `cullFront`) aren't drawn, rlgl's `rlEnableBackfaceCulling`: on, as raylib
		starts. */
	public var cull = true;

	/** Whether culling drops the fronts rather than the backs, rlgl's `rlSetCullFace`. */
	public var cullFront = false;

	/** Whether the next triangles are drawn as their edges, rlgl's `rlEnableWireMode`. */
	public var wire = false;

	/** Whether the next draws blend as `blend` says, rlgl's `rlEnableColorBlend`; when not, they draw over what is there. */
	public var colorBlend = true;

	/** How many passes have begun, counting each `begin`, `toTarget` and `toScreen`. */
	public var passCount(default, null) = 0;

	/** The rectangle the next draws fill, rlgl's `rlViewport`: x, y, width and height in framebuffer pixels from the bottom left; null
		for the whole pass, as each pass starts. */
	public var viewport:Null<Array<Int>> = null;

	/** The normal the next immediate vertices carry, as raylib's `rlNormal3f` sets it: none, 0, 0, 0, until it is set. */
	public var nx = 0.;

	public var ny = 0.;
	public var nz = 0.;

	/** The matrix the next immediate vertices are moved by, rlgl's pushed one (`rlPushMatrix`); null for none. */
	public var transform:Null<Matrix3D> = null;

	// Where a vertex goes under the transform.
	final moved = new helix.math.Vector3D();

	/** How the next draws blend, `BeginBlendMode`'s. */
	public var blend:BlendMode = Alpha;

	/** The rectangle the next draws are clipped to, `BeginScissorMode`'s: x, y, width and height in the pass's pixels from its top left;
		null for none. */
	public var scissor:Null<Array<Float>> = null;

	/** The screenshots read back as the screen's pass ends, once a program asks for one; null until then. */
	public var screenshots:Null<helix.services.screenshots.Screenshots> = null;

	/** Creates the frame, with raylib's default shader and the white texture.

		@param graphics  The graphics. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
		defaultProgram = new Program(graphics, Defaults.shader());
		program = defaultProgram;
		var texel = Bytes.alloc(4);
		texel.fill(0, 4, 255);
		white = graphics.createTexture(1, 1, [texel]);
		constants = graphics.createStaticBuffer(Bytes.alloc(CONSTANT_BYTES), CONSTANT_BYTES, false);
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
		flush();
		var screen = passes[passes.length - 1];
		screen.width = width;
		screen.height = height;
		pass = screen;
		viewport = null;
		passCount++;
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
		batch.resize(0);
		open = null;
		viewport = null;
		passCount++;
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

	/** Gets whether the current pass draws into a render target rather than the screen. */
	public var inTarget(get, never):Bool;

	function get_inTarget():Bool
		return pass.target != 0;

	/** Sets the matrices to 2D over the current pass: pixels from its top left, the batch flushed first. */
	public function screen2D():Void {
		flush();
		view = new Matrix3D();
		projection = Matrix3D.fromOrthographic(0, pass.width, pass.height, 0, 0, 1);
	}

	/** Starts drawing into a render target, as its own pass, until `toScreen`.

		@param target  The render target's handle.
		@param width  Its width.
		@param height  Its height. */
	public function toTarget(target:Int, width:Int, height:Int):Void {
		flush();
		pass = {
			target: target,
			clear: 0,
			width: width,
			height: height,
			draws: []
		};
		passes.insert(passes.length - 1, pass);
		viewport = null;
		passCount++;
		screen2D();
	}

	/** Goes back to drawing on the screen. */
	public function toScreen():Void {
		flush();
		pass = passes[passes.length - 1];
		viewport = null;
		passCount++;
		screen2D();
	}

	/** Clears the current pass to a color, dropping what was drawn into it; the batch, not drawn yet, is drawn after, as in rlgl.

		@param color  0xAARRGGBB. */
	public function clear(color:Int):Void {
		pass.clear = color;
		pass.draws.resize(0);
	}

	/** Draws the batch, rlgl's `rlDrawRenderBatchActive`: its runs into the pass, each through the current program, matrices and state
		(in wire mode, its triangles as their edges, those culling leaves). */
	public function flush():Void {
		if (batch.length == 0)
			return;
		var m = wire && cull ? Matrix3D.compose(view, projection, viewProjection).values : null;
		for (run in batch) {
			if (run.count == 0)
				continue;
			if (!wire || run.lines) {
				var d = immediate(run.texture, run.lines, run.first);
				d.count = run.count;
				pass.draws.push(d);
				continue;
			}
			// GL's line mode: each triangle's edges, written after the batch's vertices, unless culling drops it.
			var d = immediate(run.texture, true, vertices);
			for (k in 0...Std.int(run.count / 3)) {
				var a = (run.first + k * 3) * STRIDE, b = a + STRIDE, c = b + STRIDE;
				if (m != null
					&& culled(m, data.getFloat(a), data.getFloat(a + 4), data.getFloat(a + 8), data.getFloat(b), data.getFloat(b + 4), data.getFloat(b + 8),
						data.getFloat(c), data.getFloat(c + 4), data.getFloat(c + 8)))
					continue;
				for (corner in [a, b, b, c, c, a]) {
					copyVertex(corner);
					d.count++;
				}
			}
			pass.draws.push(d);
		}
		batch.resize(0);
		open = null;
	}

	/** Flushes the batch, as a change rlgl flushes for does: `flush`. */
	public inline function cut():Void {
		flush();
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
		if (transform != null) {
			transform.transformPoint(x, y, z, moved);
			x = moved.x;
			y = moved.y;
			z = moved.z;
		}
		if (open == null || open.texture != texture || open.lines != lines) {
			open = {
				texture: texture,
				lines: lines,
				first: vertices,
				count: 0
			};
			batch.push(open);
		}
		open.count++;
		var at = room();
		for (i => value in [
			x,
			y,
			z,
			u,
			v,
			nx,
			ny,
			nz,
			color.r / 255,
			color.g / 255,
			color.b / 255,
			color.a / 255
		])
			data.setFloat(at + i * 4, value);
		vertices++;
	}

	// Where the next vertex goes in the buffer, grown to hold it.
	function room():Int {
		var at = vertices * STRIDE;
		if (at + STRIDE > data.length) {
			var grown = Bytes.alloc(data.length * 2);
			grown.blit(0, data, 0, at);
			data = grown;
		}
		return at;
	}

	// Adds a copy of the vertex at a byte offset in the buffer.
	function copyVertex(from:Int):Void {
		var at = room();
		data.blit(at, data, from, STRIDE);
		vertices++;
	}

	// A draw of immediate vertices from first, through the current program, matrices and state.
	function immediate(texture:Int, lines:Bool, first:Int):Draw {
		var p = program, state = states();
		var key = 'i${lines ? "l" : "t"}$state';
		var pipeline = p.pipeline(key, () -> graphics.createPipeline({
			shader: p.handle,
			buffers: [
				{
					stride: STRIDE,
					instanced: false,
					attributes: [
						for (i => name in p.attributes)
							if (OFFSETS.exists(name)) {slot: i, componentCount: SIZES.get(name), offset: OFFSETS.get(name) * 4}
					]
				},
				{
					stride: CONSTANT_BYTES,
					instanced: true,
					attributes: [
						for (i => name in p.attributes)
							if (CONSTANTS.exists(name)) {slot: i, componentCount: SIZES.get(name), offset: CONSTANTS.get(name) * 4}
					]
				}
			],
			primitive: lines ? Lines : Triangles,
			indexed: false,
			blend: colorBlend ? blend : Opaque,
			depthTest: depthTest ? LessEqual : Off,
			depthWrite: depthTest && depthMask,
			cull: cullFace(),
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
			first: first,
			count: 0,
			texture: texture,
			lines: lines,
			scissor: scissor,
			viewport: viewport,
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
		// In wire mode, the mesh's triangles drawn as their edges, from an index buffer of them: those culling leaves, found here, as GL's
		// line mode culls the triangles it outlines.
		var edges = 0, edgeCount = mesh.triangleCount * 6;
		if (wire && cull) {
			var front = frontEdges(mesh, Matrix3D.compose(Matrix3D.compose(model, view, viewProjection), projection, viewProjection).values);
			edgeCount = front.length;
			if (edgeCount == 0)
				return;
			var bytes = Bytes.alloc(edgeCount * 4);
			for (i => index in front)
				bytes.setInt32(i * 4, index);
			edges = graphics.createStaticBuffer(bytes, bytes.length, true);
			retire(edges);
		} else if (wire)
			edges = Models.edges(mesh);
		var indexed = wire || mesh.gpu.indexBuffer != 0, state = states();
		var key = 'm${indexed ? "x" : ""}${wire ? "w" : ""}$state';
		// A buffer an attribute: the platform takes eight, as many as raylib's attributes.
		var names = p.attributes;
		var pipeline = p.pipeline(key, () -> {
			var layouts:Array<helix.platform.VertexBuffer> = [
				for (i => name in names)
					{
						stride: SIZES.get(name) * 4,
						instanced: false,
						attributes: [{slot: i, componentCount: SIZES.get(name), offset: 0}]
					}
			];
			graphics.createPipeline({
				shader: p.handle,
				buffers: layouts,
				primitive: wire ? Lines : Triangles,
				indexed: indexed,
				blend: colorBlend ? blend : Opaque,
				depthTest: depthTest ? LessEqual : Off,
				depthWrite: depthTest && depthMask,
				cull: wire ? None : cullFace(),
				clockwise: false,
				depthOnly: false,
				flip: ClipScale
			});
		});
		var bound = p.textures.copy();
		for (k => slot in [p.texture0, p.texture1, p.texture2])
			if (slot >= 0)
				bound[slot] = textures[k] == 0 ? white : textures[k];
		for (i in 0...bound.length)
			if (bound[i] == 0)
				bound[i] = white;
		var buffers = [for (name in names) Models.buffer(mesh, MESH_BUFFERS.get(name))];
		pass.draws.push({
			pipeline: pipeline,
			buffers: buffers,
			indices: wire ? edges : mesh.gpu.indexBuffer,
			first: 0,
			count: wire ? edgeCount : indexed ? mesh.triangleCount * 3 : mesh.vertexCount,
			texture: 0,
			lines: wire,
			scissor: scissor,
			viewport: viewport,
			textures: bound,
			uniforms: values(p, model, diffuse)
		});
	}

	// The view and projection together, reused.
	final viewProjection = new Matrix3D();

	// Whether culling drops a triangle, its corners moved by a matrix to clip space: by the sign of its area on the screen, GL's rule,
	// counterclockwise its front, one of no area its back. One with a corner behind the eye is kept.
	function culled(m:Array<Float>, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float):Bool {
		var aw = m[3] * ax + m[7] * ay + m[11] * az + m[15],
			bw = m[3] * bx + m[7] * by + m[11] * bz + m[15],
			cw = m[3] * cx + m[7] * cy + m[11] * cz + m[15];
		if (aw <= 0 || bw <= 0 || cw <= 0)
			return false;
		var x0 = (m[0] * ax + m[4] * ay + m[8] * az + m[12]) / aw,
			y0 = (m[1] * ax + m[5] * ay + m[9] * az + m[13]) / aw;
		var x1 = (m[0] * bx + m[4] * by + m[8] * bz + m[12]) / bw,
			y1 = (m[1] * bx + m[5] * by + m[9] * bz + m[13]) / bw;
		var x2 = (m[0] * cx + m[4] * cy + m[8] * cz + m[12]) / cw,
			y2 = (m[1] * cx + m[5] * cy + m[9] * cz + m[13]) / cw;
		// In window coordinates, snapped to a 256th of a pixel as GL rasterizers snap them, so a triangle seen almost edge-on has the area
		// GL finds for it.
		var w = pass.width * 128, h = pass.height * 128;
		x0 = Math.round(x0 * w);
		y0 = Math.round(y0 * h);
		x1 = Math.round(x1 * w);
		y1 = Math.round(y1 * h);
		x2 = Math.round(x2 * w);
		y2 = Math.round(y2 * h);
		var area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0);
		// GL takes a triangle as facing it only when its area is above 0.
		return cullFront ? area > 0 : area <= 0;
	}

	// The edges, two indices each, of a mesh's triangles culling leaves, its positions (an animation's, when one moved it) moved to clip
	// space by a matrix.
	function frontEdges(mesh:helix.ray.Mesh, m:Array<Float>):Array<Int> {
		var p = mesh.animVertices != null ? mesh.animVertices : mesh.vertices, indices = mesh.indices, edges = [];
		for (k in 0...mesh.triangleCount) {
			var a = indices == null ? k * 3 : indices[k * 3],
				b = indices == null ? k * 3 + 1 : indices[k * 3 + 1],
				c = indices == null ? k * 3 + 2 : indices[k * 3 + 2];
			if (culled(m, p[a * 3], p[a * 3 + 1], p[a * 3 + 2], p[b * 3], p[b * 3 + 1], p[b * 3 + 2], p[c * 3], p[c * 3 + 1], p[c * 3 + 2]))
				continue;
			for (i in [a, b, b, c, c, a])
				edges.push(i);
		}
		return edges;
	}

	// The render state a pipeline is made for, as part of its key.
	function states():String
		return '${depthTest ? "d" : ""}${depthTest && depthMask ? "w" : ""}${cull ? (cullFront ? "f" : "b") : ""}${colorBlend ? (blend : Int) : -1}';

	function cullFace():helix.platform.CullFace
		return cull ? (cullFront ? Front : Back) : None;

	// The program's blocks as they are now, with raylib's own values set: the matrices and the diffuse color.
	function values(p:Program, model:Matrix3D, diffuse:Array<Float>):Array<Null<Bytes>> {
		var modelView = Matrix3D.compose(model, view);
		p.writeNamed("mvp", Matrix3D.compose(modelView, projection).values);
		p.writeNamed("matModel", model.values);
		p.writeNamed("matView", view.values);
		p.writeNamed("matProjection", projection.values);
		if (p.declares("matNormal")) {
			var normal = new Matrix3D().copyFrom(model);
			normal.invert(normal);
			p.writeNamed("matNormal", normal.transpose(normal).values);
		}
		p.writeNamed("colDiffuse", diffuse);
		return [for (b in p.blocks) b == null ? null : b.sub(0, b.length)];
	}

	/** Draws the frame: each render texture's pass, then the screen's, then shows it unless told to wait for `present`. A frame ended
		and not shown yet is shown first.

		@param framebufferWidth  The screen's framebuffer width.
		@param framebufferHeight  Its height.
		@param show  Whether the screen's pass is shown as it ends; when false, `present` shows it. */
	public function draw(framebufferWidth:Int, framebufferHeight:Int, show:Bool):Void {
		flush();
		present();
		for (p in passes) {
			if (p.target == 0)
				graphics.beginFrame(framebufferWidth, framebufferHeight, p.clear);
			else
				graphics.beginTargetPass(p.target, (p.clear >> 16 & 255) / 255, (p.clear >> 8 & 255) / 255, (p.clear & 255) / 255, (p.clear >>> 24) / 255);
			upload();
			var width = p.target == 0 ? framebufferWidth : Std.int(p.width),
				height = p.target == 0 ? framebufferHeight : Std.int(p.height);
			var clipped:Null<Array<Float>> = null,
				port:Null<Array<Int>> = null;
			for (d in p.draws) {
				if (d.count == 0)
					continue;
				if (d.viewport != port) {
					port = d.viewport;
					if (port == null)
						graphics.applyViewport(0, 0, width, height);
					else
						graphics.applyViewport(port[0], port[1], port[2] < 1 ? 1 : port[2], port[3] < 1 ? 1 : port[3]);
				}
				if (d.scissor != clipped) {
					clipped = d.scissor;
					if (clipped == null)
						graphics.resetScissor();
					else
						clip(clipped, width / p.width, height / p.height, width, height);
				}
				var count = d.lines ? d.count - d.count % 2 : d.count - d.count % 3;
				var samplings = [for (t in d.textures) Textures.samplingOf(t)];
				graphics.draw(d.pipeline, d.buffers == null ? [buffer, constants] : d.buffers, d.indices, d.first, count, 0, 1, d.textures, samplings,
					d.uniforms);
			}
			if (p.target == 0) {
				graphics.endFrame();
				if (screenshots != null)
					screenshots.frameEnded();
				if (show)
					graphics.present();
				else
					unshown = true;
			} else
				graphics.endTargetPass();
		}
		for (b in retired)
			graphics.disposeBuffer(b);
		retired.resize(0);
		reset();
	}

	/** Frees a buffer once the frame is drawn, as draws asked for already may read it.

		@param buffer  The buffer. */
	public function retire(buffer:Int):Void {
		retired.push(buffer);
	}

	/** Shows the frame `draw` ended and didn't show; nothing when there is none. */
	public function present():Void {
		if (!unshown)
			return;
		unshown = false;
		graphics.present();
	}

	// Whether the screen's pass ended without being shown.
	var unshown = false;

	// A scissor in the pass's pixels from its top left, as the framebuffer's from its bottom left, within it.
	function clip(r:Array<Float>, scaleX:Float, scaleY:Float, width:Int, height:Int):Void {
		var left = Math.round(r[0] * scaleX),
			right = Math.round((r[0] + r[2]) * scaleX);
		var bottom = height - Math.round((r[1] + r[3]) * scaleY),
			top = height - Math.round(r[1] * scaleY);
		left = left < 0 ? 0 : left > width ? width : left;
		right = right < left ? left : right > width ? width : right;
		bottom = bottom < 0 ? 0 : bottom > height ? height : bottom;
		top = top < bottom ? bottom : top > height ? height : top;
		graphics.applyScissor(left, bottom, right - left, top - bottom);
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
		graphics.disposeBuffer(constants);
		for (b in retired)
			graphics.disposeBuffer(b);
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
	final scissor:Null<Array<Float>>;
	final viewport:Null<Array<Int>>;
	final textures:Array<Int>;
	final uniforms:Array<Null<Bytes>>;
}

private typedef Run = {
	final texture:Int;
	final lines:Bool;
	final first:Int;
	var count:Int;
}
