package helix.graphics;

import haxe.io.Bytes;

/** The GPU, as thin as HeliX can make it: a platform's graphics adapter implements it and nothing else. Resources (textures of a few kinds,
	buffers, programs built from a ShaderSource, pipelines made from a PipelineDesc), passes (the frame's screen pass after any passes into
	render targets and shadow maps) and one draw. An adapter knows no program, layout or pipeline of HeliX's own: shared code describes those
	(Pipelines, the generated layouts) and hands them over as data, so another adapter (another GPU API, another platform) implements this
	alone. A call that can't be done throws, before doing anything. */
interface IGraphics {
	/** Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last
		(at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a
		size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample. */
	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int;

	/** Uploads a cubemap, each face size x size, and returns its handle, sampled at a texture slot like any texture (the samplings' filter
		applies, their wrap doesn't: a cube's faces meet). levels is mip 0 then, optionally, its mips, each half the size of the last (at least 1),
		each its six faces one after another (+X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation: a face's first row is its t = 0), each face
		format.levelBytes of its size. Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't
		sample. */
	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int;

	/** Makes a data texture width x height of RGBA 32-bit floats (16 bytes a texel), read texel by texel (texelFetch: never filtered, its
		samplings ignored), and returns its handle. Its contents are updateDataTexture's. Throws for a size of 0 or less or past this GPU's. */
	public function createDataTexture(width:Int, height:Int):Int;

	/** Replaces a data texture's whole contents with data's first width * height * 16 bytes (rows top first, little-endian floats), for the
		draws after it; any number of times a frame. Throws for a handle that isn't a data texture or data too short. */
	public function updateDataTexture(handle:Int, data:Bytes):Void;

	/** Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them; half floats where it filters them. */
	public function canSample(format:TextureFormat):Bool;

	/** Makes a render target width x height and returns its handle: a texture (8 bits a channel), sampled like any other and stored top row first
		like any other, that a target pass draws into, with a depth buffer of its own. Throws for a size of 0 or less. */
	public function createRenderTarget(width:Int, height:Int):Int;

	/** Makes a shadow map: a depth texture of layers layers, each size x size, that shadow passes draw into (beginShadowPass), sampled through a
		comparison sampler (linear, less or equal, clamped to its edge; the slot's sampling is ignored) where a program declares a shadow
		texture. Its rows run bottom first, as GL's: clip space's -1..1 is its 0..1. Throws for a size or layer count of 0 or less, or past this
		GPU's. */
	public function createShadowMap(size:Int, layers:Int):Int;

	/** Frees a texture of any kind. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyTexture(handle:Int):Void;

	/** Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle.
		Throws for another size. */
	public function createBuffer(capacityBytes:Int):Int;

	/** Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true
		uint32 indices (little-endian). Throws for a bad size. */
	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int;

	/** Replaces a stream buffer's contents with the first usedBytes of data, for the draws after it; inside a pass, any number of times a frame
		(a buffer drawn into a target and then the screen is uploaded twice). Throws outside a pass, for an unknown handle or a size out of range. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Frees a buffer. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyBuffer(handle:Int):Void;

	/** Builds a program from source (the dialect this adapter compiles, its attributes by slot, its uniform blocks and its textures, each
		declared as a plain, cube, shadow or data texture) and returns its handle, for pipelines. Throws, with the compiler's log, for one that
		doesn't build. */
	public function createShader(source:ShaderSource):Int;

	/** Frees a program; the pipelines made with it are destroyed first. Throws for an unknown handle. */
	public function destroyShader(handle:Int):Void;

	/** Makes a pipeline as desc says (PipelineDesc) and returns its handle. Throws for an unknown shader or a description it can't make. */
	public function createPipeline(desc:PipelineDesc):Int;

	/** Frees a pipeline. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyPipeline(handle:Int):Void;

	/** Starts a depth-only pass drawing into layer layer of map (a createShadowMap handle), for depth-only pipelines: clears it to the farthest
		and sets the viewport to all of it. Before the screen's pass, outside any other; endTargetPass ends it. Throws inside a pass, for a
		handle that isn't a shadow map or a layer it hasn't. */
	public function beginShadowPass(map:Int, layer:Int):Void;

	/** Starts a pass drawing into target (a createRenderTarget handle): clears it to clearColor (0xRRGGBBAA) and its depth to the farthest, and sets
		the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target. */
	public function beginTargetPass(target:Int, clearColor:Int):Void;

	/** Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open. */
	public function endTargetPass():Void;

	/** Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xRRGGBBAA) and the
		depth to the farthest, and sets the viewport to all of it. Throws inside a pass or for a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, clearColor:Int):Void;

	/** Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less. */
	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void;

	/** Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a
		static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers.
		buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a
		gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map
		or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks),
		block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the
		viewport: three). Throws for anything invalid, before drawing. */
	public function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>,
		samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Ends the screen's pass and with it the frame, presenting it. Throws when no screen pass is open. */
	public function endFrame():Void;

	/** Releases the adapter itself, after its handles are destroyed. */
	public function shutdown():Void;
}
