package helix.graphics;

import haxe.io.Bytes;
import helix.texture.TextureFormat;
import helix.texture.Sampling;

/** Pixels read back from the GPU: width x height RGBA8, rows top first; or why they couldn't be. */
@:noCompletion
enum ReadPixelsResult {
	Read(width:Int, height:Int, rgba:Bytes);
	Failed(message:String);
}

/** The GPU, as thin as HeliX can make it: a platform's graphics adapter implements it and nothing else. Resources (textures of a few kinds,
	buffers, programs built from a ShaderSource, pipelines made from a PipelineDesc), passes (the frame's screen pass after any passes into
	render targets and shadow maps) and one draw. An adapter knows no program, layout or pipeline of HeliX's own: shared code describes those
	(Pipelines, the generated program classes) and hands them over as data, so another adapter (another GPU API, another platform) implements this
	alone. A call that can't be done throws, before doing anything. */
@:noCompletion
interface IGraphics {
	/** Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last
		(at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a
		size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample. */
	@:noCompletion
	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int;

	/** Uploads a cubemap, each face size x size, and returns its handle, sampled at a texture slot like any texture (the samplings' filter
		applies, their wrap doesn't: a cube's faces meet). levels is mip 0 then, optionally, its mips, each half the size of the last (at least 1),
		each its six faces one after another (+X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation: a face's first row is its t = 0), each face
		format.levelBytes of its size. Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't
		sample. */
	@:noCompletion
	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int;

	/** Makes a data texture width x height of RGBA 32-bit floats (16 bytes a texel), read texel by texel (texelFetch: never filtered, its
		samplings ignored), and returns its handle. Its contents are updateDataTexture's. Throws for a size of 0 or less or past this GPU's. */
	@:noCompletion
	public function createDataTexture(width:Int, height:Int):Int;

	/** Replaces a data texture's whole contents with data's first width * height * 16 bytes (rows top first, little-endian floats), for the
		draws after it; any number of times a frame. Throws for a handle that isn't a data texture or data too short. */
	@:noCompletion
	public function updateDataTexture(handle:Int, data:Bytes):Void;

	/** Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them; half floats where it filters them. */
	public function canSample(format:TextureFormat):Bool;

	/** Multisampling samples a pixel the screen is drawn with (WindowOptions.requestMsaaSamples): 1 for none, else what the platform gave,
		which may be fewer than asked. Render targets with depth are drawn with the same, resolved into the texture sampled. */
	var msaaSamples(get, never):Int;

	/** The most multisampling samples a pixel a window could ask for here, at most 8 (what requestMsaaSamples takes): for a settings menu to
		offer, applied at the next start. Natively the GPU's most; a browser only switches antialiasing on or off, choosing its own count, so
		there it's the count the canvas has when on (4 where the GPU has 4, else 1). */
	var maxMsaaSamples(get, never):Int;

