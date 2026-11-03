import haxe.io.Bytes;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.StreamSource;

/** Represents one step: what it starts, when it is ready, and what it checks then. */
typedef Step = {
	/** The step's name, in a failure's message. */
	final name:String;

	/** Starts the step, once. */
	final ?enter:() -> Void;

	/** Whether the step is done waiting, checked each frame; omitted, it waits `wait` seconds. */
	final ?ready:() -> Bool;

	/** How long the step waits, in seconds, when it has no `ready`. */
	final ?wait:Float;

	/** Checks what the step did, once it is ready. */
	final ?check:() -> Void;
}

/** Checks helix-platform's audio output and decoder against the clock, with the library alone.

	The steps: a mono and a stereo WAV decoded to their own channels; a 22050 Hz WAV decoded at 22050 Hz and resampled to 44100; a stereo clip played, its position advancing with time, moved, and
	ended; a stream of a WAV opened, its length read, played, moved, ended and played again; in a page, a stream whose play() the browser
	refuses (as a phone does outside a gesture) waiting, not ended, and played by the next gesture, and a stream asked for while audio
	is suspended started in the gesture that resumes it; a queue fed half a second, its queued frames falling as it
	plays, run dry while still playing, and resuming when fed again. The WAVs are made here. Times are checked within a tenth of a second
	or so, as a frame's timing and the output's buffering allow.

	Built from the hxml files beside it: in a page over Web Audio, natively over SDL3_mixer (with `SDL_AUDIO_DRIVER=dummy`, which still
	mixes in time). It ends with `{passed, checks, failures}` as JSON: printed natively, exiting 1 on a failure, and in a page in
	`window.helixResult`, null until then. Run by `tools/platform_checks.py`. */
class AudioTests {
	static inline final RATE = 44100;
	// How long a step may wait for what it waits on, in seconds.
	static inline final TIMEOUT = 10.;

