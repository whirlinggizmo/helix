import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.audio.Audio;
import helix.services.audio.Sound;

/** Checks Audio over fakes: sounds loaded whole and streamed through Assets, voices played in groups at their volumes times their
	groups', muted, faded on real time along a decibel curve, paused, pitched and panned, ended voices let go, and sounds unloaded. */
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
		var output = new FakeAudio();
		var system = new FakeSystem();
		var assets = new Assets({sources: [FileSystem(files)]});
		var audio = new Audio(output, output, assets, system);
		function pump()
			for (_ in 0...5) {
				files.poll();
				output.poll();
				audio.poll();
			}

		var jump:Sound = null, music:Sound = null, why = [];
		audio.load("jump.wav", sound -> jump = sound);
		audio.stream("music.ogg", sound -> music = sound);
		audio.load("bad.wav", _ -> {}, message -> why.push(message));
		audio.load("none.wav", _ -> {}, message -> why.push(message));
		pump();
		check(jump != null && !jump.streamed && jump.path == "jump.wav", "loaded whole");
		check(music != null && music.streamed && files.held == 1, "streamed, its file located and held");
		check(why.length == 2 && why.join("|").indexOf("bad.wav") >= 0 && why.join("|").indexOf("none.wav") >= 0,
			"a file that won't decode, and one not found, fail");

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

		voice.pitch = 9;
		voice.pan = -3;
		voice.paused = true;
		var v = output.voices.get(lastVoice(output));
		check(voice.pitch == 4 && v.pitch == 4 && voice.pan == -1 && v.pan == -1 && v.paused, "pitch, pan held to their ranges; paused");

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

		audio.dispose();
		check([for (k in output.sounds.keys()) k].length == 0, "dispose lets go of every sound");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function lastVoice(output:FakeAudio):Int {
		var most = 0;
		for (id in output.voices.keys())
			if (id > most)
				most = id;
		return most;
	}
}
