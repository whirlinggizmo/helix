package helix.adapter.audiodecoder.webaudio;

import haxe.io.Bytes;
import helix.audio.AudioDecoding.AudioDecodeResult;
import helix.audio.IAudioDecoder;

/** IAudioDecoder in a browser: decodeAudioData on an OfflineAudioContext at 44100 Hz (no user gesture needed; it resamples), its channels
	mixed down to mono. */
class WebAudioDecoderAdapter implements IAudioDecoder {
	var context:Dynamic;

	/** The page's decoder, made at the first decode. */
	public function new() {}

	public function decode(encoded:Bytes, done:AudioDecodeResult->Void):Void {
		if (context == null)
			context = js.Syntax.code("new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 1, 44100)");
		// decodeAudioData takes its input over: a copy, as the caller keeps its bytes.
		var data:js.lib.ArrayBuffer = encoded.getData().slice(0, encoded.length);
		context.decodeAudioData(data).then(buffer -> {
			try {
				var frames:Int = buffer.length,
					channels:Array<js.lib.Float32Array> = [];
				if (buffer.numberOfChannels < 1 || buffer.numberOfChannels > 2 || frames <= 0)
					throw "Unsupported decoded channels or length";
				for (c in 0...buffer.numberOfChannels)
					channels.push(buffer.getChannelData(c));
				var samples = Bytes.alloc(frames * 4);
				for (i in 0...frames) {
					var value = 0.;
					for (channel in channels)
						value += channel[i];
					value /= channels.length;
					samples.setFloat(i * 4, value < -1 ? -1 : value > 1 ? 1 : value);
				}
				done(Decoded(samples));
			} catch (error:Dynamic)
				done(Failed(Std.string(error)));
			return null;
		}, error -> {
			done(Failed("Audio decode failed: " + Std.string(error)));
			return null;
		});
	}

	/** Nothing to deliver: the page's promises already resolve on the host thread. */
	public function poll():Void {}
}
