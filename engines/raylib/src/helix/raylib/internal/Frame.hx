package helix.raylib.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.IGraphics;
import helix.platform.Primitive;
import helix.platform.VertexFormat;

/** Records a frame's drawing as rlgl orders it, and draws it at the frame's end: each render texture's pass, then the screen's.

	Shapes, text and textures are immediate vertices, collected in one buffer, uploaded once in each pass; a mesh draws from its own
	buffers. A run of quads of one texture through the default shader, flat in z and each quad one color over a rectangle of the texture
	(every `DrawTexture*`, `DrawRectangle*` and glyph), is kept as sprites instead: a 52-byte record a quad, drawn as instances of one
	quad through the sprite shader, a third of the bytes and a quarter of the writes of its four vertices. Anything else keeps its
	vertices, and runs stay in order, so mixing them costs nothing. As in rlgl, immediate vertices wait in a batch until it is flushed (`flush`: a change of mode, matrices, shader, blending,
	scissor or pass, and the pass's end), and are drawn then with the state and the program's values as they are at that moment: rlgl's
	state calls (wire and point mode, culling, depth) don't flush, so they reach what is in the batch. A mesh is drawn as it is asked for, with the
	state then, ahead of the batch's vertices still waiting. */
@:noCompletion
class Frame {
	/** The bytes of an immediate vertex, raylib's batch vertex: a position, a texture coordinate and a normal as floats, and a color as
		four bytes. */
	static inline final STRIDE = 36;

	/** Each raylib attribute's place in an immediate vertex, in bytes. */
	static final OFFSETS = [
		"vertexPosition" => 0,
		"vertexTexCoord" => 12,
		"vertexNormal" => 20,
		"vertexColor" => 32
	];

