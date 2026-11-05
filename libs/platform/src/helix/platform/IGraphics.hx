package helix.platform;

import haxe.io.Bytes;
import helix.platform.TextureFormat;
import helix.platform.Sampling;

/** Defines the GPU as a platform's graphics adapter provides it, with its resources, its passes and one draw call.

	Resources are textures of a few kinds, buffers, programs built from a `ShaderSource`, and pipelines made from a `PipelineDesc`. A frame
	is any number of passes into render targets and shadow maps, then the screen's pass from `beginFrame` to `endFrame`.

	An adapter knows nothing of its caller's programs, layouts or pipelines. The caller describes them as data. Whoever creates a handle
	disposes it, once.

	A call that cannot be done throws before doing anything. */
interface IGraphics {
	/** Uploads an image as a texture.

		Each draw chooses how the texture is sampled (`Sampling`).
		@param width  The width, in texels.
		@param height  The height, in texels.
		@param levels  The image with rows top first, then optionally its mipmaps. Each mipmap is half the size of the last, and at least 1.
			Each level is `format.levelBytes` of its size.
		@param format  Optional. The texels' format; defaults to Rgba8.
		@return  The texture's handle.
		@throws String  A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample. */
	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int;

	/** Uploads a cubemap.

		A cubemap is sampled at a texture slot like any texture. The sampling's filter applies and its wrap is ignored.
		@param size  Each face's width and height, in texels.
		@param levels  Mip 0, then optionally its mips, each half the size of the last and at least 1. Each level holds its six faces in the
			order +X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation, where a face's first row is its t = 0. Each face is `format.levelBytes` of
			its size.
		@param format  The texels' format.
		@return  The cubemap's handle.
		@throws String  A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample. */
	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int;

	/** Creates a data texture of RGBA 32-bit floats, 16 bytes a texel.

		A data texture is read texel by texel and never filtered, so its samplings are ignored. `updateTexture` fills it, whole.
		@param width  The width, in texels.
		@param height  The height, in texels.
		@return  The data texture's handle.
		@throws String  A size of 0 or less, or larger than this GPU allows. */
	public function createDataTexture(width:Int, height:Int):Int;

	/** Replaces a rectangle of a texture's texels, for the draws after it.

		A `createTexture` texture is updated outside a pass, any number of times a frame: draws in the passes before it read the old
		texels, and those after it the new. Only its top level changes; its mipmaps are left as they were. A data texture is rewritten
		whole, the rectangle all of it, any number of times a frame, inside a pass or outside: each draw reads the latest.
		@param handle  The texture: a `createTexture` texture of format Rgba8 or Rgba16f, or a data texture.
		@param x  The rectangle's left edge, in texels.
		@param y  The rectangle's top edge, in texels from the top row.
		@param width  The rectangle's width, in texels.
		@param height  The rectangle's height, in texels.
		@param data  The rectangle's texels with rows top first, `format.levelBytes(width, height)` bytes of the texture's format, or 16
			bytes a texel of little-endian floats for a data texture.
		@throws String  An unknown handle, a cube, render target or shadow map, a compressed format, a call inside a pass for a
			`createTexture` texture, a rectangle that is empty or not inside the texture (not all of a data texture), or data that is too
			short. */
	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void;

	/** Returns whether this GPU samples textures of a format.

		RGBA8 can always be sampled. The compressed formats can be sampled on GPUs that have them, and half floats where this GPU filters
		them.
		@param format  The format.
		@return  True when textures of the format can be sampled. */
	public function canSample(format:TextureFormat):Bool;

	/** Gets the number of multisampling samples per pixel that the screen is drawn with, or 1 for none.

		It can be fewer than the window asked for. A render target created with a sample count of 0 is drawn with the same number, where
		its format takes it. */
	var msaaSampleCount(get, never):Int;

	/** Gets the largest number of multisampling samples a window could ask for here, at most 8.

		A browser only switches antialiasing on or off, and chooses its own count. In a browser this is therefore the count the canvas has
		when antialiasing is on, which is 4 where the GPU supports 4, and 1 otherwise. A render target's limit is
		`getMaxRenderTargetMsaaSampleCount`. */
	var maxMsaaSampleCount(get, never):Int;

	/** Gets the GPU and driver drawing, as the graphics API reports them, for a program to log or show.

		A browser may mask them: the adapter asks for the unmasked names (`WEBGL_debug_renderer_info`) where the browser gives them, and
		otherwise has the browser's own, such as "WebKit WebGL". */
	var device(get, never):GraphicsDevice;

