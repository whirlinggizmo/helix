package helix.audio;

import haxe.io.Bytes;
import helix.audio.AudioDecoding.AudioDecodeResult;

/** Audio decoding on a platform: a whole WAV (PCM or float, any rate), Ogg (Vorbis, Opus) or MP3 file, mono or stereo, into mono 32-bit
	float PCM at 44100 Hz, samples -1 to 1 (mixed down and resampled as the platform can). Limits, queuing and cancellation are the shared
	AudioDecoding's. */
@:noCompletion
interface IAudioDecoder {
	/** Decodes encoded; done runs once on the host thread, never during this call: Decoded or Failed (a file it can't read). */
	public function decode(encoded:Bytes, done:AudioDecodeResult->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll; the shared AudioDecoding calls it once a frame. */
	public function poll():Void;
}