	/** Each raylib attribute's format, in an immediate vertex, a mesh's buffer and the one record of `constants` alike: floats, but for a
		color's four bytes, as raylib feeds them. */
	static final FORMATS:Map<String, VertexFormat> = [
		"vertexPosition" => Float3,
		"vertexTexCoord" => Float2,
		"vertexNormal" => Float3,
		"vertexColor" => UByte4Norm,
		"vertexTangent" => Float4,
		"vertexTexCoord2" => Float2,
		"vertexBoneIds" => Float4,
		"vertexBoneIndices" => Float4,
		"vertexBoneWeights" => Float4
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

	/** rlgl's modes, as `rlBegin` takes them and a run of the batch keeps its vertices in: lines, triangles, and quads of four
		vertices each, drawn as two triangles through `quadIndices`. */
	public static inline final LINES = 1;

	public static inline final TRIANGLES = 4;
	public static inline final QUADS = 7;

	/** A run of sprites: quads kept as one record each, drawn as instances (`sprite.vs`). Never rlgl's mode, only a run's. */
	public static inline final SPRITES = 8;

	/** The bytes of a sprite's record: its four corners' x and y, its texture rectangle's u0, v0, u1 and v1 as floats, and its color as four
		bytes. */
	static inline final SPRITE_BYTES = 52;

	/** The bytes of the one record of `constants`. */
	static inline final CONSTANT_BYTES = 120;

	/** Where a matrix attribute's columns are in the one record of `constants`, in floats: each column 0, 0, 0, 1, GL's value for an
		attribute no buffer feeds. A matrix is a program's instance transforms (`DrawMeshInstanced`), fed only there. */
	static inline final MATRIX_CONSTANT = 14;

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
	// The sprites' records, their count, their stream buffer and its capacity, as the vertices' above.
	var spriteData = Bytes.alloc(SPRITE_BYTES * 1024);
	var sprites = 0;
	var spriteBuffer = 0;
	var spriteCapacity = 0;
	// The quad sprites are instances of: four corner numbers as a vertex buffer, and its six indices; 0 until a sprite is drawn.
	var spriteQuad = 0;
	var spriteIndices = 0;

	/** Gives the sprite shader (`Defaults.spriteShader`): set by `Sprites.register` as a module adding quads starts, null in a program
		adding none, which then links neither the shader nor the sprite path. It has no initial value, so Frame's own start (hxcpp boots
		the classes in its order) never resets what the module set. */
	public static var spriteShader:Null<Void->helix.services.shaders.Shader>;

	// The sprite shader's program, made when first drawn through.
	var spriteProgram:Null<Program> = null;
	// A quad's corners as they arrive through `vertex`, kept until the fourth decides whether they are a sprite: how many so far, and
	// each one's texture, position, texture coordinate and color.
	var pending = 0;
	final pendingTexture = [0, 0, 0, 0];
	final pendingX = [0., 0, 0, 0];
	final pendingY = [0., 0, 0, 0];
	final pendingZ = [0., 0, 0, 0];
	final pendingU = [0., 0, 0, 0];
	final pendingV = [0., 0, 0, 0];
	final pendingColor = [0, 0, 0, 0];
	#if js
	// The buffers' floats, written through views rather than Bytes.setFloat; remade when a buffer grows.
	var floats:js.lib.Float32Array;
	var spriteFloats:js.lib.Float32Array;
	#end
	final passes:Array<Pass> = [];
	var pass:Pass;
	// The batch: runs of immediate vertices waiting to be drawn, and the one being added to.
	final batch:Array<Run> = [];

	var open:Null<Run> = null;

	/** raylib's default shader. */
	public final defaultProgram:Program;

	/** The white texture shapes draw with, and a texture without an image reads as. */
	public var white(default, null):Int;

	// The index buffer quads are drawn through, each quad's first, second and third corners then its first, third and fourth; 0 until a
	// quad is drawn. It holds quadCapacity quads, from the batch's first vertex.
	var quadIndices = 0;

	var quadCapacity = 0;

	// One record of zeros, for the attributes in CONSTANTS, read as an instance's so every vertex has it.
	var constants:Int;

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

	/** Gives the points a run of the batch's triangles is drawn as, in rlgl's point mode (`rlEnablePointMode`): null while it is off.
		`rlEnablePointMode` sets it to `pointsOfRun`, so a program drawing no points links none of it. It receives the run's first vertex,
		its vertex count and whether they are quads, and returns the first vertex and the count of the points. */
	public var pointRun:Null<(first:Int, count:Int, quads:Bool) -> Array<Int>> = null;

	/** Gives the points a mesh's triangles are drawn as, in rlgl's point mode: null while it is off. `rlEnablePointMode` sets it to
		`pointsOfMesh`. It receives the mesh, its transform and whether it is drawn as instances, and returns the index buffer of the points
		(0 for none: the vertices in order) and their count. */
	public var pointMesh:Null<(mesh:helix.raylib.Mesh, model:Matrix3D, instanced:Bool) -> Array<Int>> = null;

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

	/** The mode of the draw call rlgl's next vertices join (`RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`), as `rlBegin` sets it; each flush
		starts a new one in `RL_QUADS`, as rlgl's batch does. */
	public var drawMode = QUADS;

	/** The texture id of the draw call rlgl's next vertices join, as `rlSetTexture` and `rlBegin` set it; 0 for the white texture, as
		each flush starts. */
	public var drawTexture = 0;

	// Where a vertex goes under the transform.
	final moved = new helix.math.Vector3D();

	/** raylib's `BLEND_ALPHA` as rlgl sets it, `glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)`: alpha blended by the same factors as
		the color, so a render texture's alpha becomes alpha * alpha + its own * (1 - alpha). */
	public static final RAYLIB_ALPHA = new Blend(SourceAlpha, OneMinusSourceAlpha);

	/** How the next draws blend, as rlgl's `rlSetBlendMode` last set it. */
	public var blend:Blend = RAYLIB_ALPHA;

	/** The blend mode rlgl's `rlSetBlendMode` last set (`BLEND_*`), `BLEND_ALPHA` as raylib starts. */
	public var blendMode = 0;

	/** The GL factors and equations `BLEND_CUSTOM` and `BLEND_CUSTOM_SEPARATE` blend by, as rlgl keeps them: `rlSetBlendFactors`'
		source, destination and equation, then `rlSetBlendFactorsSeparate`'s six; 0 as raylib starts. */
	public final customBlend = [for (_ in 0...9) 0];

	/** Whether `customBlend` changed since `rlSetBlendMode` last set a mode, so setting a custom mode again applies it. */
	public var customBlendChanged = false;

	/** The color channels the next draws write, rlgl's `rlColorMask`: all, as raylib starts. */
	public var colorMask:ColorChannels = All;

	/** The rectangle the next draws are clipped to, `BeginScissorMode`'s: x, y, width and height in the pass's pixels from its top left;
		null for none. */
	public var scissor:Null<Array<Float>> = null;

	/** What runs each frame as the screen's pass ends, before the frame is shown, in the order added: what reads the frame back, as the
		screenshots do once a program asks for one (`Runtime.screenshots`). A program asking for none links none. */
	public final ended:Array<() -> Void> = [];

	/** What runs each frame before its passes are drawn, in the order added: what the passes read and only a program asking for it
		writes, as the bone palette once a program poses a model (`Skinning`). */
	public final drawing:Array<() -> Void> = [];

	/** Draws a mesh `UpdateModelAnimation` posed, skinned: set by the first call (`Skinning`), null before, so a program without one links
		none of it. Receives the mesh, the shader, the material, the transform, the diffuse color, and the instances' buffer and count;
		returns false for a draw it leaves to be drawn as it is. */
	public var skinned:Null<(mesh:helix.raylib.Mesh, shader:helix.raylib.Shader, material:helix.raylib.Material, model:Matrix3D, diffuse:Array<Float>,
			instances:Int, instanceCount:Int) -> Bool> = null;

	/** Creates the frame, with raylib's default shader and the white texture.

		@param graphics  The graphics. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
		defaultProgram = new Program(graphics, Defaults.shader());
		program = defaultProgram;
		#if js
		floats = new js.lib.Float32Array(data.getData());
		spriteFloats = new js.lib.Float32Array(spriteData.getData());
		#end
		makeOwn();
		view = new Matrix3D();
		projection = new Matrix3D();
		pass = {
			target: 0,
			clear: 0xff000000,
			width: 1,
			height: 1,
			draws: [],
			updates: []
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

	// The snapshots of the frame's draws' blocks, one a draw, kept from frame to frame so a draw allocates nothing once a frame's worth
	// exist: each is taken again after the frame is drawn.
	final snapshots:Array<helix.services.shaders.ShaderSnapshot> = [];
	var snapshotCount = 0;

	// After a frame is drawn: nothing recorded, the screen's pass alone.
	function reset():Void {
		snapshotCount = 0;
		drawCount = 0;
		intCount = 0;
		var screen = passes.length > 0 ? passes[passes.length - 1] : null;
		passes.resize(0);
		vertices = 0;
		sprites = 0;
		pending = 0;
		pass = {
			target: 0,
			clear: 0xff000000,
			width: screen == null ? 1 : screen.width,
			height: screen == null ? 1 : screen.height,
			draws: [],
			updates: []
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

	/** Starts drawing into a render target, as its own pass, until `toScreen`: over what it holds, as raylib's render textures keep it,
		unless `clear` clears it.

		@param target  The render target's handle.
		@param width  Its width.
		@param height  Its height. */
	public function toTarget(target:Int, width:Int, height:Int):Void {
		flush();
		pass = {
			target: target,
			clear: null,
			width: width,
			height: height,
			draws: [],
			updates: []
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

	/** Replaces a rectangle of a texture on the GPU in the frame's order, as rlgl's `rlUpdateTexture` does at once: in a render
		texture's pass, between its draws so far and those after (and the batch waiting); drawing on the screen, after the render texture
		passes so far and before those begun later. The screen's draws all see it, as rlgl's batch drawn after it does.

		@param texture  The texture's GPU handle.
		@param x  The rectangle's left edge, in texels.
		@param y  Its top edge.
		@param width  Its width.
		@param height  Its height.
		@param rgba  Its texels, 8-bit RGBA, rows top first. */
	public function updateTexture(texture:Int, x:Int, y:Int, width:Int, height:Int, rgba:Bytes):Void {
		var update:Update = {
			texture: texture,
			x: x,
			y: y,
			width: width,
			height: height,
			rgba: rgba
		};
		if (pass.target != 0) {
			if (pass.draws.length == 0) {
				pass.updates.push(update);
				return;
			}
			// Drawn into already: those draws keep the old texels, and the pass goes on after the update, keeping what they drew. The
			// batch waiting moves on with it, as rlgl's draws after the update.
			var next:Pass = {
				target: pass.target,
				clear: null,
				width: pass.width,
				height: pass.height,
				draws: [],
				updates: [update]
			};
			passes.insert(passes.indexOf(pass) + 1, next);
			pass = next;
			return;
		}
		var last = passes.length > 1 ? passes[passes.length - 2] : null;
		if (last != null && last.target == -1)
			last.updates.push(update);
		else
			passes.insert(passes.length - 1, {
				target: -1,
				clear: 0,
				width: 0,
				height: 0,
				draws: [],
				updates: [update]
			});
	}

	/** Returns whether a texture is updated in this frame's passes (`updateTexture`), not yet drawn.

		@param texture  The texture's GPU handle.
		@return  True when an update of it waits. */
	public function isUpdating(texture:Int):Bool {
		for (p in passes)
			for (u in p.updates)
				if (u.texture == texture)
					return true;
		return false;
	}

	/** Calls a function once the frame is drawn (`draw`), after its passes.

		@param call  The function. */
	public function afterDraw(call:() -> Void):Void {
		drawn.push(call);
	}

	// What waits for the frame to be drawn.
	final drawn:Array<() -> Void> = [];

	/** Draws the batch, rlgl's `rlDrawRenderBatchActive`: its runs into the pass, each through the current program, matrices and state
		(in wire mode, its triangles as their edges, those culling leaves; in point mode, their corners). */
	public function flush():Void {
		drawMode = QUADS;
		drawTexture = 0;
		// A quad left short of its corners isn't drawn, as rlgl's batch leaves one.
		pending = 0;
		if (eyes != null)
			eyes(() -> drawBatch(), false);
		else if (batch.length > 0)
			drawBatch();
		batch.resize(0);
		open = null;
	}

	/** Draws what is added once for each eye, as rlgl's stereo rendering does: null while it is off, set by `rlEnableStereoRender`
		(`Stereo`), so a program not drawing in stereo links none of it. It receives what adds the draws, called once an eye, and whether
		they are a mesh's (raylib's `DrawMesh` moves only its mvp to each eye, through `meshView` and `meshProjection`). */
	public var eyes:Null<(add:() -> Void, mesh:Bool)->Void> = null;

	/** The view a mesh's mvp is made with in place of `view`, an eye's in stereo; null otherwise. */
	public var meshView:Null<Matrix3D> = null;

	/** The projection a mesh's mvp is made with in place of `projection`, an eye's in stereo; null otherwise. */
	public var meshProjection:Null<Matrix3D> = null;

	// The batch's runs as draws in the pass, through the current program, matrices and state.
	function drawBatch():Void {
		var m = wire && cull ? Matrix3D.compose(view, projection, viewProjection).values : null;
		for (run in batch) {
			if (run.mode == SPRITES) {
				if (run.count == 0)
					continue;
				// Wire and point modes read vertices: the sprites' written out as quads, drawn as a run of them.
				if (pointRun == null && !wire) {
					pass.draws.push(spriteDraw(run.texture, run.first, run.count));
					continue;
				}
				run = expand(run);
			}
			var quads = run.mode == QUADS, lines = run.mode == LINES;
			// A quad's vertices are drawn once all four are in.
			var count = quads ? run.count - run.count % 4 : run.count;
			if (count == 0)
				continue;
			// GL's point mode: each triangle's corners, as points.
			if (pointRun != null && !lines) {
				var points = pointRun(run.first, count, quads);
				var d = immediate(run.texture, Points, points[0], false);
				d.count = points[1];
				pass.draws.push(d);
				continue;
			}
			if (quads && !wire) {
				var d = immediate(run.texture, Triangles, Std.int(run.first / 4) * 6, true);
				d.count = Std.int(count / 4) * 6;
				pass.draws.push(d);
				continue;
			}
			if (!wire || lines) {
				var d = immediate(run.texture, lines ? Lines : Triangles, run.first, false);
				d.count = count;
				pass.draws.push(d);
				continue;
			}
			// GL's line mode: each triangle's edges, written after the batch's vertices, unless culling drops it.
			var d = immediate(run.texture, Lines, vertices, false);
			for (k in 0...Std.int(corners(count, quads) / 3)) {
				var a = corner(run.first, quads, k * 3) * STRIDE,
					b = corner(run.first, quads, k * 3 + 1) * STRIDE,
					c = corner(run.first, quads, k * 3 + 2) * STRIDE;
				if (m != null
					&& culled(m, data.getFloat(a), data.getFloat(a + 4), data.getFloat(a + 8), data.getFloat(b), data.getFloat(b + 4), data.getFloat(b + 8),
						data.getFloat(c), data.getFloat(c + 4), data.getFloat(c + 8)))
					continue;
				copyVertex(a);
				copyVertex(b);
				copyVertex(b);
				copyVertex(c);
				copyVertex(c);
				copyVertex(a);
				d.count += 6;
			}
			pass.draws.push(d);
		}
	}

	// The corners of a run's triangles: each quad's two triangles have six.
	static inline function corners(count:Int, quads:Bool):Int
		return quads ? Std.int(count / 4) * 6 : count;

	// The vertex at a corner of a run's triangles: a quad's first, second and third corners, then its first, third and fourth.
	static inline function corner(first:Int, quads:Bool, k:Int):Int {
		if (!quads)
			return first + k;
		var j = k % 6;
		return first + Std.int(k / 6) * 4 + (j < 3 ? j : j == 3 ? 0 : j - 1);
	}

	// The quads' index buffer, made to hold the quads up to a vertex, the batch's vertices all at most.
	function quadIndexBuffer(end:Int):Int {
		var needed = Std.int((end + 3) / 4);
		if (needed <= quadCapacity)
			return quadIndices;
		if (quadIndices != 0)
			retire(quadIndices);
		quadCapacity = Std.int(Math.max(needed, data.length / STRIDE / 4));
		var bytes = Bytes.alloc(quadCapacity * 24);
		for (q in 0...quadCapacity) {
			var at = q * 24, v = q * 4;
			bytes.setInt32(at, v);
			bytes.setInt32(at + 4, v + 1);
			bytes.setInt32(at + 8, v + 2);
			bytes.setInt32(at + 12, v);
			bytes.setInt32(at + 16, v + 2);
			bytes.setInt32(at + 20, v + 3);
		}
		quadIndices = graphics.createStaticBuffer(bytes, bytes.length, true);
		return quadIndices;
	}

	// A sprite run's records written out as a run of quads after the batch's vertices, for the modes that read vertices.
	function expand(run:Run):Run {
		vertices = (vertices + 3) & ~3;
		var quads:Run = {
			texture: run.texture,
			mode: QUADS,
			first: vertices,
			count: run.count * 4
		};
		for (i in run.first...run.first + run.count) {
			var at = i * SPRITE_BYTES;
			var u0 = spriteData.getFloat(at + 32),
				v0 = spriteData.getFloat(at + 36),
				u1 = spriteData.getFloat(at + 40),
				v1 = spriteData.getFloat(at + 44);
			var r = spriteData.get(at + 48),
				g = spriteData.get(at + 49),
				b = spriteData.get(at + 50),
				a = spriteData.get(at + 51);
			for (c in 0...4)
				addVertex(run.texture, QUADS, spriteData.getFloat(at + c * 8), spriteData.getFloat(at + c * 8 + 4), 0,
					c < 2 ? u0 : u1, c == 0 || c == 3 ? v0 : v1, r, g, b, a);
		}
		return quads;
	}

	// A draw of a run of sprites, instances of the one quad through the sprite program, with the current matrices and state.
	function spriteDraw(texture:Int, first:Int, count:Int):Draw {
		var p = spriteProgram;
		if (p == null)
			p = spriteProgram = new Program(graphics, spriteShader());
		if (spriteQuad == 0) {
			var corners = Bytes.alloc(16);
			for (c in 0...4)
				corners.setFloat(c * 4, c);
			spriteQuad = graphics.createStaticBuffer(corners, 16, false);
			var indices = Bytes.alloc(24);
			for (k => i in [0, 1, 2, 0, 2, 3])
				indices.setInt32(k * 4, i);
			spriteIndices = graphics.createStaticBuffer(indices, 24, true);
		}
		var state = states();
		var pipeline = p.pipeline('s$state', () -> graphics.createPipeline({
			shader: p.handle,
			buffers: [
				{stride: 4, instanced: false, attributes: [{slot: 0, format: Float1, offset: 0}]},
				{
					stride: SPRITE_BYTES,
					instanced: true,
					attributes: [
						{slot: 1, format: Float4, offset: 0},
						{slot: 2, format: Float4, offset: 16},
						{slot: 3, format: Float4, offset: 32},
						{slot: 4, format: UByte4Norm, offset: 48}
					]
				}
			],
			primitive: Triangles,
			indexed: true,
			blend: colorBlend ? blend : Blend.OPAQUE,
			colorWrite: colorMask,
			depthTest: depthTest ? LessEqual : Off,
			depthWrite: depthTest && depthMask,
			cull: cullFace(),
			clockwise: false,
			depthOnly: false,
			flip: ClipScale,
			flipBlockSlot: p.flipSlot,
			flipOffset: p.flipOffset
		}));
		var textures = p.bindTextures([]);
		if (p.texture0 >= 0)
			textures[p.texture0] = texture;
		return {
			pipeline: pipeline,
			buffers: null,
			sprite: true,
			indices: spriteIndices,
			first: 0,
			count: 6,
			texture: texture,
			primitive: Triangles,
			scissor: scissor,
			viewport: viewport,
			textures: textures,
			cubes: p.cubes,
			uniforms: values(p, new Matrix3D(), [1, 1, 1, 1]),
			instances: count,
			firstInstance: first
		};
	}

	// The frame's own GPU things: the white texture and the constants' record (an identity matrix for the attributes no buffer feeds).
	function makeOwn():Void {
		var texel = Bytes.alloc(4);
		texel.fill(0, 4, 255);
		white = graphics.createTexture(1, 1, [texel]);
		var record = Bytes.alloc(CONSTANT_BYTES);
		record.fill(0, CONSTANT_BYTES, 0);
		for (column in 0...4)
			record.setFloat((MATRIX_CONSTANT + column * 4 + 3) * 4, 1);
		constants = graphics.createStaticBuffer(record, CONSTANT_BYTES, false);
	}

	/** Makes the frame's own GPU things again after the GPU's context was lost and given back (`Event.GraphicsRestored`): the white
		texture and the constants, gone with the context; the quads' indices, made again when next needed. The vertex buffer, the programs
		and the pipelines keep their handles, remade by the platform. */
	public function graphicsRestored():Void {
		makeOwn();
		quadIndices = 0;
		quadCapacity = 0;
		spriteQuad = spriteIndices = 0;
	}

	/** Flushes the batch, as a change rlgl flushes for does: `flush`. */
	public inline function cut():Void {
		flush();
	}

	/** Adds an immediate vertex.

		@param texture  The texture.
		@param mode  What it makes, with the vertices before it in its run: `LINES`, `TRIANGLES` or `QUADS`.
		@param x  Position.
		@param y  Position.
		@param z  Position.
		@param u  Texture coordinate.
		@param v  Texture coordinate.
		@param color  Its color. */
	public function vertex(texture:Int, mode:Int, x:Float, y:Float, z:Float, u:Float, v:Float, color:helix.raylib.Color):Void {
		if (transform != null) {
			transform.transformPoint(x, y, z, moved);
			x = moved.x;
			y = moved.y;
			z = moved.z;
		}
		if (mode == QUADS && program == defaultProgram && spriteShader != null) {
			// A quad's corners wait for the fourth: a sprite when all four are one texture and color, flat, and read the texture's rectangle
			// corner by corner as a sprite's rectangle; otherwise the four vertices they always were.
			var i = pending++;
			pendingTexture[i] = texture;
			pendingX[i] = x;
			pendingY[i] = y;
			pendingZ[i] = z;
			pendingU[i] = u;
			pendingV[i] = v;
			pendingColor[i] = color.r | color.g << 8 | color.b << 16 | color.a << 24;
			if (pending < 4)
				return;
			pending = 0;
			if (isSprite()) {
				sprite(texture, pendingU[0], pendingV[0], pendingU[2], pendingV[2], color.r, color.g, color.b, color.a);
				return;
			}
			for (c in 0...4) {
				var packed = pendingColor[c];
				addVertex(pendingTexture[c], QUADS, pendingX[c], pendingY[c], pendingZ[c], pendingU[c], pendingV[c], packed & 255, packed >> 8 & 255,
					packed >> 16 & 255, packed >>> 24);
			}
			return;
		}
		addVertex(texture, mode, x, y, z, u, v, color.r, color.g, color.b, color.a);
	}

	/** Adds a quad of one texture, one color and a rectangle of the texture, its corners in rlgl's order (`DrawTexturePro`'s): a sprite
		record when it draws as one (the default shader, flat under the transform pushed, the sprite shader given), else its four vertices.
		What `vertex` decides from four calls, decided at once.

		@param texture  The texture.
		@param ax  The first corner.
		@param ay  The first corner.
		@param bx  The second.
		@param by  The second.
		@param cx  The third.
		@param cy  The third.
		@param ex  The fourth.
		@param ey  The fourth.
		@param u0  The rectangle's left, at the first and second corners.
		@param v0  Its top, at the first and fourth.
		@param u1  Its right, at the third and fourth.
		@param v1  Its bottom, at the second and third.
		@param color  Its color. */
	public function quad(texture:Int, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, ex:Float, ey:Float, u0:Float, v0:Float, u1:Float, v1:Float,
			color:helix.raylib.Color):Void {
		if (transform != null || program != defaultProgram || spriteShader == null) {
			vertex(texture, QUADS, ax, ay, 0, u0, v0, color);
			vertex(texture, QUADS, bx, by, 0, u0, v1, color);
			vertex(texture, QUADS, cx, cy, 0, u1, v1, color);
			vertex(texture, QUADS, ex, ey, 0, u1, v0, color);
			return;
		}
		var at = spriteRoom(texture);
		putSprite(at, ax);
		putSprite(at + 4, ay);
		putSprite(at + 8, bx);
		putSprite(at + 12, by);
		putSprite(at + 16, cx);
		putSprite(at + 20, cy);
		putSprite(at + 24, ex);
		putSprite(at + 28, ey);
		putSprite(at + 32, u0);
		putSprite(at + 36, v0);
		putSprite(at + 40, u1);
		putSprite(at + 44, v1);
		putSpriteByte(at + 48, color.r);
		putSpriteByte(at + 49, color.g);
		putSpriteByte(at + 50, color.b);
		putSpriteByte(at + 51, color.a);
	}

	// Whether the four corners waiting make a sprite: one texture, one color, z 0, and texture coordinates u0, v0, then u0, v1, then u1,
	// v1, then u1, v0.
	function isSprite():Bool {
		return pendingTexture[1] == pendingTexture[0]
			&& pendingTexture[2] == pendingTexture[0]
			&& pendingTexture[3] == pendingTexture[0]
			&& pendingColor[1] == pendingColor[0]
			&& pendingColor[2] == pendingColor[0]
			&& pendingColor[3] == pendingColor[0]
			&& pendingZ[0] == 0
			&& pendingZ[1] == 0
			&& pendingZ[2] == 0
			&& pendingZ[3] == 0
			&& pendingU[1] == pendingU[0]
			&& pendingV[2] == pendingV[1]
			&& pendingU[3] == pendingU[2]
			&& pendingV[3] == pendingV[0];
	}

	// Where the next sprite's record goes, in a run of sprites of its texture, the buffer grown to hold it.
	function spriteRoom(texture:Int):Int {
		if (open == null || open.texture != texture || open.mode != SPRITES) {
			open = {
				texture: texture,
				mode: SPRITES,
				first: sprites,
				count: 0
			};
			batch.push(open);
		}
		open.count++;
		var at = sprites++ * SPRITE_BYTES;
		if (at + SPRITE_BYTES > spriteData.length) {
			var grown = Bytes.alloc(spriteData.length * 2);
			grown.blit(0, spriteData, 0, at);
			spriteData = grown;
			#if js
			spriteFloats = new js.lib.Float32Array(spriteData.getData());
			#end
		}
		return at;
	}

	// Adds a sprite from the corners waiting: its record, in a run of sprites of its texture.
	function sprite(texture:Int, u0:Float, v0:Float, u1:Float, v1:Float, r:Int, g:Int, b:Int, a:Int):Void {
		var at = spriteRoom(texture);
		for (c in 0...4) {
			putSprite(at + c * 8, pendingX[c]);
			putSprite(at + c * 8 + 4, pendingY[c]);
		}
		putSprite(at + 32, u0);
		putSprite(at + 36, v0);
		putSprite(at + 40, u1);
		putSprite(at + 44, v1);
		putSpriteByte(at + 48, r);
		putSpriteByte(at + 49, g);
		putSpriteByte(at + 50, b);
		putSpriteByte(at + 51, a);
	}

	// Writes a float into the sprites' buffer.
	inline function putSprite(at:Int, value:Float):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(spriteData.getData(), at, value);
		#elseif js
		spriteFloats[at >> 2] = value;
		#else
		spriteData.setFloat(at, value);
		#end
	}

	// Writes a byte into the sprites' buffer.
	inline function putSpriteByte(at:Int, value:Int):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_byte(spriteData.getData(), at, value);
		#else
		spriteData.set(at, value);
		#end
	}

	// Adds an immediate vertex to the run of its texture and mode, starting one when the open run is another's.
	function addVertex(texture:Int, mode:Int, x:Float, y:Float, z:Float, u:Float, v:Float, r:Int, g:Int, b:Int, a:Int):Void {
		if (open == null || open.texture != texture || open.mode != mode) {
			// A run of quads starts at a multiple of four, where the quads' indices for it start.
			if (mode == QUADS)
				vertices = (vertices + 3) & ~3;
			open = {
				texture: texture,
				mode: mode,
				first: vertices,
				count: 0
			};
			batch.push(open);
		}
		open.count++;
		var at = room();
		put(at, x);
		put(at + 4, y);
		put(at + 8, z);
		put(at + 12, u);
		put(at + 16, v);
		put(at + 20, nx);
		put(at + 24, ny);
		put(at + 28, nz);
		data.set(at + 32, r);
		data.set(at + 33, g);
		data.set(at + 34, b);
		data.set(at + 35, a);
		vertices++;
	}

	// Writes a float into the buffer where room made room for it: natively without Bytes.setFloat's bounds check and call, in a page
	// through the buffer's float view.
	inline function put(at:Int, value:Float):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(data.getData(), at, value);
		#elseif js
		floats[at >> 2] = value;
		#else
		data.setFloat(at, value);
		#end
	}

