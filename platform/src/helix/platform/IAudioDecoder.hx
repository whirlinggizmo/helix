package helix.platform;

import haxe.io.Bytes;

/** Defines audio decoding: a whole WAV (PCM or float, any rate), Ogg Vorbis, MP3 or FLAC file, mono or stereo, into mono 32-bit float PCM at
	44100 Hz, samples -1 to 1, mixed down and resampled. */
interface IAudioDecoder {
	/** Decodes a file, off the main thread where the platform can.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param decoded  Receives the samples.
		@param failed  Receives why the file can't be read. */
	function decode(encoded:Bytes, decoded:Bytes->Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll; call once a frame. */
	function poll():Void;

	/** Closes the decoder; a decode still running finishes without answering. */
	function dispose():Void;
}
