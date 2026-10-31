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
	final output:IAudio;
	// A clip's length; a stream's once known, from a download's tail or the platform.
	var seconds = 0.;
	// A stream downloading in two parts, and its last bytes, from which its length is read once its start has arrived too.
	var growing:Null<GrowingSource> = null;
	var tail:Null<Bytes> = null;

	@:allow(helix.services.audio)
	function new(output:IAudio, path:String, streamed:Bool, id:Int, channels:Int, seconds:Float, release:Null<Void->Void>) {
		this.output = output;
		this.path = path;
		this.streamed = streamed;
		this.id = id;
		this.channels = channels;
		this.seconds = seconds;
		this.release = release;
	}

	/** Gets the path it was loaded from, or "" for a sound made from samples (`Audio.createSound`). */
	public var path(default, null):String;

	/** Gets a value indicating whether the sound is read as it plays (`Audio.stream`) rather than held whole. */
	public var streamed(default, null):Bool;

	/** Gets the channels it plays, 1 (mono) or 2 (stereo); 0 for a streamed sound whose channels the platform can't tell
		(`IAudio.getStreamChannels`). */
	public var channels(default, null):Int;

	/** Gets the sound's length in seconds, or 0 while it isn't known.

		A sound held whole knows its length at once. A streamed sound's is the platform's (`IAudio.getStreamDuration`), which may come
		later. A streamed sound downloading from a server knows its length once the file's start and its last 64 KiB have arrived, which
		`Assets` fetches first. */
	public var duration(get, never):Float;

	function get_duration():Float {
		if (seconds > 0 || unloaded || !streamed)
			return seconds;
		if (tail != null && growing != null && growing.received >= Std.int(Math.min(START, growing.total - tail.length))) {
			var start = growing.bytes.sub(0, Std.int(Math.min(START, growing.received)));
			seconds = AudioHeader.readDuration(start, tail, growing.total);
			tail = null;
			if (seconds > 0)
				return seconds;
		}
		var known = output.getStreamDuration(id);
		if (known > 0)
			seconds = known;
		return known;
	}
}
