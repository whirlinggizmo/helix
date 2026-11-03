package helix.services.audio;

import haxe.io.Bytes;
import helix.formats.audio.AudioHeader;
import helix.platform.GrowingSource;
import helix.platform.IAudio;

/** Represents a sound ready to play: decoded whole (`Audio.load`), made from samples (`Audio.createSound`), or opened to be read as it
	plays (`Audio.stream`). */
@:allow(helix.services.audio)
class Sound {
	/** The bytes from a file's start that its length is read from. */
	static inline final START = 65536;

	// The output's clip or stream, and what lets go of a located stream's file; unloaded once let go.
	var id:Int;
	var release:Null<Void->Void>;
	var unloaded = false;
	// What plays it (loop, volume; the output's voice), disposes of it and, for a stream, asks the platform its length: the clip's or
	// the stream's calls, so a program that never streams links none of the output's streaming.
	final playing:(loop:Bool, volume:Float) -> Int;
	final disposing:Void->Void;
	final measuring:Null<Void->Float>;
	// A clip's length; a stream's once known, from a download's tail or the platform.
	var seconds = 0.;
	// Natively, a stream downloading in two parts: what reads its length from its start and its last bytes once its start has arrived,
	// -1 until then (`measureFrom`); null for any other sound, so only a program streaming from a server links the headers' reading.
	var measure:Null<Void->Float> = null;

	@:allow(helix.services.audio)
	function new(path:String, id:Int, channelCount:Int, seconds:Float, release:Null<Void->Void>, playing:(loop:Bool, volume:Float) -> Int,
			disposing:Void->Void, measuring:Null<Void->Float>) {
		this.path = path;
		this.streamed = measuring != null;
		this.playing = playing;
		this.disposing = disposing;
		this.measuring = measuring;
		this.id = id;
		this.channelCount = channelCount;
		this.seconds = seconds;
		this.release = release;
	}

	/** Gets the path it was loaded from, or "" for a sound made from samples (`Audio.createSound`). */
	public var path(default, null):String;

	/** Gets a value indicating whether the sound is read as it plays (`Audio.stream`) rather than held whole. */
	public var streamed(default, null):Bool;

	/** Gets the number of channels it plays, 1 (mono) or 2 (stereo); 0 for a streamed sound whose channels the platform can't tell
		(`IAudio.getStreamChannelCount`). */
	public var channelCount(default, null):Int;

	/** Gets the sound's length in seconds, or 0 while it isn't known.

		A sound held whole knows its length at once. A streamed sound's is the platform's (`IAudio.getStreamDuration`), which may come
		later. A streamed sound downloading from a server knows its length once the file's start and its last 64 KiB have arrived, which
		`Assets` fetches first. */
	public var duration(get, never):Float;

	function get_duration():Float {
		if (seconds > 0 || unloaded || measuring == null)
			return seconds;
		if (measure != null) {
			var read = measure();
			if (read >= 0) {
				measure = null;
				seconds = read;
				if (seconds > 0)
					return seconds;
			}
		}
		var known = measuring();
		if (known > 0)
			seconds = known;
		return known;
	}

	// Has the length read from a download's start and its last bytes, once its start has arrived (`Audio.stream`, natively).
	function measureFrom(growing:GrowingSource, tail:Bytes):Void {
		measure = () -> {
			if (growing.received < Std.int(Math.min(START, growing.total - tail.length)))
				return -1;
			var start = growing.bytes.sub(0, Std.int(Math.min(START, growing.received)));
			return AudioHeader.readDuration(start, tail, growing.total);
		};
	}
}
