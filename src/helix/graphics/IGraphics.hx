package helix.graphics;

import haxe.io.Bytes;

/** Thin resource/submission contract. No scene policy belongs in an adapter. A frame is any number of passes into render targets
	(beginTargetPass to endTargetPass), then the screen's pass (beginFrame to endFrame), each with any number of viewports, uploads and draws;
	whoever draws (an app, Batch2D, Batch3D) brings its own buffers and pipelines. */
interface IGraphics {
	/** Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last
		(at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a
		size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample. */
	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int;

	/** Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them. */
	public function canSample(format:TextureFormat):Bool;

	/** Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle.
		Throws for another size. */
	public function createBuffer(capacityBytes:Int):Int;

	/** Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true
		uint32 indices (little-endian). Throws for a bad size. */
	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int;

	/** Creates a pipeline drawing kind, its colors meeting the framebuffer's as blend says, and returns its handle: with its framework shader, or with shader (a
		createShader handle) for a kind that takes an app's: Screen always does, Lit3D may (a surface shader). doubleSided draws a Lit3D pipeline's back
		faces too (its triangles aren't culled; the shader sees which side it draws through gl_FrontFacing); other kinds cull nothing anyway.
		clockwise makes a Lit3D pipeline's front faces the clockwise ones: for models whose placement mirrors them (an odd number of negative
		scales), so they keep their faces. Throws for a shader of another kind's layout. */
	public function createPipeline(kind:PipelineKind, blend:BlendMode, shader:Int = 0, doubleSided:Bool = false, clockwise:Bool = false):Int;

	/** Builds an app's program (a .hxshader's source, in this adapter's dialect) and returns its handle, for createPipeline. Throws, with the
		compiler's log, for one that doesn't build. */
	public function createShader(source:ShaderSource):Int;

	/** Draws one triangle over the viewport through a Screen pipeline: textures[i] (createTexture or createRenderTarget handles) bound at the
		shader's texture slot i, sampled as samplings[i] says (0 for a slot it doesn't sample), and uniforms[i] the bytes of its uniform block at
		slot i (its declared size; null for a slot it doesn't have). Block 0 is the vertex stage's clip scale, which the adapter sets. Throws for anything invalid, before
		drawing. */
	public function drawScreen(pipeline:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Replaces a stream buffer's contents with the first usedBytes of data, for the draws after it; inside a pass, any number of times a frame
		(a buffer drawn into a target and then the screen is uploaded twice). Throws outside a pass, for an unknown handle or a size out of range. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Makes a render target width x height and returns its handle: a texture (8 bits a channel), sampled like any other and stored top row first
		like any other, that a target pass draws into, with a depth buffer of its own. destroyTexture frees it. Throws for a size of 0 or less. */
	public function createRenderTarget(width:Int, height:Int):Int;

	/** Starts a pass drawing into target (a createRenderTarget handle): clears it to clearColor (0xRRGGBBAA) and its depth to the farthest, and sets
		the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target. */
	public function beginTargetPass(target:Int, clearColor:Int):Void;

	/** Ends the pass beginTargetPass started; its target can be sampled from then on. Throws when no target pass is open. */
	public function endTargetPass():Void;

	/** Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xRRGGBBAA) and the depth to the farthest, and sets the viewport to all
		of it. Throws inside a pass or for a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, clearColor:Int):Void;

	/** Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less. */
	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void;

	/** Draws vertices from firstVertex of buffer's upload this frame through pipeline: whole triangles (three vertices each) or lines (two each), in
		the pipeline's vertex layout. texture is a handle from createTexture for a Sprite2D pipeline, sampled as sampling says, both ignored by the
		others; uniforms are a Color3D or Lines3D pipeline's (the view-projection matrix, column-major, 64 bytes), null for a Sprite2D one. Throws for
		anything invalid, before drawing. */
	public function draw(pipeline:Int, buffer:Int, texture:Int, sampling:Sampling, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void;

	/** Draws indexCount indices (whole triangles) of indices into vertices, two static buffers, as instanceCount instances whose records start at
		instance firstInstance of instances' upload this frame (the kind's layout's instanceStride bytes each), through a Lit3D pipeline (the
		framework's program, or an app's surface shader) or a Sprite3D one (its one texture and vertex block): textures[i] bound at texture slot i, sampled as samplings[i] says (0 for a slot the program doesn't
		sample; the framework's are 0, the base color texture, sRGB, and 1, the normal map, linear), and uniforms[i] its uniform block at slot i
		(null for one it lacks; 0 the vertex stage's, starting with the view-projection matrix, 1 the fragment stage's lights and material, as
		Lit3DLayout and the surface kind lay them out). Throws for anything invalid, before drawing. */
	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int,
		textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void;

	/** Ends the screen's pass and with it the frame; sokol also commits it for presentation. Throws when no screen pass is open. */
	public function endFrame():Void;

	/** Frees a handle from createTexture. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyTexture(handle:Int):Void;

	/** Frees a handle from createBuffer. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyBuffer(handle:Int):Void;

	/** Frees a handle from createShader; the pipelines made with it can only be destroyed after. Throws for an unknown handle. */
	public function destroyShader(handle:Int):Void;

	/** Frees a handle from createPipeline. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyPipeline(handle:Int):Void;

	/** Releases the adapter itself, after its handles are destroyed. */
	public function shutdown():Void;
}