	/** Removes the last vertices added, a shape left short of its corners.

		@param count  How many, at most those of the run being added to. */
	public function dropVertices(count:Int):Void {
		// The corners still waiting first, then the open run's: a run of sprites by whole sprites.
		var waiting = count < pending ? count : pending;
		pending -= waiting;
		count -= waiting;
		if (count <= 0 || open == null)
			return;
		if (open.mode == SPRITES) {
			var n = Std.int(count / 4);
			if (n > open.count)
				n = open.count;
			open.count -= n;
			sprites -= n;
			return;
		}
		var n = count < open.count ? count : open.count;
		open.count -= n;
		vertices -= n;
	}

	// Where the next vertex goes in the buffer, grown to hold it.
	function room():Int {
		var at = vertices * STRIDE;
		if (at + STRIDE > data.length) {
			var grown = Bytes.alloc(data.length * 2);
			grown.blit(0, data, 0, at);
			data = grown;
			#if js
			floats = new js.lib.Float32Array(data.getData());
			#end
		}
		return at;
	}

	// Adds a copy of the vertex at a byte offset in the buffer.
	function copyVertex(from:Int):Void {
		var at = room();
		data.blit(at, data, from, STRIDE);
		vertices++;
	}

	/** Returns the points a run of the batch's triangles is drawn as in point mode, `pointRun` while it is on: each whole triangle's
		corners, in order (a quad's two triangles', six); with culling, those of the triangles it leaves. Those not in the run in order are
		copied after the batch's vertices, as GL culls the triangles whose corners it draws.

		@param first  The run's first vertex.
		@param count  Its vertex count.
		@param quads  Whether its vertices are quads.
		@return  The first vertex of the points and their count. */
	public function pointsOfRun(first:Int, count:Int, quads:Bool):Array<Int> {
		if (!cull && !quads)
			return [first, count - count % 3];
		var m = cull ? Matrix3D.compose(view, projection, viewProjection).values : null,
			from = vertices;
		for (k in 0...Std.int(corners(count, quads) / 3)) {
			var a = corner(first, quads, k * 3) * STRIDE,
				b = corner(first, quads, k * 3 + 1) * STRIDE,
				c = corner(first, quads, k * 3 + 2) * STRIDE;
			if (m != null
				&& culled(m, data.getFloat(a), data.getFloat(a + 4), data.getFloat(a + 8), data.getFloat(b), data.getFloat(b + 4), data.getFloat(b + 8),
					data.getFloat(c), data.getFloat(c + 4), data.getFloat(c + 8)))
				continue;
			copyVertex(a);
			copyVertex(b);
			copyVertex(c);
		}
		return [from, vertices - from];
	}