	static var audio:IAudio;
	static var decoder:IAudioDecoder;
	static var steps:Array<Step>;
	static var next = 0;
	static var entered = -1.;
	static var checks = 0;
	static var failures:Array<String> = [];
	static var current = "";

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		audio = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		decoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
		// The adapter starts audio at a key press; the page check's browser lets it start without a real one.
		js.Browser.window.dispatchEvent(new js.html.KeyboardEvent("keydown"));
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		audio = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		decoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
		setup();
		while (tick())
			Sys.sleep(1 / 120);
		finish();
		#end
	}

	/** Runs one frame: polls the audio, and moves on to the next step once the one waiting is ready. False once every step has run. */
	static function tick():Bool {
		audio.poll();
		decoder.poll();
		while (next < steps.length) {
			var step = steps[next];
			current = step.name;
			var now = haxe.Timer.stamp();
			try {
				if (entered < 0) {
					entered = now;
					if (step.enter != null)
						step.enter();
				}
				var ready = step.ready != null ? step.ready() : now - entered >= (step.wait == null ? 0 : step.wait);
				if (!ready) {
					if (now - entered < TIMEOUT)
						return true;
					fail('not ready after $TIMEOUT seconds');
				} else if (step.check != null)
					step.check();
			} catch (error:Dynamic)
				fail('threw: $error');
			next++;
			entered = -1;
		}
		return false;
	}

	/** Records a check's outcome. */
	static function check(value:Bool, message:String):Void {
		checks++;
		if (!value)
			fail(message);
	}

	/** Records a check that a value is within tolerance of what's expected. */
	static function near(value:Float, expected:Float, tolerance:Float, what:String):Void
		check(Math.abs(value - expected) <= tolerance, '$what: $value, expected $expected within $tolerance');

	static function fail(message:String):Void
		failures.push('$current: $message');

	/** Returns a 16-bit WAV of frames frames at rate (44100 when omitted): mono at left, or stereo at left and right. */
	static function wav(frames:Int, channels:Int, left:Float, right:Float, rate = RATE):Bytes {
		var data = frames * channels * 2, bytes = Bytes.alloc(44 + data);
		bytes.blit(0, Bytes.ofString("RIFF"), 0, 4);
		bytes.setInt32(4, 36 + data);
		bytes.blit(8, Bytes.ofString("WAVEfmt "), 0, 8);
		bytes.setInt32(16, 16);
		bytes.setUInt16(20, 1);
		bytes.setUInt16(22, channels);
		bytes.setInt32(24, rate);
		bytes.setInt32(28, rate * channels * 2);
		bytes.setUInt16(32, channels * 2);
		bytes.setUInt16(34, 16);
		bytes.blit(36, Bytes.ofString("data"), 0, 4);
		bytes.setInt32(40, data);
		for (i in 0...frames)
			for (c in 0...channels)
				bytes.setUInt16(44 + (i * channels + c) * 2, Std.int((c == 0 ? left : right) * 32767) & 0xffff);
		return bytes;
	}

	/** Returns 32-bit float frames of a stereo queue's samples, left and right. */
	static function frames(count:Int, left:Float, right:Float):Bytes {
		var bytes = Bytes.alloc(count * 8);
		for (i in 0...count) {
			bytes.setFloat(i * 8, left);
			bytes.setFloat(i * 8 + 4, right);
		}
		return bytes;
	}

	/** Returns where a stream can be opened from with the file's bytes: a file natively, a Blob's URL in a page. */
	static function place(bytes:Bytes):StreamSource {
		#if js
		var blob = new js.html.Blob([bytes.getData()], {type: "audio/wav"});
		return Local(js.html.URL.createObjectURL(blob));
		#else
		sys.FileSystem.createDirectory("native");
		sys.io.File.saveBytes("native/stream.wav", bytes);
		return Local("native/stream.wav");
		#end
	}

	/** Makes the steps. */
	static function setup():Void {
		var mono:Null<{samples:Bytes, channels:Int}> = null,
			stereo:Null<{samples:Bytes, channels:Int}> = null,
			own:Null<Bytes> = null,
			resampled:Null<Bytes> = null;
		var clip = 0, stream = 0, queue = 0, voice = 0, started = 0., queued = 0;
		var streamFile = wav(Std.int(RATE * 1.5), 2, .5, -.25);
		function decode(file:Bytes, decoded:(Bytes, Int) -> Void, rate = RATE):Void
			decoder.decode(file, rate, decoded, why -> fail('not decoded: $why'));
		function elapsed():Float
			return haxe.Timer.stamp() - started;
		steps = [
			{name: "audio runs", ready: () -> audio.running, check: () -> check(audio.available, "no output")},
			{
				name: "a mono WAV decodes to mono",
				enter: () -> decode(wav(RATE >> 2, 1, .5, 0), (samples, channels) -> mono = {samples: samples, channels: channels}),
				ready: () -> mono != null || failures.length > 0,
				check: () -> {
					check(mono.channels == 1, 'channels: ${mono.channels}');
					near(mono.samples.length / 4, RATE >> 2, 2, "frames");
					near(mono.samples.getFloat(4000), .5, 1e-3, "a sample");
				}
			},
			{
				name: "a stereo WAV decodes to stereo",
				enter: () -> decode(streamFile, (samples, channels) -> stereo = {samples: samples, channels: channels}),
				ready: () -> stereo != null || failures.length > 0,
				check: () -> {
					check(stereo.channels == 2, 'channels: ${stereo.channels}');
					near(stereo.samples.length / 8, RATE * 1.5, 2, "frames");
					near(stereo.samples.getFloat(8000), .5, 1e-3, "a left sample");
					near(stereo.samples.getFloat(8004), -.25, 1e-3, "a right sample");
				}
			},
			{
				name: "a 22050 Hz WAV decodes at its own rate, every frame",
				enter: () -> decode(wav(5512, 1, .5, 0, 22050), (samples, _) -> own = samples, 22050),
				ready: () -> own != null || failures.length > 0,
				check: () -> {
					check(own.length == 5512 * 4, 'frames: ${own.length / 4}');
					near(own.getFloat(8000), .5, 1e-3, "a sample");
				}
			},
			{
				name: "a 22050 Hz WAV resampled to 44100 Hz",
				enter: () -> decode(wav(5512, 1, .5, 0, 22050), (samples, _) -> resampled = samples, 44100),
				ready: () -> resampled != null || failures.length > 0,
				check: () -> {
					near(resampled.length / 4, 11024, 4, "frames");
					near(resampled.getFloat(16000), .5, 1e-3, "a sample");
				}
			},
			{
				name: "a stereo clip plays, its position advancing",
				enter: () -> {
					clip = audio.createClip(stereo.samples, stereo.channels);
					voice = audio.playClip(clip, false, 1);
					started = haxe.Timer.stamp();
				},
				wait: .5,
				check: () -> {
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), elapsed(), .1, "position");
				}
			},
			{
				name: "a clip's position moves",
				enter: () -> {
					check(audio.setPosition(voice, 1), "not moved");
					near(audio.getPosition(voice), 1, .05, "position moved to");
					started = haxe.Timer.stamp() - 1;
				},
				wait: .2,
				check: () -> near(audio.getPosition(voice), elapsed(), .1, "position after")
			},
			{
				name: "a clip ends",
				ready: () -> !audio.isPlaying(voice),
				check: () -> {
					near(elapsed(), 1.5, .15, "ended at");
					check(audio.getPosition(voice) == 0 && !audio.setPosition(voice, 0), "an ended voice has a position");
					audio.disposeClip(clip);
				}
			},
			{
				name: "a stream opens, its length and channels known",
				enter: () -> audio.openStream(place(streamFile), id -> stream = id, why -> fail('not opened: $why')),
				ready: () -> stream != 0 || failures.length > 0,
				check: () -> {
					near(audio.getStreamDuration(stream), 1.5, 1 / 60, "duration");
					check(audio.getStreamChannelCount(stream) == 2, 'channels: ${audio.getStreamChannelCount(stream)}');
				}
			},
			{
				name: "a stream plays, its position advancing",
				enter: () -> {
					voice = audio.playStream(stream, false, 1);
					started = haxe.Timer.stamp();
				},
				wait: .5,
				check: () -> {
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), elapsed(), .15, "position");
				}
			},
			{
				name: "a stream's position moves",
				enter: () -> {
					check(audio.setPosition(voice, 1), "not moved");
					near(audio.getPosition(voice), 1, .05, "position moved to");
					started = haxe.Timer.stamp() - 1;
				},
				wait: .2,
				check: () -> near(audio.getPosition(voice), elapsed(), .15, "position after")
			},
			{
				name: "a stream ends",
				ready: () -> !audio.isPlaying(voice),
				check: () -> {
					near(elapsed(), 1.5, .2, "ended at");
					near(audio.getStreamDuration(stream), 1.5, 1 / 60, "duration after");
				}
			},
			{
				name: "a stream plays again from its start",
				enter: () -> {
					voice = audio.playStream(stream, false, 1);
					started = haxe.Timer.stamp();
				},
				wait: .3,
				check: () -> {
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), elapsed(), .15, "position");
					audio.stop(voice);
					check(!audio.isPlaying(voice), "not stopped");
				}
			},
			#if js
			{
				// As a phone refuses a media element's play() outside a gesture: refused, the voice waits, with its volume and place, and
				// isn't tried again at a poll; the next gesture plays it.
				name: "a stream the browser refuses waits for a gesture",
				enter: () -> {
					js.Syntax.code("window.helixRealPlay = HTMLMediaElement.prototype.play; window.helixPlays = 0");
					js.Syntax.code("HTMLMediaElement.prototype.play = function() { window.helixPlays++; return Promise.reject(new DOMException('refused', 'NotAllowedError')); }");
					voice = audio.playStream(stream, false, 1);
					check(audio.setVolume(voice, .5), "volume not set");
				},
				wait: .3,
				check: () -> {
					check(audio.isPlaying(voice), "a refused voice ended");
					check(audio.getPosition(voice) == 0, 'position: ${audio.getPosition(voice)}');
					var plays:Int = js.Syntax.code("window.helixPlays");
					check(plays == 1, 'play() asked $plays times, not once, before a gesture');
					js.Syntax.code("HTMLMediaElement.prototype.play = window.helixRealPlay");
					js.Browser.window.dispatchEvent(new js.html.KeyboardEvent("keydown"));
					started = haxe.Timer.stamp();
				}
			}, {
				name: "the gesture plays it",
				wait: .3,
				check: () -> {
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), elapsed(), .15, "position");
					audio.stop(voice);
				}
			}, {
				name: "audio suspended as the page loses focus",
				enter: () -> js.Browser.window.dispatchEvent(new js.html.Event("blur")),
				ready: () -> !audio.running
			}, {
				// A phone plays a media element only in a gesture: a stream's voice asked for while audio waits starts in the gesture itself,
				// not at a poll after it.
				name: "a stream asked for while audio waits starts in the gesture",
				enter: () -> {
					voice = audio.playStream(stream, false, 1);
					js.Syntax.code("window.helixRealPlay = HTMLMediaElement.prototype.play; window.helixPlays = 0");
					js.Syntax.code("HTMLMediaElement.prototype.play = function() { if (!this.muted) window.helixPlays++; return window.helixRealPlay.call(this); }");
					js.Browser.window.dispatchEvent(new js.html.KeyboardEvent("keydown"));
					var plays:Int = js.Syntax.code("window.helixPlays");
					js.Syntax.code("HTMLMediaElement.prototype.play = window.helixRealPlay");
					check(plays == 1, 'play() asked $plays times in the gesture, not once');
					started = haxe.Timer.stamp();
				},
				wait: .3,
				check: () -> {
					check(audio.running, "audio not resumed");
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), elapsed(), .15, "position");
					audio.stop(voice);
				}
			},
			#end
			{
				name: "a queue fed half a second plays it",
				enter: () -> {
					queue = audio.createQueue(2, 22050);
					audio.queueSamples(queue, frames(11025, .5, .25));
					check(audio.getQueuedFrameCount(queue) == 11025, 'queued before playing: ${audio.getQueuedFrameCount(queue)}');
					voice = audio.playQueue(queue, 1);
					started = haxe.Timer.stamp();
				},
				wait: .25,
				check: () -> {
					near(audio.getQueuedFrameCount(queue), 11025 - elapsed() * 22050, 22050 * .1, "queued");
					near(audio.getPosition(voice), elapsed(), .1, "position");
					check(!audio.setPosition(voice, 0), "a queue's voice moved");
				}
			},
			{
				name: "a queue run dry keeps playing",
				wait: .5,
				check: () -> {
					check(audio.getQueuedFrameCount(queue) == 0, 'queued: ${audio.getQueuedFrameCount(queue)}');
					check(audio.isPlaying(voice), "not playing");
					near(audio.getPosition(voice), .5, .01, "position");
				}
			},
			{
				name: "a dry queue resumes when fed",
				enter: () -> {
					audio.queueSamples(queue, frames(5512, .5, .25));
					queued = audio.getQueuedFrameCount(queue);
					near(queued, 5512, 22050 * .02, "queued when fed");
				},
				wait: .15,
				check: () -> {
					check(audio.getQueuedFrameCount(queue) < queued - 22050 * .05, 'queued: ${audio.getQueuedFrameCount(queue)} of $queued');
					check(audio.getPosition(voice) > .55, 'position: ${audio.getPosition(voice)}');
				}
			},
			{
				name: "a queue's voice stopped drops what it held",
				enter: () -> audio.stop(voice),
				check: () -> {
					check(!audio.isPlaying(voice) && audio.getQueuedFrameCount(queue) == 0, "still holds samples");
					audio.disposeQueue(queue);
					audio.disposeStream(stream);
					var refused = 0;
					for (dispose in [
						() -> audio.disposeQueue(queue),
						() -> audio.disposeStream(stream),
						() -> audio.disposeClip(clip)
					])
						try
							dispose()
						catch (_:Dynamic)
							refused++;
					check(refused == 3, 'disposed twice: ${3 - refused} of 3 not refused');
				}
			}
		];
	}

	static function finish():Void {
		audio.dispose();
		decoder.dispose();
		var result = {passed: failures.length == 0, checks: checks, failures: failures};
		#if js
		js.Syntax.code("window.helixResult = {0}", result);
		#else
		Sys.println(haxe.Json.stringify(result));
		Sys.exit(result.passed ? 0 : 1);
		#end
	}
}
