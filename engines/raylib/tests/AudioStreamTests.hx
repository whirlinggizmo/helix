import haxe.io.Bytes;
import helix.raylib.AudioStream;
import helix.raylib.Raylib.*;
import helix.raylib.internal.AudioStreams;
import helix.raylib.internal.Runtime;

/** Checks helix-raylib's audio streams, on services' `FakeAudio` as the output: a stream fed by `UpdateAudioStream` plays with nothing
	polled for it, its two buffers taken and a third refused until one is heard; the first `SetAudioStreamCallback` adds what tops a
	stream up to the poll, which fills a playing stream's two buffers as it starts and again each poll once they're heard, and nothing
	once its callback is taken away; FLAC music refused by `LoadMusicStream` and `LoadMusicStreamFromMemory`; `CloseAudioDevice` takes
	it out of the poll, and the next callback adds it again. */
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

	// Opens the audio over the fake output, as InitAudioDevice does over the platform's.
	static function open(output:FakeAudio):Void {
		Runtime.system = new FakeSystem();
		Runtime.output = output;
		Runtime.audioDecoder = output;
		Runtime.audio = new helix.services.audio.Audio(output, output, new helix.services.assets.Assets([]), Runtime.system);
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
		check(!IsMusicValid(LoadMusicStream("theme.flac"))
			&& !IsMusicValid(LoadMusicStream("THEME.Flac")), "LoadMusicStream refuses FLAC");
		var bytes = Bytes.ofString("fLaC");
		check(!IsMusicValid(LoadMusicStreamFromMemory(".flac", bytes, 4)) && !IsMusicValid(LoadMusicStreamFromMemory(".FLAC", bytes, 4)),
			"LoadMusicStreamFromMemory refuses FLAC");

		CloseAudioDevice();
		check(polled() == 0, "CloseAudioDevice takes it out of the poll");
		open(output);
		var again = LoadAudioStream(44100, 16, 1);
		SetAudioStreamCallback(again, (data, frames) -> calls++);
		check(polled() == 1, "the next callback adds it again");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