	/** Returns the points a mesh's triangles are drawn as in point mode, `pointMesh` while it is on: each index of its triangles, or
		each vertex of its whole triangles when it has no indices, as GL draws them; with culling, the corners of the triangles it
		leaves, from an index buffer made for the frame.

		Instances are drawn whole, culling not found for them, as in wire mode.
		@param mesh  The mesh, uploaded.
		@param model  Its transform.
		@param instanced  Whether it is drawn as instances.
		@return  The index buffer of the points (0 for none) and their count. */
	public function pointsOfMesh(mesh:helix.raylib.Mesh, model:Matrix3D, instanced:Bool):Array<Int> {
		var indices = mesh.indices;
		if (!cull || instanced)
			return indices != null ? [mesh.gpu.indexBuffer, mesh.triangleCount * 3] : [0, mesh.vertexCount - mesh.vertexCount % 3];
		var m = Matrix3D.compose(Matrix3D.compose(model, view, viewProjection), projection, viewProjection).values;
		var p = mesh.animVertices != null ? mesh.animVertices : mesh.vertices, corners = [];
		for (k in 0...(indices != null ? mesh.triangleCount : Std.int(mesh.vertexCount / 3))) {
			var a = indices == null ? k * 3 : indices[k * 3],
				b = indices == null ? k * 3 + 1 : indices[k * 3 + 1],
				c = indices == null ? k * 3 + 2 : indices[k * 3 + 2];
			if (!culled(m, p[a * 3], p[a * 3 + 1], p[a * 3 + 2], p[b * 3], p[b * 3 + 1], p[b * 3 + 2], p[c * 3], p[c * 3 + 1], p[c * 3 + 2]))
				for (i in [a, b, c])
					corners.push(i);
		}
		if (corners.length == 0)
			return [0, 0];
		var bytes = Bytes.alloc(corners.length * 4);
		for (i => index in corners)
			bytes.setInt32(i * 4, index);
		var buffer = graphics.createStaticBuffer(bytes, bytes.length, true);
		retire(buffer);
		return [buffer, corners.length];
	}

