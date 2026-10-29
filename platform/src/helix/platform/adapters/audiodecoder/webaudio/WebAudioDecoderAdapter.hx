package helix.platform.adapters.audiodecoder.webaudio;

import haxe.io.Bytes;
import helix.platform.IAudioDecoder;

/** Provides `IAudioDecoder` in a browser page: decodeAudioData on an OfflineAudioContext at 44100 Hz, which needs no user gesture and
	resamples, its channels mixed down to mono. */
class WebAudioDecoderAdapter implements IAudioDecoder {
	var context:Dynamic;
	var closed = false;

	/** Creates the decoder; the page's decoding context is made at the first decode. */
	public function new() {}

	public function decode(encoded:Bytes, decoded:Bytes->Void, failed:String->Void):Void {
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
				if (!closed)
					decoded(samples);
			} catch (error:Dynamic)
				if (!closed)
					failed(Std.string(error));
			return null;
		}, error -> {
			if (!closed)
				failed("Audio decode failed: " + Std.string(error));
			return null;
		});
	}

	// Nothing to deliver: the page's promises already resolve on the main thread.
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}
