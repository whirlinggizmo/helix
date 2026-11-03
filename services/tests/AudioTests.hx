import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.audio.Audio;
import helix.services.audio.Sound;

/** Checks Audio over fakes: sounds loaded whole and streamed through Assets, voices played in groups at their volumes times their
	groups', muted, faded on real time along a decibel curve, paused, pitched and panned, ended voices let go, and sounds unloaded; sounds'
	lengths and channels, voices' positions, sounds made from samples, queues played in groups; and natively a server's stream knowing its
	length from its last bytes, fetched first. */
@:access(helix.services.audio)
class AudioTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	static function main():Void {
		var files = new FakeFileSystem();
		files.files.set("jump.wav", Bytes.ofString("jump"));
		files.files.set("music.ogg", Bytes.ofString("music"));
		files.files.set("bad.wav", Bytes.ofString("bad"));
		files.files.set("both.wav", Bytes.ofString("stereo!!"));
		var output = new FakeAudio();
		var system = new FakeSystem();
		var assets = new Assets([new FileSystemSource(files)]);
		var audio = new Audio(output, output, assets, system);
		function pump()
			for (_ in 0...5) {
				files.poll();
				output.poll();
				audio.poll();
			}

		var jump:Sound = null, music:Sound = null, both:Sound = null, why = [];
		audio.load("jump.wav", sound -> jump = sound);
		audio.load("both.wav", sound -> both = sound);
		audio.stream("music.ogg", sound -> music = sound);
		audio.load("bad.wav", _ -> {}, message -> why.push(message));
		audio.load("none.wav", _ -> {}, message -> why.push(message));
		pump();
		check(jump != null && !jump.streamed && jump.path == "jump.wav", "loaded whole");
		check(music != null && music.streamed && files.held == 1, "streamed, its file located and held");
		check(why.length == 2 && why.join("|").indexOf("bad.wav") >= 0 && why.join("|").indexOf("none.wav") >= 0,
			"a file that won't decode, and one not found, fail");

		check(jump.channelCount == 1 && near(jump.duration, 1 / 44100), "a sound loaded whole: its channels, and its frames over 44100 its length");
		check(both.channelCount == 2 && near(both.duration, 1 / 44100), "a stereo file: 2 channels, its frames counted in pairs");
		check(music.channelCount == 2 && music.duration == 0, "a stream: the platform's channels, its length 0 while the platform doesn't know it");
		output.streamDuration = 12.5;
		check(music.duration == 12.5, "and the platform's once it does");
		output.streamDuration = 0;
		check(music.duration == 12.5, "kept once known");

		var made = audio.createSound(Bytes.alloc(44100 * 8), 2);
		check(made.path == "" && !made.streamed && made.channelCount == 2 && near(made.duration, 1) && output.sounds.get(made.id) == "clip",
			"a sound made from samples: a clip, a second of stereo");
		check(try {
			audio.createSound(Bytes.alloc(8), 3);
			false;
		} catch (_:String) true, "a sound of 3 channels: refused");

		var effects = audio.createGroup();
		effects.volume = .5;
		var voice = audio.play(jump, effects, false, .8);
		check(voice.playing && near(output.voices.get(lastVoice(output)).volume, .4), "a voice heard at its volume times its group's");
		audio.master.volume = .5;
		audio.poll();
		check(near(output.voices.get(lastVoice(output)).volume, .2), "and the master's, applied at the poll");
		audio.master.muted = true;
		audio.poll();
		check(output.voices.get(lastVoice(output)).volume == 0 && voice.volume == .8, "muted: silent, its volume kept");
		audio.master.muted = false;
		audio.master.volume = 1;

		output.voices.get(lastVoice(output)).position = 0.25;
		check(voice.position == .25, "a voice's position, the platform's");
		check(voice.setPosition(.5) && output.voices.get(lastVoice(output)).position == .5, "moved");

		voice.pitch = 9;
		voice.pan = -3;
		voice.paused = true;
		var v = output.voices.get(lastVoice(output));
		check(voice.pitch == 4 && v.pitch == 4 && voice.pan == -1 && v.pan == -1 && v.paused, "pitch, pan held to their ranges; paused");
		voice.pitch = 2;
		voice.pitch = 2;
		check(voice.pitch == 2 && v.pitch == 2, "a pitch set twice is the pitch set, not one relative to the last");
		voice.pitch = 1;
		check(voice.pitch == 1 && v.pitch == 1, "and set back to 1, as recorded");
		var again = audio.play(jump);
		check(again.position == 0
			&& output.voices.get(lastVoice(output)).position == 0, "a sound played again: a new voice, from its start");
		again.stop();

		system.now = 10;
		var song = audio.play(music, null, true, 0);
		var songId = lastVoice(output);
		var faded = false;
		song.fadeTo(1, 2, () -> faded = true);
		system.now = 11;
		audio.poll();
		var halfway = output.voices.get(songId).volume;
		check(halfway > 0 && halfway < .1, "a fade from silence: quiet halfway, as the ear hears it");
		system.now = 12;
		audio.poll();
		check(near(song.volume, 1) && faded, "the fade reaches its volume, then done");
		effects.fadeTo(0, 1);
		system.now = 13;
		audio.poll();
		check(effects.volume == 0, "a group's fade reaches 0 exactly");
		song.volume = .3;
		check(near(output.voices.get(songId).volume, .3), "a voice's volume set at once");

