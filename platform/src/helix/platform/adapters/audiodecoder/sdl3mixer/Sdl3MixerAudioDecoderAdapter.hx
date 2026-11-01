package helix.platform.adapters.audiodecoder.sdl3mixer;

import haxe.io.Bytes;
import helix.platform.IAudioDecoder;
import helix.platform.adapters.audiodecoder.sdl3mixer.internal.AudioDecoderBridge;
import helix.platform.adapters.shared.Mailbox;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;
import helix.platform.adapters.shared.sdl3mixer.Sdl3MixerBridge;
import sys.thread.Thread;

/** Provides `IAudioDecoder` natively over SDL3_mixer's decoder: WAV, Ogg Vorbis, MP3 and FLAC, resampled to 44100 Hz by it, in the file's
	channels (more than 2 mixed down to stereo by SDL), each decode on a worker thread. */
class Sdl3MixerAudioDecoderAdapter implements IAudioDecoder {
	var mailbox = new Mailbox();
	var closed = false;

	/** Creates the decoder. */
	public function new() {
		Sdl3Bridge.nameApp(ProgramName.product());
		Sdl3MixerBridge.version();
		AudioDecoderBridge.init();
	}

	public function decode(encoded:Bytes, decoded:(samples:Bytes, channelCount:Int) -> Void, failed:String->Void):Void
		Thread.create(() -> {
			var result = AudioDecoderBridge.decode(cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
			if (result == null) {
				var message:String = AudioDecoderBridge.error();
				mailbox.post(() -> failed("Audio decode failed: " + message));
				return;
			}
			var samples = Bytes.alloc(AudioDecoderBridge.count(result) * 4),
				channels = AudioDecoderBridge.channels(result);
			AudioDecoderBridge.take(result, cpp.Pointer.arrayElem(samples.getData(), 0).raw);
			mailbox.post(() -> decoded(samples, channels));
		});

	public function poll():Void
		if (!closed)
			mailbox.deliver();

	/** Closes the decoder: a decode still running on its worker finishes, and its answer is dropped. */
	public function dispose():Void
		closed = true;
}