	// A draw of immediate vertices from first, through the current program, matrices and state; indexed, of quads through the quads'
	// indices, first and the count then being indices.
	function immediate(texture:Int, primitive:Primitive, first:Int, indexed:Bool):Draw {
		var p = program, state = states();
		var key = 'i${indexed ? "x" : ""}${(primitive : Int)}$state';
		var pipeline = p.pipeline(key, () -> graphics.createPipeline({
			shader: p.handle,
			buffers: [
				{
					stride: STRIDE,
					instanced: false,
					attributes: [
						for (i => name in p.attributes)
							if (OFFSETS.exists(name)) {slot: i, format: FORMATS.get(name), offset: OFFSETS.get(name)}
					]
				},
				{
					stride: CONSTANT_BYTES,
					instanced: true,
					attributes: constantAttributes(p.attributes)
				}
			],
			primitive: primitive,
			indexed: indexed,
			blend: colorBlend ? blend : Blend.OPAQUE,
			colorWrite: colorMask,
			depthTest: depthTest ? LessEqual : Off,
			depthWrite: depthTest && depthMask,
			cull: cullFace(),
			clockwise: false,
			depthOnly: false,
			flip: ClipScale,
			flipBlockSlot: p.flipSlot,
			flipOffset: p.flipOffset
		}));
		var textures = p.bindTextures([]);
		if (p.texture0 >= 0)
			textures[p.texture0] = texture;
		var model = new Matrix3D();
		return {
			pipeline: pipeline,
			buffers: null,
			indices: indexed ? quadIndexBuffer(vertices) : 0,
			first: first,
			count: 0,
			texture: texture,
			primitive: primitive,
			scissor: scissor,
			viewport: viewport,
			textures: textures,
			cubes: p.cubes,
			uniforms: values(p, model, [1, 1, 1, 1]),
			instances: 1
		};
	}

