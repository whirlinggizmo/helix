package helix.platform;

import haxe.io.Bytes;

/** Defines audio decoding from a whole file into 32-bit float PCM, at the file's own rate or one asked for.

	It reads WAV (PCM or float, at any rate), Ogg Vorbis, MP3 and FLAC files. A clip plays at 44100 Hz (`IAudio.createClip`), so a
	program decoding for one asks for 44100; one keeping a file's samples as they are asks for 0. A mono file decodes to mono and a
	stereo file to stereo, interleaved, left first. A file of more channels is mixed down to stereo by the platform's speaker mix: SDL's
	channel conversion natively, Web Audio's down-mix in a page, which may differ slightly. Samples are -1 to 1. */
interface IAudioDecoder extends IPollable {
	/** Decodes a file, off the main thread where the platform can.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param sampleRate  The frames a second to decode at: 0 for the file's own rate, any other resampled to it.
		@param decoded  Receives the samples, their number of channels (1 or 2) and their frames a second: the rate asked, or for 0 the
			file's (44100 in a page when its header can't be read).
		@param failed  Receives why the file can't be read. */
	function decode(encoded:Bytes, sampleRate:Int, decoded:(samples:Bytes, channelCount:Int, sampleRate:Int) -> Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the decoder. A decode still running finishes without calling back. */
	function dispose():Void;
}
