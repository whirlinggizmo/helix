package helix.platform;

import haxe.io.Bytes;

/** Defines audio decoding from a whole file into mono 32-bit float PCM at 44100 Hz.

	It reads WAV (PCM or float, at any rate), Ogg Vorbis, MP3 and FLAC files, mono or stereo. Stereo is mixed down and other rates are
	resampled. Samples are -1 to 1. */
interface IAudioDecoder extends IPollable {
	/** Decodes a file, off the main thread where the platform can.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param decoded  Receives the samples.
		@param failed  Receives why the file can't be read. */
	function decode(encoded:Bytes, decoded:Bytes->Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the decoder. A decode still running finishes without calling back. */
	function dispose():Void;
}
