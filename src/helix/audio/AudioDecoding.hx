package helix.audio;

import haxe.io.Bytes;
import helix.assets.IRequest;
import helix.core.Jobs;

/** How a decode ended: mono 32-bit float PCM at 44100 Hz, samples -1 to 1; a failure message; or cancellation. */
enum AudioDecodeResult {
	Decoded(samples:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Whole-file audio decoding, the same on every platform: a WAV (mono PCM16 at 44100 Hz, at most 4 seconds) decoded here, an Ogg (Vorbis,
	Opus) or MP3 by the platform's IAudioDecoder; at most 8 MiB encoded and 2Mi frames decoded; at most two at once, each completing exactly
	once on the host thread. */
class AudioDecoding {
	/** The largest encoded file, in bytes. */
	public static inline var MAX_ENCODED = 8 * 1024 * 1024;

	/** The most frames a decoded clip has. */
	public static inline var MAX_FRAMES = 2 * 1024 * 1024;

	var decoder:IAudioDecoder;
	var jobs = new Jobs(2);

	/** Decodes compressed files with decoder. */
	public function new(decoder:IAudioDecoder)
		this.decoder = decoder;

	/** What encoded is by its first bytes: "wav", "ogg", "mp3" (an ID3 tag or an MPEG frame's sync bits), or null. */
	public static function sniff(encoded:Bytes):Null<String> {
		if (encoded.length < 4)
			return null;
		var magic = encoded.getString(0, 4);
		return magic == "RIFF" ? "wav" : magic == "OggS" ? "ogg" : encoded.getString(0, 3) == "ID3"
			|| encoded.get(0) == 0xFF
			&& encoded.get(1) & 0xE0 == 0xE0 ? "mp3" : null;
	}

	/** Decodes encoded whole; complete runs exactly once on the host thread at a later poll. Failed for a closed service, more than 8 MiB
		encoded, more than 2Mi frames decoded, or an unsupported or corrupt file. */
	public function decode(encoded:Bytes, complete:AudioDecodeResult->Void):IRequest
		return jobs.add(job -> {
			var kind = sniff(encoded);
			if (encoded.length > MAX_ENCODED)
				job.finish(Failed("Encoded audio exceeds byte limit"));
			else if (kind == null)
				job.finish(Failed("Unsupported encoded audio; expected WAV, Ogg or MP3"));
			else if (kind == "wav")
				job.finish(try Decoded(Wav.decode(encoded)) catch (error:Dynamic) Failed(Std.string(error)));
			else
				decoder.decode(encoded, result -> job.finish(switch result {
					case Decoded(samples) if (samples.length > MAX_FRAMES * 4): Failed("Decoded PCM exceeds frame limit");
					case Decoded(samples): try {
							Pcm.validate(samples);
							result;
						} catch (error:Dynamic)
							Failed(Std.string(error));
					case _: result;
				}));
		}, complete, Cancelled, Failed("Closed audio decoder"));

	/** Delivers finished decodes, starts queued ones and runs completions. Call once per frame. */
	public function poll():Void {
		decoder.poll();
		jobs.poll();
	}

	/** Cancels every pending decode (each completes Cancelled) and refuses later ones. */
	public function shutdown():Void
		jobs.shutdown();
}
