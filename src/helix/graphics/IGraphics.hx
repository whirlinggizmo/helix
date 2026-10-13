package helix.graphics;

import haxe.io.Bytes;

/** Thin resource/submission contract. No scene policy belongs in an adapter. A frame is beginFrame, then any number of viewports, uploads and
	draws, then endFrame; whoever draws (an app, Batch2D, Batch3D) brings its own buffers and pipelines. */
interface IGraphics {
	/** Uploads an RGBA8 image, rows top first, 4 bytes per pixel, and returns its handle. levels is the image then, optionally, its mipmaps, each half
		the size of the last (at least 1; Mipmaps.build makes them). linear picks bilinear filtering over nearest, trilinear with mipmaps. Throws for a size
		of 0 or less, no levels, or a level whose byte count isn't its width*height*4. */
	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, linear:Bool = false):Int;

	/** Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle.
		Throws for another size. */
	public function createBuffer(capacityBytes:Int):Int;

	/** Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true
		uint32 indices (little-endian). Throws for a bad size. */
	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int;

	/** Creates a pipeline drawing kind, alpha-blended when alpha is true, and returns its handle. */
	public function createPipeline(kind:PipelineKind, alpha:Bool):Int;

	/** Replaces a buffer's contents for this frame with the first usedBytes of data; call it between beginFrame and endFrame, at most once per buffer
		per frame (sokol refuses it outside a frame). Throws for an unknown handle or a size out of range. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Starts a frame on a width x height framebuffer: clears it to clearColor (0xRRGGBBAA) and the depth to the farthest, and sets the viewport to all
		of it. Throws when a frame is already open or for a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, clearColor:Int):Void;

	/** Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less. */
	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void;

	/** Draws vertices from firstVertex of buffer's upload this frame through pipeline: whole triangles (three vertices each) or lines (two each), in
		the pipeline's vertex layout. texture is a handle from createTexture for a Sprite2D pipeline, ignored by the others; uniforms are a Color3D or
		Lines3D pipeline's (the view-projection matrix, column-major, 64 bytes), null for a Sprite2D one. Throws for anything invalid, before drawing. */
	public function draw(pipeline:Int, buffer:Int, texture:Int, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void;

	/** Draws indexCount indices (whole triangles) of indices into vertices, two static buffers, as instanceCount instances whose records start at
		instance firstInstance of instances' upload this frame (Lit3DLayout.instanceStride bytes each), through a Lit3D pipeline: texture is its
		base color texture, vertexUniforms the view-projection matrix (64 bytes) and fragmentUniforms the lights and material
		(Lit3DLayout.fragmentUniformBytes). Throws for anything invalid, before drawing. */
	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int, texture:Int,
		vertexUniforms:Bytes, fragmentUniforms:Bytes):Void;

	/** Closes the frame opened by beginFrame; sokol also commits it for presentation. Throws when no frame is open. */
	public function endFrame():Void;

	/** Frees a handle from createTexture. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyTexture(handle:Int):Void;

	/** Frees a handle from createBuffer. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyBuffer(handle:Int):Void;

	/** Frees a handle from createPipeline. Whoever created a handle destroys it, once. Throws for an unknown handle. */
	public function destroyPipeline(handle:Int):Void;

	/** Releases the adapter itself, after its handles are destroyed. */
	public function shutdown():Void;
}
