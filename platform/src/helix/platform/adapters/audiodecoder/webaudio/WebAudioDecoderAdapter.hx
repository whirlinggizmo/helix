package helix.platform.adapters.audiodecoder.webaudio;

import haxe.io.Bytes;
import helix.formats.audio.AudioHeader;
import helix.platform.IAudioDecoder;

/** Provides `IAudioDecoder` in a browser page: decodeAudioData on an OfflineAudioContext made at the rate asked, which needs no user
	gesture and resamples to its rate, in the file's channels; a file of more than 2 is rendered through a stereo OfflineAudioContext,
	which mixes it down by Web Audio's speaker rules. For the file's own rate, the context is made at the rate its header records
	(`AudioHeader.readSampleRate`), so nothing is resampled; a header it can't read, or a rate a context can't take, decodes at 44100. */
class WebAudioDecoderAdapter implements IAudioDecoder {
	// A decoding context for each rate asked, made at its first decode.
	final contexts = new Map<Int, Dynamic>();
	var closed = false;

	/** Creates the decoder; the page's decoding contexts are made at the first decode at each rate. */
	public function new() {}

	public function decode(encoded:Bytes, sampleRate:Int, decoded:(samples:Bytes, channelCount:Int, sampleRate:Int) -> Void, failed:String->Void):Void {
		var rate = sampleRate > 0 ? sampleRate : AudioHeader.readSampleRate(encoded.length > 65536 ? encoded.sub(0, 65536) : encoded);
		// An OfflineAudioContext takes 3000 to 768000 Hz in every browser that has one.
		if (rate < 3000 || rate > 768000)
			rate = 44100;
		var context = contexts.get(rate);
		if (context == null) {
			context = js.Syntax.code("new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 1, {0})", rate);
			contexts.set(rate, context);
		}
		// decodeAudioData takes its input over: a copy, as the caller keeps its bytes.
		var data:js.lib.ArrayBuffer = encoded.getData().slice(0, encoded.length);
		function fail(error:Dynamic):Null<Dynamic> {
			if (!closed)
				failed("Audio decode failed: " + Std.string(error));
			return null;
		}
		context.decodeAudioData(data).then(buffer -> {
			if (buffer.numberOfChannels <= 2)
				deliver(buffer, rate, decoded, failed);
			else {
				// Mixed down to stereo as Web Audio's destination mixes speakers.
				var mixer:Dynamic = js.Syntax.code("new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(2, {0}, {1})", buffer.length, rate);
				var source:Dynamic = mixer.createBufferSource();
				source.buffer = buffer;
				source.connect(mixer.destination);
				source.start(0);
				mixer.startRendering().then(mixed -> {
					deliver(mixed, rate, decoded, failed);
					return null;
				}, fail);
			}
			return null;
		}, fail);
	}

	// Interleaves a decoded buffer of 1 or 2 channels into samples held to -1 to 1, and hands them over with their rate.
	function deliver(buffer:Dynamic, rate:Int, decoded:(samples:Bytes, channelCount:Int, sampleRate:Int) -> Void, failed:String->Void):Void {
		try {
			var frames:Int = buffer.length,
				count:Int = buffer.numberOfChannels;
			if (count < 1 || count > 2 || frames <= 0)
				throw "Unsupported decoded channels or length";
			var channels:Array<js.lib.Float32Array> = [for (c in 0...count) buffer.getChannelData(c)];
			var samples = Bytes.alloc(frames * count * 4);
			for (i in 0...frames)
				for (c in 0...count) {
					var value = channels[c][i];
					samples.setFloat((i * count + c) * 4, value < -1 ? -1 : value > 1 ? 1 : value);
				}
			if (!closed)
				decoded(samples, count, rate);
		} catch (error:Dynamic)
			if (!closed)
				failed(Std.string(error));
	}

	// Nothing to deliver: the page's promises already resolve on the main thread.
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}
