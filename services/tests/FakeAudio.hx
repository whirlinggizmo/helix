import haxe.io.Bytes;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.StreamSource;

/** A voice as FakeAudio keeps it. */
typedef FakeVoice = {
	sound:Int,
	loop:Bool,
	volume:Float,
	pitch:Float,
	pan:Float,
	paused:Bool,
	playing:Bool
}

/** Stands in for the platform's sound output and decoder in the services' tests: clips, streams and voices kept for the test to read,
	streams opened and files decoded at the next `poll`, and voices the test ends. */
class FakeAudio implements IAudio implements IAudioDecoder {
	/** Gets the voices, by id. */
	public final voices = new Map<Int, FakeVoice>();

	/** Gets the clips and streams not disposed, by id. */
	public final sounds = new Map<Int, String>();

	final queued:Array<Void->Void> = [];
	var next = 1;

	/** Creates one with nothing in it. */
	public function new() {}

	/** Gets true. */
	public var available(get, never):Bool;

	function get_available():Bool
		return true;

	/** Gets true. */
	public var running(get, never):Bool;

	function get_running():Bool
		return true;

	/** Gets false. */
	public var playsUrls(get, never):Bool;

	function get_playsUrls():Bool
		return false;

	public function decode(encoded:Bytes, decoded:(samples:Bytes, channels:Int) -> Void, failed:String->Void):Void
		queued.push(() -> encoded.toString() == "bad" ? failed("not audio") : decoded(encoded, 1));

	public function createClip(samples:Bytes, channels:Int):Int {
		sounds.set(next, "clip");
		return next++;
	}

	public function disposeClip(clip:Int):Void
		sounds.remove(clip);

	public function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void {
		queued.push(() -> {
			sounds.set(next, "stream");
			opened(next++);
		});
		return () -> {};
	}

	public function disposeStream(stream:Int):Void
		sounds.remove(stream);

	/** Returns 0: a stream's length is unknown. */
	public function getStreamDuration(stream:Int):Float
		return 0;

	public function createQueue(channels:Int, sampleRate:Int):Int {
		sounds.set(next, "queue");
		return next++;
	}

	/** Does nothing: no samples are kept. */
	public function queueSamples(queue:Int, samples:Bytes):Void {}

	/** Returns 0: no samples are kept. */
	public function getQueuedFrames(queue:Int):Int
		return 0;

	public function disposeQueue(queue:Int):Void
		sounds.remove(queue);

	public function playQueue(queue:Int, volume:Float):Int
		return start(queue, false, volume);

	public function playClip(clip:Int, loop:Bool, volume:Float):Int
		return start(clip, loop, volume);

	public function playStream(stream:Int, loop:Bool, volume:Float):Int
		return start(stream, loop, volume);

	public function stop(voice:Int):Void
		if (voices.exists(voice))
			voices.get(voice).playing = false;

	public function pause(voice:Int, paused:Bool):Void
		if (voices.exists(voice))
			voices.get(voice).paused = paused;

	public function setVolume(voice:Int, volume:Float):Bool {
		var v = voices.get(voice);
		if (v == null || !v.playing || volume < 0 || volume > 1)
			return false;
		v.volume = volume;
		return true;
	}

	public function setPitch(voice:Int, pitch:Float):Bool {
		var v = voices.get(voice);
		if (v == null || !v.playing)
			return false;
		v.pitch = pitch;
		return true;
	}

	public function setPan(voice:Int, pan:Float):Bool {
		var v = voices.get(voice);
		if (v == null || !v.playing)
			return false;
		v.pan = pan;
		return true;
	}

	public function isPlaying(voice:Int):Bool
		return voices.exists(voice) && voices.get(voice).playing;

	/** Returns 0: voices don't advance. */
	public function getPosition(voice:Int):Float
		return 0;

	/** Returns whether the voice is playing; it doesn't move. */
	public function setPosition(voice:Int, seconds:Float):Bool
		return isPlaying(voice);

	public function poll():Void {
		var due = queued.splice(0, queued.length);
		for (f in due)
			f();
	}

	public function dispose():Void {}

	function start(sound:Int, loop:Bool, volume:Float):Int {
		voices.set(next, {
			sound: sound,
			loop: loop,
			volume: volume,
			pitch: 1,
			pan: 0,
			paused: false,
			playing: true
		});
		return next++;
	}
}
