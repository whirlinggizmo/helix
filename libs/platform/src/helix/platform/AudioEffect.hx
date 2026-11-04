package helix.platform;

/** Specifies an effect on a chain of what voices play (`IAudioEffects.addEffect`), with its settings.

	Both targets compute each effect the same way, so a game sounds alike on both. The filters follow the Audio EQ Cookbook, as Web
	Audio's `BiquadFilterNode` does. The reverbs are convolutions, as Web Audio's `ConvolverNode` is, with the same room's response on
	both. The delay, the distortion, the compressor and the pitch shift are the platform's own, the same code natively and in a page. */
enum AudioEffect {
	/** Lets through what is below a frequency and cuts what is above it, as underwater or behind a wall sounds.
		@param frequency  The cutoff in Hz, 10 to 22050.
		@param q  How sharp the cutoff is, 0.1 to 20, where 0.71 is flat to the cutoff. */
	LowPass(frequency:Float, q:Float);

	/** Lets through what is above a frequency and cuts what is below it, as a radio or a telephone sounds.
		@param frequency  The cutoff in Hz, 10 to 22050.
		@param q  How sharp the cutoff is, 0.1 to 20, where 0.71 is flat to the cutoff. */
	HighPass(frequency:Float, q:Float);

	/** Lets through a band around a frequency and cuts what is either side of it.
		@param frequency  The band's middle in Hz, 10 to 22050.
		@param q  How narrow the band is, 0.1 to 20. */
	BandPass(frequency:Float, q:Float);

	/** Raises or lowers a band around a frequency, one band of an equalizer.
		@param frequency  The band's middle in Hz, 10 to 22050.
		@param q  How narrow the band is, 0.1 to 20.
		@param gain  The change in decibels, -40 to 40. */
	Peaking(frequency:Float, q:Float, gain:Float);

	/** Raises or lowers everything below a frequency, an equalizer's bass.
		@param frequency  The shelf's edge in Hz, 10 to 22050.
		@param gain  The change in decibels, -40 to 40. */
	LowShelf(frequency:Float, gain:Float);

	/** Raises or lowers everything above a frequency, an equalizer's treble.
		@param frequency  The shelf's edge in Hz, 10 to 22050.
		@param gain  The change in decibels, -40 to 40. */
	HighShelf(frequency:Float, gain:Float);

	/** Repeats what plays after a time, each repeat quieter, as an echo.
		@param seconds  The time to each repeat, 0.001 to 2.
		@param feedback  How loud each repeat is against the one before, 0 to 0.95.
		@param mix  How much of the echo is heard against what plays, 0 (none) to 1 (only the echo). */
	Delay(seconds:Float, feedback:Float, mix:Float);

	/** Adds the reflections of a room, from a small room to a hall. The room's response is made from its size and damping by the
		platform's own code, the same on both targets.
		@param size  The room's size, 0 (small) to 1 (a hall).
		@param damping  How soon the reflections lose their highs, 0 (bright) to 1 (dull).
		@param mix  How much of the room is heard against what plays, 0 (none) to 1 (only the room). */
	Reverb(size:Float, damping:Float, mix:Float);

	/** Adds the reflections of a recorded room: its impulse response, the echo of a single click played in it.
		@param response  The response as 32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo, up to 10 seconds. It is copied.
		@param channelCount  Its channels, 1 or 2.
		@param mix  How much of the room is heard against what plays, 0 (none) to 1 (only the room). */
	RecordedReverb(response:haxe.io.Bytes, channelCount:Int, mix:Float);

	/** Evens out loud and quiet, lowering what is above a level.
		@param threshold  The level in decibels where it starts, -60 to 0.
		@param ratio  How much it lowers what is above the threshold, 1 (not at all) to 20.
		@param attack  The seconds it takes to lower a sound that gets loud, 0 to 1.
		@param release  The seconds it takes to let a sound back up, 0 to 1. */
	Compressor(threshold:Float, ratio:Float, attack:Float, release:Float);

	/** Clips what plays toward a square wave, from warmth to a broken speaker.
		@param drive  How hard it clips, 0 (not at all) to 1. */
	Distortion(drive:Float);

	/** Raises or lowers the pitch of what plays and keeps its speed, as a voice changer or a slowed world sounds. `IAudio.setPitch`
		changes a voice's pitch and speed together.
		@param ratio  The pitch against what plays, 0.5 (an octave down) to 2 (an octave up), where 1 changes nothing. */
	PitchShift(ratio:Float);
}
