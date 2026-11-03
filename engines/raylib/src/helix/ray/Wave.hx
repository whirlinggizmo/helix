package helix.ray;

/** Represents raylib's `Wave`: sound samples in memory, as `LoadWaveAsync` reads them and `LoadSoundFromWave` plays them.

	The samples are interleaved, a frame a sample for each channel, left first: 8-bit unsigned, 16-bit signed or 32-bit float, little-endian.
	The `Wave*` functions change a wave in place, as raylib's do through its pointer: its fields are replaced. */
class Wave {
	/** Gets or sets the number of frames, a sample for each channel. */
	public var frameCount:Int;

	/** Gets or sets the frames a second. */
	public var sampleRate:Int;

	/** Gets or sets the bits a sample takes: 8, 16 or 32. */
	public var sampleSize:Int;

	/** Gets or sets the number of channels: 1 is mono, 2 stereo. */
	public var channels:Int;

	/** Gets or sets the samples, or null for none. */
	public var data:Null<haxe.io.Bytes>;

	/** Creates a wave's record. Its fields are zero and its data null unless given, as raylib's `Wave wave = { 0 }` is.

		@param frameCount  The number of frames.
		@param sampleRate  The frames a second.
		@param sampleSize  The bits a sample takes.
		@param channels  The number of channels.
		@param data  Optional. The samples. */
	public function new(frameCount:Int = 0, sampleRate:Int = 0, sampleSize:Int = 0, channels:Int = 0, ?data:haxe.io.Bytes) {
		this.frameCount = frameCount;
		this.sampleRate = sampleRate;
		this.sampleSize = sampleSize;
		this.channels = channels;
		this.data = data;
	}
}