	/** Returns the largest number of multisampling samples a render target of a format can be drawn with here, at most 8.

		It is 1, 2, 4 or 8: 1 where this GPU cannot multisample the format, or cannot draw into it at all (`canRender`).
		@param format  The format.
		@return  The largest sample count `createRenderTarget` gives a target of the format. */
	public function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int;

	/** Creates a render target, which is a texture that a target pass draws into.

		The target is sampled like any texture and stored top row first. A target with depth has its own depth buffer. Whether it has depth
		and how many samples it is drawn with are chosen apart. A target of more than one sample is drawn into its samples, which are
		resolved into the texture at the end of each pass; a target of one sample is drawn into the texture itself. The count asked for is
		rounded down to the nearest that this GPU draws the format with: 1, 2, 4 or 8, at most `getMaxRenderTargetMsaaSampleCount(format)`.
		A count the GPU can't give is never refused.
		What a pass leaves in a target, its samples and depth too, lasts until a `beginTargetPass` clears it, so `resumeTargetPass` draws
		over it in a later pass or frame. A new target holds transparent black and the farthest depth.
		@param width  The width, in texels.
		@param height  The height, in texels.
		@param format  Optional. The texels' format; defaults to Rgba8.
		@param depth  Optional. Whether it has a depth buffer; defaults to true.
		@param msaaSampleCount  Optional. The multisampling samples per texel asked for: 1 for none, or 0, the default, for the screen's
			(`msaaSampleCount`).
		@return  The render target's handle.
		@throws String  A size of 0 or less, a format this GPU cannot draw into (`canRender`), or a sample count below 0. */
	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true, msaaSampleCount:Int = 0):Int;

	/** Returns whether this GPU draws into, blends over and filters render targets of a format.

		RGBA8 always can. RGBA16F can where float targets exist, which is nearly always natively, and in a browser through
		EXT_color_buffer_float. A compressed format never can.
		@param format  The format.
		@return  True when render targets of the format can be drawn into. */
	public function canRender(format:TextureFormat):Bool;

	/** Creates a shadow map, which is a depth texture of layers that shadow passes draw into.

		A program that declares a shadow texture samples it through a comparison sampler that is linear, less or equal, and clamped to its
		edge. The slot's sampling is ignored. The map's rows are stored bottom first, as GL's are, so clip space's -1 to 1 is its 0 to 1.
		@param size  Each layer's width and height, in texels.
		@param layerCount  The number of layers.
		@return  The shadow map's handle.
		@throws String  A size or layer count of 0 or less, or larger than this GPU allows. */
	public function createShadowMap(size:Int, layerCount:Int):Int;

	/** Frees a texture of any kind.

		@param handle  The texture.
		@throws String  An unknown handle. */
	public function disposeTexture(handle:Int):Void;

	/** Creates a stream vertex buffer, filled each frame by `updateBuffer`.

		@param capacityBytes  The capacity, in bytes, which must be a positive multiple of 4.
		@return  The buffer's handle.
		@throws String  A capacity that is not a positive multiple of 4. */
	public function createBuffer(capacityBytes:Int):Int;

	/** Creates an immutable buffer of vertices or indices.

		@param data  The contents.
		@param bytes  The number of bytes of data to use, which must be a positive multiple of 4.
		@param index  Whether the buffer holds uint32 indices (little-endian) rather than vertices.
		@return  The buffer's handle.
		@throws String  A size that is not a positive multiple of 4. */
	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int;

	/** Replaces a stream buffer's contents for the draws after it.

		It must be called inside a pass, and can be called any number of times a frame. A buffer drawn into a target and then into the
		screen is uploaded twice.
		A buffer a frame has appended to (`appendBuffer`) can't be updated until the next frame.
		@param handle  The stream buffer.
		@param data  The new contents.
		@param usedBytes  The number of bytes of data to use.
		@throws String  A call outside a pass, an unknown handle, a size out of range, or a buffer appended to this frame. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Adds bytes to the end of a stream buffer, so draws can read each range from its own offset.

		A frame starts with every stream buffer empty. Each call writes after the bytes the frame's earlier calls wrote, and the earlier bytes
		stay as they were, so a draw after any call can read any range written so far. It must be called inside a pass, and can be called
		any number of times a frame. A buffer is either appended to or updated (`updateBuffer`) in a frame, not both. An adapter may set aside
		the buffer's whole capacity of its upload space for the frame, at the first call.
		@param handle  The stream buffer.
		@param data  The bytes to add.
		@param usedBytes  The number of bytes of data to use, which must be a multiple of 4.
		@return  The byte offset in the buffer where the bytes landed, which is a multiple of 4. Pass it in a draw's `bufferOffsets`.
		@throws String  A call outside a pass, an unknown handle, a size out of range, bytes that don't fit in the buffer's capacity, or
			a buffer updated this frame. */
	public function appendBuffer(handle:Int, data:Bytes, usedBytes:Int):Int;

	/** Frees a buffer.

		@param handle  The buffer.
		@throws String  An unknown handle. */
	public function disposeBuffer(handle:Int):Void;

	/** Builds a program for pipelines to use.

		@param source  The program, with the dialect this adapter compiles, its attributes by slot, its uniform blocks, and its textures.
			Each texture is a plain, cube, shadow or data texture.
		@return  The program's handle.
		@throws String  A program that does not build, with the compiler's log. */
	public function createShader(source:ShaderSource):Int;

	/** Frees a program, disposing the pipelines made with it first.

		@param handle  The program.
		@throws String  An unknown handle. */
	public function disposeShader(handle:Int):Void;

	/** Creates a pipeline.

		@param desc  What the pipeline fixes for its draws.
		@return  The pipeline's handle.
		@throws String  An unknown program, or a description this adapter cannot make. */
	public function createPipeline(desc:PipelineDesc):Int;

	/** Frees a pipeline.

		@param handle  The pipeline.
		@throws String  An unknown handle. */
	public function disposePipeline(handle:Int):Void;

	/** Starts a depth-only pass into one layer of a shadow map, for depth-only pipelines.

		The layer is cleared to the farthest depth, and the viewport is set to all of it. The pass comes before the screen's and outside any
		other. `endTargetPass` ends it.
		@param map  The shadow map, as a `createShadowMap` handle.
		@param layerIndex  The index of the layer to draw into.
		@throws String  A call inside a pass, a handle that is not a shadow map, or a layer it does not have. */
	public function beginShadowPass(map:Int, layerIndex:Int):Void;

	/** Starts a pass into a render target.

		The target is cleared to the color as its texels store it. That is 0 to 1 in an RGBA8 target, and can be beyond 1 in a half-float
		one. Its depth, if it has one, is cleared to the farthest, and the viewport is set to all of it. The pass comes before the screen's
		and outside any other. `endTargetPass` ends it.
		@param target  The render target, as a `createRenderTarget` handle.
		@param red  The clear color's red.
		@param green  The clear color's green.
		@param blue  The clear color's blue.
		@param alpha  The clear color's alpha.
		@throws String  A call inside a pass, or a handle that is not a render target. */
	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void;

	/** Starts a pass into a render target that keeps what the target holds: its texels, and its depth if it has one.

		It is `beginTargetPass` without the clear: the viewport is set to all of the target, and the pass comes before the screen's and
		outside any other. `endTargetPass` ends it.
		@param target  The render target, as a `createRenderTarget` handle.
		@throws String  A call inside a pass, or a handle that is not a render target. */
	public function resumeTargetPass(target:Int):Void;

	/** Ends the pass that `beginTargetPass`, `resumeTargetPass` or `beginShadowPass` started.

		Its target can be sampled from then on.
		@throws String  No such pass is open. */
	public function endTargetPass():Void;

	/** Starts the frame's screen pass, after its target passes.

		The framebuffer is cleared to the color and the farthest depth, and the viewport is set to all of it.
		@param width  The framebuffer's width, in framebuffer pixels.
		@param height  The framebuffer's height, in framebuffer pixels.
		@param clearColor  The clear color, as 0xAARRGGBB.
		@throws String  A call inside a pass, or a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, clearColor:Int):Void;

	/** Sets the rectangle that the following draws fill.

		@param x  The left edge, in framebuffer pixels.
		@param y  The bottom edge, in framebuffer pixels from the bottom.
		@param w  The width, in framebuffer pixels.
		@param h  The height, in framebuffer pixels.
		@throws String  A call outside a frame, or a size of 0 or less. */
	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void;

	/** Clips the following draws to a rectangle, until `resetScissor` or the end of the pass.

		A pass begins unclipped.
		@param x  The left edge, in framebuffer pixels.
		@param y  The bottom edge, in framebuffer pixels from the bottom.
		@param w  The width, in framebuffer pixels.
		@param h  The height, in framebuffer pixels.
		@throws String  A call outside a pass, or a size below 0. */
	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void;

	/** Removes the clip that `applyScissor` set, for the rest of the pass.

		@throws String  A call outside a pass. */
	public function resetScissor():Void;

	/** Draws through a pipeline.

		Only whole primitives are drawn. A pipeline without buffers draws `elementCount` vertices from no data, so one triangle over the viewport is
		three vertices. An attribute the program declares that no buffer feeds reads the pipeline's constant for its slot, or (0, 0, 0, 1)
		(`PipelineDesc.attributeConstants`). The uniform the pipeline names is flipped as its `ClipFlip` specifies, in the adapter's own
		copy of the block. A texture that is the open pass's own target (the render target drawn into, or the shadow map whose layer is
		drawn into) is refused, as sampling what a pass draws into is undefined.
		@param pipeline  The pipeline.
		@param buffers  The buffer for each of the pipeline's buffers, by index, or 0 for a gap. Each is a `createBuffer` handle as this
			frame's upload left it, or a `createStaticBuffer` handle.
		@param bufferOffsets  The byte offset in each of `buffers` where its data starts, so draws can read different ranges of one
			buffer. Null, or a buffer past the array's end, is 0. An offset is a multiple of 4. The draw's elements and instances are counted from
			it, and must end inside the buffer's bytes, written this frame or static: a vertex buffer's at `firstElementIndex` plus
			`elementCount` records for a pipeline that isn't indexed, an instanced buffer's at `firstInstanceIndex` plus `instanceCount`. An
			indexed pipeline's vertex data is read from the offset by index, with no base vertex. It applies to vertex and instanced buffers alike.
		@param indexBuffer  For an indexed pipeline, a static index buffer. Otherwise it is ignored.
		@param firstElementIndex  The index of the first element drawn: its first vertex, or for an indexed pipeline its first index.
		@param elementCount  The number of elements drawn: vertices, or for an indexed pipeline indices.
		@param firstInstanceIndex  The index of the first instance drawn: the first record of the instanced buffers.
		@param instanceCount  The number of instances.
		@param textures  The texture bound at each of the program's texture slots, by slot. A slot provided 0, or past the array's end,
			reads a clear 1x1 texture of its kind, for a texture the program declares and doesn't read.
		@param samplings  How each texture is sampled, by slot. A shadow map or data texture is sampled as its kind requires.
		@param uniforms  The bytes of each uniform block at its declared size, by stage and slot: the vertex stage's slot n at index n, the
			fragment stage's at 4 + n, a block both stages read at both (`ShaderBlock`); null at an index the program has no block for.
		@throws String  Anything invalid, before drawing: a texture that is the pass's own target among them, or an offset out of range. */
	public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
		firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Ends the screen's pass and the frame, and submits it.

		`present` shows the frame. Between the two calls, the frame can be read back with `readPixels(0)`, and the caller can do other
		work.
		@throws String  No screen pass is open. */
	public function endFrame():Void;

	/** Shows the frame that `endFrame` submitted, and waits for the display's refresh.

		Natively the wait paces the caller's loop. In a page it does nothing, because the browser shows the frame when the frame's callback
		returns. */
	public function present():Void;

	/** Reads a texture, a render target, or the frame just ended, back from the GPU.

		It waits for the GPU, so it suits screenshots and checks, not every frame. A texture or render target is read as the passes so far
		left it. The frame `endFrame` ended must be read before `present`, and in a page before the frame's callback returns. One of `read`
		or `failed` is called once, on the main thread. It is called during the call, or later on a GPU that reads back asynchronously.
		@param handle  An RGBA8 `createTexture` texture (its top level), an RGBA8 render target, or 0 for the frame `endFrame` just ended.
		@param read  Receives the pixels and their width and height. The pixels are `width * height * 4` bytes of RGBA8, with rows top first.
		@param failed  Receives why the pixels can't be read, which is that no frame has ended since the last `beginFrame`.
		@throws String  A call inside a pass, or a handle that is none of these. */
	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void;

	/** Releases the adapter.

		It is called after every handle the adapter made is disposed, and before its window is closed. */
	public function dispose():Void;
}