	/** Makes a render target width x height of format and returns its handle: a texture, sampled like any other and stored top row first like any
		other, that a target pass draws into. With depth, it has a depth buffer of its own and is multisampled as the screen is (msaaSamples, or
		single where this GPU can't multisample format), resolved into the texture at each pass's end; without, it has neither (a pass drawing over
		the whole target: a screen effect's). Throws for a size of 0 or less, or a format this GPU can't draw into (canRender). */
	@:noCompletion
	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true):Int;

	/** Whether this GPU draws into render targets of format, blends over them and filters them when sampled: RGBA8 always; RGBA16F where float
		targets exist (natively nearly always; in a browser through EXT_color_buffer_float, turned on by asking); never a compressed one. */
	public function canRender(format:TextureFormat):Bool;

	/** Makes a shadow map: a depth texture of layers layers, each size x size, that shadow passes draw into (beginShadowPass), sampled through a
		comparison sampler (linear, less or equal, clamped to its edge; the slot's sampling is ignored) where a program declares a shadow
		texture. Its rows run bottom first, as GL's: clip space's -1..1 is its 0..1. Throws for a size or layer count of 0 or less, or past this
		GPU's. */
	@:noCompletion
	public function createShadowMap(size:Int, layers:Int):Int;

	/** Frees a texture of any kind. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	@:noCompletion
	public function destroyTexture(handle:Int):Void;

	/** Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle.
		Throws for another size. */
	@:noCompletion
	public function createBuffer(capacityBytes:Int):Int;

	/** Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true
		uint32 indices (little-endian). Throws for a bad size. */
	@:noCompletion
	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int;

	/** Replaces a stream buffer's contents with the first usedBytes of data, for the draws after it; inside a pass, any number of times a frame
		(a buffer drawn into a target and then the screen is uploaded twice). Throws outside a pass, for an unknown handle or a size out of range. */
	@:noCompletion
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Frees a buffer. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	@:noCompletion
	public function destroyBuffer(handle:Int):Void;

	/** Builds a program from source (the dialect this adapter compiles, its attributes by slot, its uniform blocks and its textures, each
		declared as a plain, cube, shadow or data texture) and returns its handle, for pipelines. Throws, with the compiler's log, for one that
		doesn't build. */
	@:noCompletion
	public function createShader(source:ShaderSource):Int;

	/** Frees a program; the pipelines made with it are destroyed first. Throws for an unknown handle. */
	@:noCompletion
	public function destroyShader(handle:Int):Void;

	/** Makes a pipeline as desc says (PipelineDesc) and returns its handle. Throws for an unknown shader or a description it can't make. */
	@:noCompletion
	public function createPipeline(desc:PipelineDesc):Int;

	/** Frees a pipeline. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	@:noCompletion
	public function destroyPipeline(handle:Int):Void;

	/** Starts a depth-only pass drawing into layer layer of map (a createShadowMap handle), for depth-only pipelines: clears it to the farthest
		and sets the viewport to all of it. Before the screen's pass, outside any other; endTargetPass ends it. Throws inside a pass, for a
		handle that isn't a shadow map or a layer it hasn't. */
	@:noCompletion
	public function beginShadowPass(map:Int, layer:Int):Void;

	/** Starts a pass drawing into target (a createRenderTarget handle): clears it to red, green, blue and alpha, as its texels store them (0 to
		1 in an RGBA8 target; a half-float one holds values past 1, as an HDR scene's light), and its depth (if it has one) to the farthest, and
		sets the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target. */
	@:noCompletion
	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void;

	/** Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open. */
	@:noCompletion
	public function endTargetPass():Void;

	/** Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xAARRGGBB) and the
		depth to the farthest, and sets the viewport to all of it. Throws inside a pass or for a size of 0 or less. */
	@:noCompletion
	public function beginFrame(width:Int, height:Int, clearColor:Int):Void;

	/** Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less. */
	@:noCompletion
	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void;

	/** Draws from now on only inside x, y, w, h in framebuffer pixels from the bottom-left (as applyViewport), until resetScissor or the pass
		ends; a pass begins unclipped. Throws outside a pass or for a size below 0. */
	@:noCompletion
	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void;

	/** Draws everywhere in the pass again. Throws outside a pass. */
	@:noCompletion
	public function resetScissor():Void;

	/** Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a
		static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers.
		buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a
		gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map
		or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks),
		block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the
		viewport: three). Throws for anything invalid, before drawing. */
	@:noCompletion
	public function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>,
		samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Ends the screen's pass and with it the frame, presenting it. Throws when no screen pass is open. */
	@:noCompletion
	public function endFrame():Void;

	/** Reads target back (a createRenderTarget handle; 0 for the frame endFrame just ended, read before the host's frame returns, as a browser
		presents it then and a GPU may swap it away); done runs once on the host thread, during this call or, on a GPU that reads back
		asynchronously, later: Read, or Failed when no frame has ended since the last beginFrame. Slow (it waits for the GPU): for screenshots and
		checks, not every frame. Throws inside a pass or for a handle that isn't an RGBA8 render target. */
	@:noCompletion
	public function readPixels(target:Int, done:ReadPixelsResult->Void):Void;

	/** Releases the adapter itself, after its handles are destroyed. */
	@:noCompletion
	public function shutdown():Void;
}
