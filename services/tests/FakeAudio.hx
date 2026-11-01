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
	playing:Bool,
	position:Float
}

/** Stands in for the platform's sound output and decoder in the services' tests: clips, streams, queues and voices kept for the test to
	read, streams opened and files decoded at the next `poll`, and voices the test ends and moves. A file decodes to itself, mono, unless
	it starts "stereo". */
class FakeAudio implements IAudio implements IAudioDecoder {
	/** Gets the voices, by id. */
	public final voices = new Map<Int, FakeVoice>();

	/** Gets the clips, streams and queues not disposed, by id. */
	public final sounds = new Map<Int, String>();

	/** Gets the sources streams were opened from, by stream. */
	public final sources = new Map<Int, StreamSource>();

	/** Gets the frames each queue holds, by queue: what was queued, less what the test has taken as heard. */
	public final queued = new Map<Int, Int>();

	/** Gets or sets what `getStreamDuration` answers for every stream. Defaults to 0, unknown. */
	public var streamDuration = 0.;

	/** Gets or sets what `getStreamChannelCount` answers for every stream. Defaults to 2. */
	public var streamChannels = 2;

	final queueChannels = new Map<Int, Int>();
	final queueVoices = new Map<Int, Int>();

	final waiting:Array<Void->Void> = [];
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
		waiting.push(() -> encoded.toString() == "bad" ? failed("not audio") : decoded(encoded, StringTools.startsWith(encoded.toString(), "stereo") ? 2 : 1));

	public function createClip(samples:Bytes, channelCount:Int):Int {
		if (channelCount != 1 && channelCount != 2)
			throw 'createClip takes 1 or 2 channels, not $channelCount';
		sounds.set(next, "clip");
		return next++;
	}

	public function disposeClip(clip:Int):Void
		sounds.remove(clip);

	public function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void {
		waiting.push(() -> {
			sources.set(next, source);
			sounds.set(next, "stream");
			opened(next++);
		});
		return () -> {};
	}

	public function disposeStream(stream:Int):Void
		sounds.remove(stream);

	/** Returns `streamDuration`. */
	public function getStreamDuration(stream:Int):Float
		return streamDuration;

	/** Returns `streamChannels`. */
	public function getStreamChannelCount(stream:Int):Int
		return streamChannels;

	public function createQueue(channelCount:Int, sampleRate:Int):Int {
		if (channelCount != 1 && channelCount != 2 || sampleRate < 8000 || sampleRate > 96000)
			throw 'createQueue: $channelCount channels at $sampleRate';
		sounds.set(next, "queue");
		queued.set(next, 0);
		queueChannels.set(next, channelCount);
		return next++;
	}

	/** Counts the frames added. */
	public function queueSamples(queue:Int, samples:Bytes):Void {
		if (!queued.exists(queue))
			throw 'unknown queue $queue';
		queued.set(queue, queued.get(queue) + Std.int(samples.length / (4 * queueChannels.get(queue))));
	}

	public function getQueuedFrameCount(queue:Int):Int {
		if (!queued.exists(queue))
			throw 'unknown queue $queue';
		return queued.get(queue);
	}

	public function disposeQueue(queue:Int):Void {
		if (queueVoices.exists(queue))
			stop(queueVoices.get(queue));
		sounds.remove(queue);
		queued.remove(queue);
	}

	/** Ends the queue's earlier voice, keeping its samples. */
	public function playQueue(queue:Int, volume:Float):Int {
		if (queueVoices.exists(queue) && voices.exists(queueVoices.get(queue)))
			voices.get(queueVoices.get(queue)).playing = false;
		var voice = start(queue, false, volume);
		queueVoices.set(queue, voice);
		return voice;
	}

	public function playClip(clip:Int, loop:Bool, volume:Float):Int
		return start(clip, loop, volume);

	public function playStream(stream:Int, loop:Bool, volume:Float):Int
		return start(stream, loop, volume);

	/** Stops a voice; a queue's drops what it held. */
	public function stop(voice:Int):Void {
		if (!voices.exists(voice))
			return;
		var v = voices.get(voice);
		if (v.playing && sounds.get(v.sound) == "queue")
			queued.set(v.sound, 0);
		v.playing = false;
	}

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

	/** Returns the voice's position, which the test or `setPosition` sets; 0 for an unknown or ended voice. */
	public function getPosition(voice:Int):Float
		return isPlaying(voice) ? voices.get(voice).position : 0;

	/** Moves a playing voice that isn't a queue's. */
	public function setPosition(voice:Int, seconds:Float):Bool {
		if (!isPlaying(voice) || sounds.get(voices.get(voice).sound) == "queue")
			return false;
		voices.get(voice).position = seconds;
		return true;
	}

	public function poll():Void {
		var due = waiting.splice(0, waiting.length);
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
			playing: true,
			position: 0
		});
		return next++;
	}
}
