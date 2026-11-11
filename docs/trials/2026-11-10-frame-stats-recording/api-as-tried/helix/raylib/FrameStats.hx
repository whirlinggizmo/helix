package helix.raylib;

/** Represents the stats of a run of frames, as `GetFrameStats` and `StopFrameStatsRecording` (`helix.raylib.extras.Debug`) return them. */
@:structInit class FrameStats {
	/** Gets or sets the number of frames recorded. */
	public var frames:Int;

	/** Gets or sets the frames a second: the frames recorded over their total time. */
	public var fps:Float;

	/** Gets or sets the frames' mean time, in seconds. */
	public var meanFrameTime:Float;

	/** Gets or sets the least of the slowest 5% of the frames' times (p95), in seconds. */
	public var p95FrameTime:Float;

	/** Gets or sets the slowest frame's time, in seconds. */
	public var slowestFrameTime:Float;

	/** Gets or sets the draw calls a frame sent the GPU, the mean over the frames. */
	public var drawCalls:Float;

	/** Gets or sets the triangles a frame drew, each instance counted, the mean over the frames. */
	public var triangles:Float;

	/** Gets or sets how often a frame's draws switched shader, render state or texture, the mean over the frames. */
	public var stateChanges:Float;

	/** Gets or sets the bytes of textures helix-raylib holds on the GPU, at the call. */
	public var gpuTextureBytes:Float;

	/** Gets or sets the bytes of buffers helix-raylib holds on the GPU, at the call. */
	public var gpuBufferBytes:Float;

	/** Gets or sets the bytes of memory the program holds, at the call, as `ISystem.getMemoryBytes` reports them. */
	public var memoryBytes:Float;
}
