import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Audio.*;
import helix.raylib.internal.Runtime;

// helix-raylib's waves, printed as ref.c prints raylib 5.5's, for tools/raylib_parity.py: each file read through LoadWaveFromMemoryAsync
// with its type a constant (its reader chosen as the program builds), the last through a type known only as it runs. The files are
// compiled in (the manifest's resources), so the page needs no server. Natively the platform's decoder answers on its worker, in a
// page through the browser's promises, so each wave is waited for across turns of the event loop.
@:access(helix.raylib.internal.Runtime)
class WaveBits {
	static final out = new StringBuf();

	static function print(name:String, w:Null<Wave>):Void {
		if (w == null) {
			out.add('$name wave 0 0 0 0\n');
			return;
		}
		out.add('$name wave ${w.frameCount} ${w.sampleRate} ${w.sampleSize} ${w.channels}\n');
		var count = w.frameCount * w.channels;
		for (i in 0...count) {
			var v = w.sampleSize == 32 ? w.data.getFloat(i * 4) : ((w.data.getUInt16(i * 2) << 16) >> 16) / 32768;
			if (i % 32 == 0)
				out.add('$name s');
			out.add(' $v');
			if (i % 32 == 31 || i == count - 1)
				out.add("\n");
		}
	}

	// Pumps helix-raylib's polls and later answers until the wave answers, then prints it and goes on.
	static function wait(name:String, start:(Wave->Void, String->Void)->Void, next:Void->Void):Void {
		var answered = false, wave:Null<Wave> = null;
		start(w -> {
			answered = true;
			wave = w;
		}, _ -> answered = true);
		function step():Void {
			for (_ in 0...10000) {
				Runtime.pollAll();
				var now = Runtime.waiting;
				Runtime.waiting = [];
				for (f in now)
					f();
				if (answered) {
					print(name, wave);
					next();
					return;
				}
				#if js
				haxe.Timer.delay(step, 1);
				return;
				#else
				WaitTime(0.001);
				#end
			}
			throw '$name never answered';
		}
		step();
	}

	static function file(name:String):Bytes
		return haxe.Resource.getBytes(name);

	static function main() {
		SetTraceLogLevel(LOG_NONE);
		#if js
		js.Syntax.code("window.helixResult = null");
		#end
		var type = [".qoa"][0];
		var steps:Array<Void->Void> = [];
		function run(i:Int):Void
			if (i < steps.length)
				steps[i]()
			else {
				music();
				save();
			}
		function add(name:String, start:(Wave->Void, String->Void)->Void):Void {
			var i = steps.length;
			steps.push(() -> wait(name, start, () -> run(i + 1)));
		}
		add("wav22_u8", (l, f) -> LoadWaveFromMemoryAsync(".wav", file("tone22_u8.wav"), file("tone22_u8.wav").length, l, f));
		add("wav22_s24", (l, f) -> LoadWaveFromMemoryAsync(".wav", file("tone22_s24.wav"), file("tone22_s24.wav").length, l, f));
		add("ogg48_mono", (l, f) -> LoadWaveFromMemoryAsync(".ogg", file("tone48_mono.ogg"), file("tone48_mono.ogg").length, l, f));
		add("ogg44_stereo", (l, f) -> LoadWaveFromMemoryAsync(".ogg", file("tone44_stereo.ogg"), file("tone44_stereo.ogg").length, l, f));
		add("mp3_lame", (l, f) -> LoadWaveFromMemoryAsync(".mp3", file("tone32_lame.mp3"), file("tone32_lame.mp3").length, l, f));
		add("mp3_plain", (l, f) -> LoadWaveFromMemoryAsync(".mp3", file("tone32_plain.mp3"), file("tone32_plain.mp3").length, l, f));
		add("qoa44_stereo", (l, f) -> LoadWaveFromMemoryAsync(".qoa", file("tone44_stereo.qoa"), file("tone44_stereo.qoa").length, l, f));
		add("flac48", (l, f) -> LoadWaveFromMemoryAsync(".flac", file("tone48.flac"), file("tone48.flac").length, l, f));
		add("ogg_mixed_case", (l, f) -> LoadWaveFromMemoryAsync(".Ogg", file("tone48_mono.ogg"), file("tone48_mono.ogg").length, l, f));
		add("qoa_run_time", (l, f) -> LoadWaveFromMemoryAsync(type, file("tone44_stereo.qoa"), file("tone44_stereo.qoa").length, l, f));
		run(0);
	}

	// FLAC music, refused by its file (answered at the next turn) and its bytes before any device is asked for, as raylib refuses it.
	static function music():Void {
		var valid = -1;
		LoadMusicStreamAsync("tone48.flac", music -> valid = IsMusicValid(music) ? 1 : 0, _ -> valid = 0);
		var now = Runtime.waiting;
		Runtime.waiting = [];
		for (f in now)
			f();
		out.add('music_flac valid $valid\n');
		out.add('music_flac_memory valid ${IsMusicValid(LoadMusicStreamFromMemory(".flac", file("tone48.flac"), file("tone48.flac").length)) ? 1 : 0}\n');
	}

	// The lines: in a page, left for tools/page_check.cjs as the page's result; natively, written to the file the command line names.
	static function save():Void {
		#if js
		js.Syntax.code("window.helixResult = {0}", out.toString());
		#else
		sys.io.File.saveContent(Sys.args()[0], out.toString());
		#end
	}
}
