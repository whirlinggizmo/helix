package helix.platform.adapters.audiodecoder.webaudio;

import haxe.io.Bytes;
import helix.platform.IAudioDecoder;

/** Provides `IAudioDecoder` in a browser page: decodeAudioData on an OfflineAudioContext at 44100 Hz, which needs no user gesture and
	resamples, in the file's channels; a file of more than 2 is rendered through a stereo OfflineAudioContext, which mixes it down by Web
	Audio's speaker rules. */
class WebAudioDecoderAdapter implements IAudioDecoder {
	var context:Dynamic;
	var closed = false;

	/** Creates the decoder; the page's decoding context is made at the first decode. */
	public function new() {}

	public function decode(encoded:Bytes, decoded:(samples:Bytes, channels:Int) -> Void, failed:String->Void):Void {
		if (context == null)
			context = js.Syntax.code("new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 1, 44100)");
		// decodeAudioData takes its input over: a copy, as the caller keeps its bytes.
		var data:js.lib.ArrayBuffer = encoded.getData().slice(0, encoded.length);
		function fail(error:Dynamic):Null<Dynamic> {
			if (!closed)
				failed("Audio decode failed: " + Std.string(error));
			return null;
		}
		context.decodeAudioData(data).then(buffer -> {
			if (buffer.numberOfChannels <= 2)
				deliver(buffer, decoded, failed);
			else {
				// Mixed down to stereo as Web Audio's destination mixes speakers.
				var mixer:Dynamic = js.Syntax.code("new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(2, {0}, 44100)", buffer.length);
				var source:Dynamic = mixer.createBufferSource();
				source.buffer = buffer;
				source.connect(mixer.destination);
				source.start(0);
				mixer.startRendering().then(mixed -> {
					deliver(mixed, decoded, failed);
					return null;
				}, fail);
			}
			return null;
		}, fail);
	}

	// Interleaves a decoded buffer of 1 or 2 channels into samples held to -1 to 1, and hands them over.
	function deliver(buffer:Dynamic, decoded:(samples:Bytes, channels:Int) -> Void, failed:String->Void):Void {
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
				decoded(samples, count);
		} catch (error:Dynamic)
			if (!closed)
				failed(Std.string(error));
	}

	// Nothing to deliver: the page's promises already resolve on the main thread.
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}