	// The attributes the constants' one record feeds: those immediate vertices don't carry, and each matrix's columns.
	static function constantAttributes(names:Array<String>):Array<helix.platform.VertexAttribute> {
		var attributes:Array<helix.platform.VertexAttribute> = [];
		for (i => name in names)
			if (CONSTANTS.exists(name))
				attributes.push({slot: i, format: FORMATS.get(name), offset: CONSTANTS.get(name) * 4});
			else if (isMatrix(names, i))
				for (column in 0...4)
					attributes.push({slot: i + column, format: Float4, offset: (MATRIX_CONSTANT + column * 4) * 4});
		return attributes;
	}

	// Whether a program's attribute at a slot is a mat4, its other columns' slots following it unnamed.
	static function isMatrix(names:Array<String>, slot:Int):Bool
		return names[slot] != "" && slot + 1 < names.length && names[slot + 1] == "";

	/** Draws a mesh.

		@param mesh  The mesh, uploaded.
		@param p  The program.
		@param model  Its transform.
		@param diffuse  The diffuse color, 0 to 1 each.
		@param textures  The texture at each of the program's slots: a GPU handle (0 for white), or -1 for the program's own
			(`SetShaderValueTexture`'s).
		@param instances  Optional. The instances' transforms, a static buffer of 16 floats each, column by column, fed to the program's
			mat4 attribute; 0 for one instance, the attribute fed GL's default.
		@param instanceCount  Optional. How many instances; defaults to 1. */
	public function mesh(mesh:helix.raylib.Mesh, p:Program, model:Matrix3D, diffuse:Array<Float>, textures:Array<Int>, instances:Int = 0,
			instanceCount:Int = 1):Void {
		meshBuffers = null;
		// In point mode, the mesh's triangles drawn as their corners: those culling leaves, found here, as GL's point mode culls the
		// triangles whose corners it draws.
		var points:Null<Array<Int>> = null;
		if (pointMesh != null) {
			points = pointMesh(mesh, model, instances != 0);
			if (points[1] == 0)
				return;
		}
		// In wire mode, the mesh's triangles drawn as their edges, from an index buffer of them: those culling leaves, found here, as GL's
		// line mode culls the triangles it outlines.
		var edges = 0, edgeCount = mesh.triangleCount * 6;
		if (wire && cull && instances == 0) {
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
		var primitive:Primitive = points != null ? Points : wire ? Lines : Triangles;
		// Point mode and wire mode are never both on: each ends the other, as GL's one polygon mode.
		var indexed = points != null ? points[0] != 0 : wire || mesh.gpu.indexBuffer != 0;
		var key = meshKey(indexed, primitive, instances != 0);
		var pipeline = p.cached(key);
		if (pipeline == -1)
			pipeline = meshPipeline(p, key, primitive, indexed, instances);
		// The draw's textures and buffers, from the frame's pool: read when the frame is drawn, taken again after.
		var bound = p.bindTextures(ints());
		for (slot => t in textures)
			if (t >= 0 && slot < bound.length)
				bound[slot] = t;
		for (i in 0...bound.length)
			if (bound[i] == 0)
				bound[i] = white;
		// A buffer an attribute: the platform takes eight, as many as raylib's attributes.
		var names = p.attributes, buffers = ints();
		for (i => name in names)
			if (isMatrix(names, i))
				buffers.push(instances != 0 ? instances : constants);
			else if (name != "")
				buffers.push(Models.buffer(mesh, MESH_BUFFERS.get(name)));
		meshBuffers = buffers;
		var indices = points != null ? points[0] : wire ? edges : mesh.gpu.indexBuffer,
			count = points != null ? points[1] : wire ? edgeCount : indexed ? mesh.triangleCount * 3 : mesh.vertexCount;
		if (eyes != null)
			meshEyes(pipeline, buffers, indices, count, primitive, bound, p, model, diffuse, instanceCount);
		else
			addMesh(pipeline, buffers, indices, count, primitive, bound, p, model, diffuse, instanceCount);
	}

	// A mesh's draw, in the pass: its blocks captured as they are now.
	function addMesh(pipeline:Int, buffers:Array<Int>, indices:Int, count:Int, primitive:Primitive, bound:Array<Int>, p:Program, model:Matrix3D,
			diffuse:Array<Float>, instanceCount:Int):Void {
		var d = drawCount < drawPool.length ? drawPool[drawCount] : null;
		if (d == null)
			drawPool[drawCount] = d = {
				pipeline: 0,
				buffers: null,
				indices: 0,
				first: 0,
				count: 0,
				texture: 0,
				primitive: Triangles,
				scissor: null,
				viewport: null,
				textures: null,
				cubes: null,
				uniforms: null,
				instances: 0
			};
		drawCount++;
		d.pipeline = pipeline;
		d.buffers = buffers;
		d.sprite = false;
		d.indices = indices;
		d.first = 0;
		d.count = count;
		d.texture = 0;
		d.primitive = primitive;
		d.scissor = scissor;
		d.viewport = viewport;
		d.textures = bound;
		d.cubes = p.cubes;
		d.uniforms = values(p, model, diffuse);
		d.instances = instanceCount;
		d.firstInstance = 0;
		pass.draws.push(d);
	}

	// A mesh's draws in stereo, one an eye, sharing its buffers (meshBuffers).
	function meshEyes(pipeline:Int, buffers:Array<Int>, indices:Int, count:Int, primitive:Primitive, bound:Array<Int>, p:Program, model:Matrix3D,
			diffuse:Array<Float>, instanceCount:Int):Void
		eyes(() -> addMesh(pipeline, buffers, indices, count, primitive, bound, p, model, diffuse, instanceCount), true);

	// Makes the pipeline drawing a mesh through a program in a way, under its key.
	function meshPipeline(p:Program, key:String, primitive:Primitive, indexed:Bool, instances:Int):Int {
		var names = p.attributes;
		return p.pipeline(key, () -> {
			// A matrix's columns from the instances' transforms, or from the constants' record.
			var layouts:Array<helix.platform.VertexBuffer> = [
				for (i => name in names)
					if (isMatrix(names, i)) {
						stride: instances != 0 ? 64 : CONSTANT_BYTES,
						instanced: true,
						attributes: [
							for (column in 0...4)
								{slot: i + column, format: Float4, offset: (instances != 0 ? 0 : MATRIX_CONSTANT * 4) + column * 16}
						]
					} else if (name != "") {
						stride: FORMATS.get(name).bytes,
						instanced: false,
						attributes: [{slot: i, format: FORMATS.get(name), offset: 0}]
					}
			];
			graphics.createPipeline({
				shader: p.handle,
				buffers: layouts,
				primitive: primitive,
				indexed: indexed,
				blend: colorBlend ? blend : Blend.OPAQUE,
				colorWrite: colorMask,
				depthTest: depthTest ? LessEqual : Off,
				depthWrite: depthTest && depthMask,
				cull: primitive == Triangles ? cullFace() : None,
				clockwise: false,
				depthOnly: false,
				flip: ClipScale,
				flipBlockSlot: p.flipSlot,
				flipOffset: p.flipOffset
			});
		});
	}

	// The key of a mesh's pipeline: how it is drawn and the render state (states), kept for the state last found, so a draw builds none.
	function meshKey(indexed:Bool, primitive:Primitive, instanced:Bool):String {
		var state = states();
		if (state != meshKeysState) {
			meshKeysState = state;
			meshKeys.resize(0);
		}
		var at = (primitive : Int) * 4 + (indexed ? 2 : 0) + (instanced ? 1 : 0);
		var key = at < meshKeys.length ? meshKeys[at] : null;
		if (key == null) {
			key = 'm${indexed ? "x" : ""}${(primitive : Int)}${instanced ? "i" : ""}$state';
			while (meshKeys.length <= at)
				meshKeys.push(null);
			meshKeys[at] = key;
		}
		return key;
	}

	// The mesh keys made for meshKeysState, by meshKey's index.
	final meshKeys:Array<Null<String>> = [];
	var meshKeysState:Null<String> = null;

	// The frame's mesh draws, and the arrays its draws hold, kept from frame to frame and taken again after the frame is drawn.
	final drawPool:Array<Draw> = [];
	var drawCount = 0;
	final intPool:Array<Array<Int>> = [];
	var intCount = 0;

	// An empty array of the frame's, held by a draw until the frame is drawn.
	function ints():Array<Int> {
		var a = intCount < intPool.length ? intPool[intCount] : null;
		if (a == null)
			intPool[intCount] = a = [];
		else
			a.resize(0);
		intCount++;
		return a;
	}

	/** The buffers, by the program's slot, of the draws the last `mesh` added, which a caller may change before the frame is drawn (a
		mesh posed on the CPU, `Skinning`); null when it added none. */
	public var meshBuffers:Null<Array<Int>> = null;

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
	function frontEdges(mesh:helix.raylib.Mesh, m:Array<Float>):Array<Int> {
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

	// The render state a pipeline is made for, as part of its key: made again only when the state changes.
	function states():String {
		var text = stateText;
		if (text == null
			|| depthTest != stateDepthTest
			|| depthMask != stateDepthMask
			|| cull != stateCull
			|| cullFront != stateCullFront
			|| colorBlend != stateColorBlend
			|| (blend : Int) != stateBlend || (colorMask : Int) != stateColorMask) {
			stateDepthTest = depthTest;
			stateDepthMask = depthMask;
			stateCull = cull;
			stateCullFront = cullFront;
			stateColorBlend = colorBlend;
			stateBlend = blend;
			stateColorMask = colorMask;
			stateText = text = '${depthTest ? "d" : ""}${depthTest && depthMask ? "w" : ""}${cull ? (cullFront ? "f" : "b") : ""}${colorBlend ? (blend : Int) : -1}c${(colorMask : Int)}';
		}
		return text;
	}

	// The state stateText was made for.
	var stateText:Null<String> = null;
	var stateDepthTest = false;
	var stateDepthMask = false;
	var stateCull = false;
	var stateCullFront = false;
	var stateColorBlend = false;
	var stateBlend = 0;
	var stateColorMask = 0;

	function cullFace():helix.platform.CullFace
		return cull ? (cullFront ? Front : Back) : None;

	// The program's blocks as they are now, with raylib's own values set: the matrices and the diffuse color.
	function values(p:Program, model:Matrix3D, diffuse:Array<Float>):Array<Null<Bytes>> {
		var snapshot = snapshotCount < snapshots.length ? snapshots[snapshotCount] : null;
		if (snapshot == null)
			snapshots[snapshotCount] = snapshot = new helix.services.shaders.ShaderSnapshot();
		snapshotCount++;
		return p.capture(snapshot, model, view, projection, diffuse, meshView, meshProjection);
	}

	/** Draws the frame: each render texture's pass, then the screen's, then shows it unless told to wait for `present`. A frame ended
		and not shown yet is shown first.

		@param framebufferWidth  The screen's framebuffer width.
		@param framebufferHeight  Its height.
		@param show  Whether the screen's pass is shown as it ends; when false, `present` shows it. */
	public function draw(framebufferWidth:Int, framebufferHeight:Int, show:Bool):Void {
		flush();
		present();
		for (call in drawing)
			call();
		for (p in passes) {
			for (u in p.updates)
				graphics.updateTexture(u.texture, u.x, u.y, u.width, u.height, u.rgba);
			if (p.target == -1)
				continue;
			var color:Int = p.clear == null ? 0xff000000 : p.clear;
			if (p.target == 0)
				graphics.beginFrame(framebufferWidth, framebufferHeight, color);
			else if (p.clear == null)
				graphics.resumeTargetPass(p.target);
			else
				graphics.beginTargetPass(p.target, (color >> 16 & 255) / 255, (color >> 8 & 255) / 255, (color & 255) / 255, (color >>> 24) / 255);
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
				var count = d.primitive == Points ? d.count : d.primitive == Lines ? d.count - d.count % 2 : d.count - d.count % 3;
				// A texture binds only to a sampler of its kind, a cubemap to a samplerCube; any other reads the platform's clear texture.
				// Into arrays of the frame's, as the graphics adapter reads them during the call alone.
				var textures = drawTextures, samplings = drawSamplings;
				textures.resize(0);
				samplings.resize(0);
				for (slot => t in d.textures)
					textures.push(t != 0 && (slot < d.cubes.length && d.cubes[slot]) != Textures.isCubeHandle(t) ? 0 : t);
				for (t in textures)
					samplings.push(Textures.samplingOf(t));
				var buffers = d.buffers;
				if (buffers == null) {
					buffers = ownBuffers;
					buffers[0] = d.sprite ? spriteQuad : buffer;
					buffers[1] = d.sprite ? spriteBuffer : constants;
				}
				graphics.draw(d.pipeline, buffers, null, d.indices, d.first, count, d.firstInstance, d.instances, textures, samplings, d.uniforms);
			}
			if (p.target == 0) {
				graphics.endFrame();
				for (call in ended)
					call();
				if (show)
					graphics.present();
				else
					unshown = true;
			} else
				graphics.endTargetPass();
		}
		for (b in retired) {
			graphics.disposeBuffer(b);
		}
		retired.resize(0);
		reset();
		var calls = drawn.copy();
		drawn.resize(0);
		for (call in calls)
			call();
	}

	// What draw hands the graphics adapter a draw's textures, samplings and the frame's own buffers in.
	final drawTextures:Array<Int> = [];
	final drawSamplings:Array<helix.platform.Sampling> = [];
	final ownBuffers:Array<Int> = [0, 0];

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
		if (vertices > 0) {
			var bytes = vertices * STRIDE;
			if (bytes > capacity) {
				if (buffer != 0) {
					graphics.disposeBuffer(buffer);
				}
				capacity = data.length;
				buffer = graphics.createBuffer(capacity);
			}
			graphics.updateBuffer(buffer, data, bytes);
		}
		if (sprites > 0) {
			var bytes = sprites * SPRITE_BYTES;
			if (bytes > spriteCapacity) {
				if (spriteBuffer != 0) {
					graphics.disposeBuffer(spriteBuffer);
				}
				spriteCapacity = spriteData.length;
				spriteBuffer = graphics.createBuffer(spriteCapacity);
			}
			graphics.updateBuffer(spriteBuffer, spriteData, bytes);
		}
	}

