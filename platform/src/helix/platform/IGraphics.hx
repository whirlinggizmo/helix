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

		It can be fewer than the window asked for. Render targets with depth are drawn with the same number, and resolved into the texture
		that is sampled. */
	var msaaSampleCount(get, never):Int;

	/** Gets the largest number of multisampling samples a window could ask for here, at most 8.

		A browser only switches antialiasing on or off, and chooses its own count. In a browser this is therefore the count the canvas has
		when antialiasing is on, which is 4 where the GPU supports 4, and 1 otherwise. */
	var maxMsaaSampleCount(get, never):Int;

	/** Creates a render target, which is a texture that a target pass draws into.

		The target is sampled like any texture and stored top row first. A target with depth has its own depth buffer. It is multisampled
		as the screen is (`msaaSampleCount`), or single-sampled where this GPU cannot multisample the format, and it is resolved into the
		texture at the end of each pass. A target without depth has neither a depth buffer nor multisampling, for a pass that draws over the
		whole target.
		@param width  The width, in texels.
		@param height  The height, in texels.
		@param format  Optional. The texels' format; defaults to Rgba8.
		@param depth  Optional. Whether it has a depth buffer; defaults to true.
		@return  The render target's handle.
		@throws String  A size of 0 or less, or a format this GPU cannot draw into (`canRender`). */
	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true):Int;

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
		@param handle  The stream buffer.
		@param data  The new contents.
		@param usedBytes  The number of bytes of data to use.
		@throws String  A call outside a pass, an unknown handle, or a size out of range. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

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

	/** Ends the pass that `beginTargetPass` or `beginShadowPass` started.

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
		three vertices. Block 0 of the uniforms is flipped as the pipeline's `ClipFlip` specifies.
		@param pipeline  The pipeline.
		@param buffers  The buffer for each of the pipeline's buffers, by index, or 0 for a gap. Each is a `createBuffer` handle as this
			frame's upload left it, or a `createStaticBuffer` handle.
		@param indexBuffer  For an indexed pipeline, a static index buffer. Otherwise it is ignored.
		@param firstElementIndex  The index of the first element drawn: its first vertex, or for an indexed pipeline its first index.
		@param elementCount  The number of elements drawn: vertices, or for an indexed pipeline indices.
		@param firstInstanceIndex  The index of the first instance drawn: the first record of the instanced buffers.
		@param instanceCount  The number of instances.
		@param textures  The texture bound at each of the program's texture slots, by slot. A slot provided 0, or past the array's end,
			reads a clear 1x1 texture of its kind, for a texture the program declares and doesn't read.
		@param samplings  How each texture is sampled, by slot. A shadow map or data texture is sampled as its kind requires.
		@param uniforms  The bytes of each uniform block, by slot, at its declared size, or null for a slot the program lacks.
		@throws String  Anything invalid, before drawing. */
	public function draw(pipeline:Int, buffers:Array<Int>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int, firstInstanceIndex:Int,
		instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Ends the screen's pass and the frame, and submits it.

		`present` shows the frame. Between the two calls, the frame can be read back with `readPixels(0)`, and the caller can do other
		work.
		@throws String  No screen pass is open. */
	public function endFrame():Void;

	/** Shows the frame that `endFrame` submitted, and waits for the display's refresh.

		Natively the wait paces the caller's loop. In a page it does nothing, because the browser shows the frame when the frame's callback
		returns. */
	public function present():Void;

	/** Reads a render target, or the frame just ended, back from the GPU.

		It waits for the GPU, so it suits screenshots and checks, not every frame. The frame `endFrame` ended must be read before
		`present`, and in a page before the frame's callback returns. One of `read` or `failed` is called once, on the main thread. It is
		called during the call, or later on a GPU that reads back asynchronously.
		@param target  The render target, as a `createRenderTarget` handle, or 0 for the frame `endFrame` just ended.
		@param read  Receives the pixels and their width and height. The pixels are `width * height * 4` bytes of RGBA8, with rows top first.
		@param failed  Receives why the pixels can't be read, which is that no frame has ended since the last `beginFrame`.
		@throws String  A call inside a pass, or a handle that is not an RGBA8 render target. */
	public function readPixels(target:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void;

	/** Releases the adapter.

		It is called after every handle the adapter made is disposed, and before its window is closed. */
	public function dispose():Void;
}
