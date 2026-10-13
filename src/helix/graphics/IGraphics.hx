package helix.graphics;

import haxe.io.Bytes;

/** Thin resource/submission contract. No scene policy belongs in an adapter. */
interface IGraphics {
	/** Uploads an RGBA8 image, rows top first, 4 bytes per pixel, and returns its handle; linear picks bilinear filtering over nearest. Throws for a size of 0 or less or a byte count other than width*height*4. */
	public function createTexture(width:Int, height:Int, rgba:Bytes, linear:Bool = false):Int;

	/** The color, 0xRRGGBBAA, the next beginFrame clears to; until it is set, a dark blue. */
	public function setClearColor(color:Int):Void;

	/** Allocates a vertex buffer of capacityBytes, a whole number of vertices, and returns its handle. */
	public function createBuffer(capacityBytes:Int):Int;

	/** Creates the textured, vertex-colored triangle pipeline, alpha-blended when alpha is true, and returns its handle. */
	public function createPipeline(alpha:Bool):Int;

	/** Replaces a buffer's contents for this frame with the first usedBytes of data, a whole number of vertices; call it between beginFrame and endFrame (sokol refuses it outside a frame). Throws for an unknown handle or a size out of range. */
	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void;

	/** Starts a frame on a width x height framebuffer: clears it to the clear color and sets the viewport x, y, w, h in framebuffer pixels from the bottom-left. Throws when a frame is already open or for a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, x:Int, y:Int, w:Int, h:Int):Void;

	/** Draw a triangle-aligned range from the current frame’s uploaded vertices. */
	public function draw(pipeline:Int, buffer:Int, texture:Int, vertices:Int, firstVertex:Int):Void;

	/** Closes the frame opened by beginFrame; sokol also commits it for presentation. Throws when no frame is open. */
	public function endFrame():Void;

	/** Frees a handle from createTexture, createBuffer or createPipeline; kind is "texture", "buffer" or "pipeline". Whoever created a handle destroys it, once. Throws for an unknown kind or handle. */
	public function destroy(kind:String, handle:Int):Void;

	/** Releases the adapter itself, after its handles are destroyed. */
	public function shutdown():Void;
}