	/** Frees the buffers, the white texture and the default and sprite programs. */
	public function dispose():Void {
		for (b in [buffer, constants, quadIndices, spriteBuffer, spriteQuad, spriteIndices].concat(retired))
			if (b != 0)
				graphics.disposeBuffer(b);
		graphics.disposeTexture(white);
		defaultProgram.dispose();
		if (spriteProgram != null)
			spriteProgram.dispose();
	}
}

@:structInit
private class Pass {
	// The render target, 0 for the screen, or -1 for no pass: updates alone, between passes.
	public final target:Int;
	// The color the pass is cleared to, 0xAARRGGBB, or null to keep what a render texture holds (the screen's black).
	public var clear:Null<Int>;
	public var width:Float;
	public var height:Float;
	public final draws:Array<Draw>;
	// Textures' rectangles replaced before the pass begins.
	public final updates:Array<Update>;
}

@:structInit
private class Update {
	public final texture:Int;
	public final x:Int;
	public final y:Int;
	public final width:Int;
	public final height:Int;
	public final rgba:Bytes;
}

@:structInit
private class Draw {
	public var pipeline:Int;
	// The buffers by the pipeline's slots, or null for the frame's own: the batch's vertices and the constants, or for a sprite run
	// (sprite) the quad and the sprites' records, both taken when the frame is drawn, as their buffers may be remade before.
	public var buffers:Null<Array<Int>>;
	public var sprite:Bool = false;
	public var indices:Int;
	public var first:Int;
	public var count:Int;
	public var texture:Int;
	public var primitive:Primitive;
	public var scissor:Null<Array<Float>>;
	public var viewport:Null<Array<Int>>;
	public var textures:Array<Int>;
	// Whether each slot's sampler is a samplerCube.
	public var cubes:Array<Bool>;
	public var uniforms:Array<Null<Bytes>>;
	public var instances:Int;
	// The first instance drawn: a sprite run's first record.
	public var firstInstance:Int = 0;
}

@:structInit
private class Run {
	public final texture:Int;
	// LINES, TRIANGLES, QUADS or SPRITES.
	public final mode:Int;
	// The run's first vertex, or first sprite record.
	public final first:Int;
	// Its vertices, or its sprites.
	public var count:Int;
}
