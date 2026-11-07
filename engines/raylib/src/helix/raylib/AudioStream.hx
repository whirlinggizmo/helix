package helix.raylib;

/** Represents raylib's `AudioStream`: samples a program makes as it goes, played as `UpdateAudioStream` gives them, over helix-services'
	`SampleQueue`.

	Holds raylib's double buffer: two buffers of `SetAudioStreamBufferSizeDefault` frames each, 1470 until set (a 30th of a second at 44100
	Hz).

	Each update fills one buffer while the other plays. */
class AudioStream {
	/** Gets the sample rate, in frames a second. */
	public var sampleRate(default, null):Int;

	/** Gets the bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float). */
	public var sampleSize(default, null):Int;

	/** Gets the number of channels: 1 is mono, 2 stereo. */
	public var channels(default, null):Int;

	// The service's queue, null once unloaded or when it couldn't be made; its voice; a buffer's frames; its settings; the program's
	// callback, null for none.
	@:allow(helix.raylib)
	var queue:Null<helix.services.audio.SampleQueue> = null;
	@:allow(helix.raylib)
	var voice:Null<helix.services.audio.Voice> = null;
	@:allow(helix.raylib)
	var bufferFrames = 0;
	@:allow(helix.raylib)
	var volume = 1.;
	@:allow(helix.raylib)
	var pitch = 1.;
	@:allow(helix.raylib)
	var pan = .5;
	@:allow(helix.raylib)
	var callback:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void> = null;

	@:allow(helix.raylib)
	function new(sampleRate:Int, sampleSize:Int, channels:Int) {
		this.sampleRate = sampleRate;
		this.sampleSize = sampleSize;
		this.channels = channels;
	}
}
