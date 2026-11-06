package helix.raylib.internal;

/** Counts the bytes helix-raylib holds on the GPU, textures and buffers apart, as it makes and frees them, for the frame stats
	(`FrameStatsStyle.gpuTextures` and `gpuBuffers`). Each handle's bytes are kept, so freeing needs only the handle.

	Textures are counted as their levels' bytes (a render texture's with its depth, a data texture's as 16 a texel), buffers as their
	bytes or capacity. What the GPU rounds or pads isn't known here. */
@:noCompletion
class GpuMemory {
	/** The bytes of the textures held: 2D textures, cubemaps, render textures and the skinning palettes. */
	public static var textureBytes = 0.;

	/** The bytes of the buffers held: meshes' vertices and indices, the frame's batch and its quad indices, a frame's instances. */
	public static var bufferBytes = 0.;

	static final textures = new Map<Int, Float>();
	static final buffers = new Map<Int, Float>();

	/** Counts a texture made, and returns its handle.

		@param handle  The texture's handle.
		@param bytes  Its bytes on the GPU.
		@return  The handle. */
	public static function texture(handle:Int, bytes:Float):Int {
		if (handle != 0) {
			textures.set(handle, bytes);
			textureBytes += bytes;
		}
		return handle;
	}

	/** Counts a buffer made, and returns its handle.

		@param handle  The buffer's handle.
		@param bytes  Its bytes on the GPU.
		@return  The handle. */
	public static function buffer(handle:Int, bytes:Float):Int {
		if (handle != 0) {
			buffers.set(handle, bytes);
			bufferBytes += bytes;
		}
		return handle;
	}

	/** Counts a texture or buffer freed, or gone with the GPU's context. Nothing for a handle it doesn't know.

		@param handle  The handle. */
	public static function freed(handle:Int):Void {
		var bytes = textures.get(handle);
		if (bytes != null) {
			textures.remove(handle);
			textureBytes -= bytes;
			return;
		}
		bytes = buffers.get(handle);
		if (bytes != null) {
			buffers.remove(handle);
			bufferBytes -= bytes;
		}
	}

	/** Counts a texture as held under another handle (a render texture moved by a copy on write).

		@param handle  The handle it had.
		@param moved  The handle it has now. */
	public static function moved(handle:Int, moved:Int):Void {
		var bytes = textures.get(handle);
		if (bytes != null) {
			textures.remove(handle);
			textures.set(moved, bytes);
		}
	}

	/** Returns bytes as megabytes with one decimal, for the stats: "1.5", capped at 9999.9.

		@param bytes  The bytes.
		@return  The text. */
	public static function megabytes(bytes:Float):String {
		var tenths = Math.round(bytes / (1024 * 1024) * 10);
		if (tenths > 99999)
			tenths = 99999;
		return Std.int(tenths / 10) + "." + (tenths % 10);
	}
}
