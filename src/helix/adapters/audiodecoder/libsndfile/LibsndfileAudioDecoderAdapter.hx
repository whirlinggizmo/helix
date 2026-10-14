package helix.adapters.audiodecoder.libsndfile;

import haxe.io.Bytes;
import helix.adapters.audiodecoder.libsndfile.internal.CodecBridge;
import helix.adapters.internal.Mailbox;
import helix.audio.AudioDecoding.AudioDecodeResult;
import helix.audio.IAudioDecoder;
import sys.thread.Thread;

/** IAudioDecoder natively over libsndfile (Ogg Vorbis and Opus, MP3; mixed down and resampled to mono at 44100 Hz in its C), each decode on a
	worker thread. */
class LibsndfileAudioDecoderAdapter implements IAudioDecoder {
	var mailbox = new Mailbox();

	/** A decoder with no work. */
	public function new() {}

	public function decode(encoded:Bytes, done:AudioDecodeResult->Void):Void
		Thread.create(() -> {
			var result = decodeNow(encoded);
			mailbox.post(() -> done(result));
		});

	static function decodeNow(encoded:Bytes):AudioDecodeResult {
		var codec = CodecBridge.codecMemory(cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
		if (codec == 0)
			return Failed("Audio decode failed; expected mono or stereo Vorbis, Opus or MP3");
		var result:AudioDecodeResult;
		try {
			var frames = Std.int(CodecBridge.codecFrames(codec));
			if (frames <= 0)
				throw "Empty decoded audio";
			var samples = Bytes.alloc(frames * 4), chunk = Bytes.alloc(2048 * 4), count = 0;
			while (true) {
				var n = CodecBridge.codecRead(codec, cpp.Pointer.arrayElem(chunk.getData(), 0).raw, 2048);
				if (n < 0)
					throw "Audio decode failed";
				if (n == 0)
					break;
				if ((count + n) * 4 > samples.length)
					throw "Audio sample count changed during decode";
				samples.blit(count * 4, chunk, 0, n * 4);
				count += n;
			}
			if (count == 0)
				throw "Empty decoded audio";
			result = Decoded(samples.sub(0, count * 4));
		} catch (error:Dynamic)
			result = Failed(Std.string(error));
		CodecBridge.codecClose(codec);
		return result;
	}

	public function poll():Void
		mailbox.deliver();
}
