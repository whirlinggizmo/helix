import haxe.io.Bytes;
import helix.raylib.AudioStream;
import helix.raylib.Wave;
import helix.raylib.Raylib.*;
import helix.raylib.internal.AudioStreams;
import helix.raylib.internal.Runtime;

/** Checks helix-raylib's audio streams, on services' `FakeAudio` as the output: a stream fed by `UpdateAudioStream` plays with nothing
	polled for it, its two buffers taken and a third refused until one is heard; the first `SetAudioStreamCallback` adds what tops a
	stream up to the poll, which fills a playing stream's two buffers as it starts and again each poll once they're heard, and nothing
	once its callback is taken away; FLAC music and a missing file refused by `LoadMusicStreamAsync`, FLAC by `LoadMusicStreamFromMemory`; `CloseAudioDevice` takes
	it out of the poll, and the next callback adds it again. And a sound's aliases: each holds a reference to the sound's samples, which are
	freed when the last, the sound's or an alias's, is released. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.AudioStream)
class AudioStreamTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function polled():Int {
		return [for (p in Runtime.polled) if (Std.isOfType(p, AudioStreams)) p].length;
	}

	// Opens music, pumping the polls and later answers until it answers: "opened", or "failed: " and why.
	static function opens(fileName:String):String {
		var answer:Null<String> = null;
		LoadMusicStreamAsync(fileName, music -> answer = "opened", error -> answer = 'failed: $error');
		for (_ in 0...100) {
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
			if (answer != null)
				return answer;
		}
		return "never answered";
	}

	// Opens the audio over the fake output, as InitAudioDevice does over the platform's.
	static function open(output:FakeAudio):Void {
		Runtime.system = new FakeSystem();
		Runtime.output = output;
		Runtime.audioDecoder = output;
		var assets = new helix.services.assets.Assets([]);
		Runtime.audio = new helix.services.audio.Audio(output, output, assets, Runtime.system);
		Runtime.polled.push(assets);
		Runtime.polled.push(output);
		Runtime.polled.push(Runtime.audio);
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var output = new FakeAudio();
		open(output);
		var fed = LoadAudioStream(44100, 16, 1);
		check(IsAudioStreamValid(fed) && fed.bufferFrames == 1470, "a stream opened, a buffer 1470 frames");
		PlayAudioStream(fed);
		var buffer = Bytes.alloc(1470 * 2);
		UpdateAudioStream(fed, buffer, 1470);
		check(IsAudioStreamProcessed(fed), "UpdateAudioStream: one buffer held, room for another");
		UpdateAudioStream(fed, buffer, 1470);
		check(!IsAudioStreamProcessed(fed) && fed.queue.queuedFrameCount == 2940, "two held, none free");
		UpdateAudioStream(fed, buffer, 1470);
		check(fed.queue.queuedFrameCount == 2940, "a third refused until one is heard");
		check(polled() == 0, "a stream fed by UpdateAudioStream polls nothing");

		var calls = 0;
		var called = LoadAudioStream(22050, 32, 2);
		SetAudioStreamCallback(called, (data, frames) -> calls++);
		check(polled() == 1, "the first SetAudioStreamCallback adds the topping up to the poll");
		PlayAudioStream(called);
		check(calls == 2 && called.queue.queuedFrameCount == 2940, 'playing, its callback fills two buffers: $calls');
		for (queue in output.queued.keys())
			output.queued.set(queue, 0);
		Runtime.pollAll();
		check(calls == 4 && called.queue.queuedFrameCount == 2940, 'heard, the poll fills them again: $calls');
		SetAudioStreamCallback(called, null);
		for (queue in output.queued.keys())
			output.queued.set(queue, 0);
		Runtime.pollAll();
		check(calls == 4, "its callback taken away, the poll calls nothing");

		// FLAC music isn't opened, as raylib 5.5's default build leaves FLAC out.
		check(opens("theme.flac") == "failed: theme.flac: STREAM: File format not supported" && opens("THEME.Flac") != "opened",
			"LoadMusicStreamAsync refuses FLAC");
		var missing = opens("missing.ogg");
		check(StringTools.startsWith(missing, "failed: "), 'LoadMusicStreamAsync refuses a file that isn\x27t there: $missing');
		var bytes = Bytes.ofString("fLaC");
		check(!IsMusicValid(LoadMusicStreamFromMemory(".flac", bytes, 4)) && !IsMusicValid(LoadMusicStreamFromMemory(".FLAC", bytes, 4)),
			"LoadMusicStreamFromMemory refuses FLAC");

		CloseAudioDevice();
		check(polled() == 0, "CloseAudioDevice takes it out of the poll");
		open(output);
		var again = LoadAudioStream(44100, 16, 1);
		SetAudioStreamCallback(again, (data, frames) -> calls++);
		check(polled() == 1, "the next callback adds it again");

		// A sound's aliases hold a reference to its samples: freed when the last held reference, the sound's or an alias's, is released.
		var held = () -> Lambda.count(output.sounds);
		var none = held();
		var owner = LoadSoundFromWave(new Wave(4410, 44100, 16, 1, Bytes.alloc(8820)));
		var alias = LoadSoundAlias(owner), second = LoadSoundAlias(owner);
		check(held() == none + 1 && IsSoundValid(alias) && IsSoundValid(second), "a sound and its aliases share one set of samples");
		UnloadSound(owner);
		check(held() == none + 1, "the sound unloaded: its samples kept while its aliases hold them");
		PlaySound(alias);
		check(IsSoundPlaying(alias), "an alias plays on after its sound is unloaded");
		UnloadSoundAlias(alias);
		check(held() == none + 1, "one alias unloaded: the other still holds them");
		UnloadSoundAlias(second);
		check(held() == none, "the last alias unloaded: the samples freed");
		var first = LoadSoundFromWave(new Wave(4410, 44100, 16, 1, Bytes.alloc(8820)));
		var late = LoadSoundAlias(first);
		UnloadSoundAlias(late);
		check(held() == none + 1, "an alias unloaded first: the sound keeps its samples");
		UnloadSound(first);
		check(held() == none, "then the sound unloaded: freed");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
