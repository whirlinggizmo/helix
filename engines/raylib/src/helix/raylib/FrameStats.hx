package helix.raylib;

/** Represents the stats of a run of frames, as `GetFrameStats` and `StopFrameStatsRecording` (`helix.raylib.extras.Debug`) return them.

	Each field is 0 for a run of no frames. */
@:structInit class FrameStats {
	/** Gets or sets the number of frames counted. */
	public var frames:Int = 0;

	/** Gets or sets the frames a second: the frames counted over their total time. */
	public var fps:Float = 0;

	/** Gets or sets the frames' mean time, in seconds. */
	public var meanFrameTime:Float = 0;

	/** Gets or sets the least of the slowest 5% of the frames' times (p95), in seconds. */
	public var p95FrameTime:Float = 0;

	/** Gets or sets the slowest frame's time, in seconds. */
	public var slowestFrameTime:Float = 0;

	/** Gets or sets the draw calls a frame sent the GPU, the mean over the frames. */
	public var drawCalls:Float = 0;

	/** Gets or sets the triangles a frame drew, each instance counted, the mean over the frames. */
	public var triangles:Float = 0;

	/** Gets or sets how often a frame's draws switched shader, render state or textures, the mean over the frames. */
	public var stateChanges:Float = 0;

	/** Gets or sets the bytes of textures helix-raylib holds on the GPU. Counted as `FrameStatsStyle.gpuTextures` shows them. */
	public var gpuTextureBytes:Float = 0;

	/** Gets or sets the bytes of buffers helix-raylib holds on the GPU. Counted as `FrameStatsStyle.gpuBuffers` shows them. */
	public var gpuBufferBytes:Float = 0;

	/** Gets or sets the bytes of memory the program holds.

		Natively, the process's resident memory.

		In a page, the script heap where the browser reports it, and 0 where it doesn't. */
	public var memoryBytes:Float = 0;
}