		output.voices.get(songId).playing = false;
		audio.poll();
		check(!song.playing, "a voice that ended: not playing");
		check(song.position == 0 && !song.setPosition(1), "an ended voice: at 0, not moved");
		song.volume = .9;
		check(output.voices.get(songId).volume != .9, "an ended voice changes nothing");

		var streams = [for (k => kind in output.sounds) if (kind == "stream") k].length;
		audio.unload(music);
		check(files.held == 0 && [for (k => kind in output.sounds) if (kind == "stream") k].length == streams - 1,
			"unloaded: the stream disposed and its file let go");
		check(try {
			audio.play(music);
			false;
		} catch (_:String) true, "playing an unloaded sound throws");
		check(try {
			audio.play(null);
			false;
		} catch (_:String) true, "playing null throws");

		var queue = audio.createSampleQueue(2, 22050);
		check(output.sounds.get(queue.id) == "queue" && queue.queuedFrameCount == 0, "a queue, holding nothing");
		queue.queueSamples(Bytes.alloc(800));
		check(queue.queuedFrameCount == 100, "samples queued: 100 stereo frames");
		var tones = audio.createGroup();
		tones.volume = .5;
		var tone = queue.play(tones, .5);
		var toneId = lastVoice(output);
		check(tone.playing
			&& tone.sound == null
			&& near(output.voices.get(toneId).volume, .25), "played in a group, heard at its volume times the group's");
		tones.muted = true;
		audio.poll();
		check(output.voices.get(toneId).volume == 0, "its group muted: silent");
		tones.muted = false;
		tones.fadeTo(0, 1);
		system.now += 2;
		audio.poll();
		check(output.voices.get(toneId).volume == 0, "its group faded out");
		tones.volume = 1;
		check(!tone.setPosition(1), "a queue's voice can't be moved");
		var again = queue.play();
		check(!tone.playing && again.playing && queue.queuedFrameCount == 100, "played again: the earlier voice ended, the samples kept");
		again.stop();
		check(queue.queuedFrameCount == 0, "its voice stopped: what it held dropped");
		queue.dispose();
		check(!output.sounds.exists(queue.id) && queue.queuedFrameCount == 0, "disposed: the platform's queue let go");
		check(try {
			queue.queueSamples(Bytes.alloc(8));
			false;
		} catch (_:String) true, "a disposed queue takes no samples");
		check(try {
			queue.play();
			false;
		} catch (_:String) true, "nor plays");
		audio.createSampleQueue(1, 8000);

		audio.dispose();
		check([for (k in output.sounds.keys()) k].length == 0, "dispose lets go of every sound and queue");
		#if !js
		served();
		#end
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	#if !js
	// A server's stream natively: its last 64 KiB fetched first, so its length is known once its start has arrived too; a server that
	// ignores the range sends it whole, its length the platform's.
	static function served():Void {
		var http = new FakeHttp(),
			cache = new FakeFileSystem(),
			output = new FakeAudio(),
			system = new FakeSystem();
		var base = "https://example.com/";
		var rate = 44100, frames = 2 * rate;
		var wav = helix.formats.wav.WavFile.write(rate, 1, 16, frames, Bytes.alloc(frames * 2));
		http.routes.set(base + "song.wav", {status: 200, headers: ["etag" => '"s1"'], body: wav});
		http.routes.set(base + "plain.wav", {status: 200, body: wav, ignoresRange: true});
		var assets = new Assets([new ServerSource(base, http, new RevalidateCache(cache))]);
		var audio = new Audio(output, output, assets, system);
		function pump()
			for (_ in 0...10) {
				http.poll();
				cache.poll();
				output.poll();
				audio.poll();
			}
		var song:Sound = null;
		audio.stream("song.wav", sound -> song = sound);
		cache.poll();
		http.poll();
		check(http.requests.length == 2 && http.requests[0].headers.get("Range") == "bytes=-65536", "its last 64 KiB asked for first");
		output.poll();
		check(song != null && song.duration == 0, "opened as its start downloads, its length not yet known");
		http.poll();
		check(near(song.duration, 2), "its start arrived: its length read from it and its end");
		check(http.requests[1].headers.get("Range") == 'bytes=0-${wav.length - 65537}'
			&& http.requests[1].headers.get("If-Range") == '"s1"',
			"the rest asked for, while it's the same file");
		check(http.bytesSent == wav.length, "no byte downloaded twice");
		pump();
		check([
			for (path => bytes in cache.files)
				if (StringTools.endsWith(path, "/files/song.wav")) bytes.compare(wav)
		].join(",") == "0", "kept whole");

		var plain:Sound = null;
		var before = http.requests.length;
		audio.stream("plain.wav", sound -> plain = sound);
		pump();
		check(http.requests.length == before + 1 && plain.duration == 0, "a server ignoring the range: downloaded once, its length the platform's");
		output.streamDuration = 2;
		check(plain.duration == 2, "which it knows once the file has arrived");
		audio.dispose();
	}
	#end

	static function lastVoice(output:FakeAudio):Int {
		var most = 0;
		for (id in output.voices.keys())
			if (id > most)
				most = id;
		return most;
	}
}
