package helix.audio;

/** One playback, playing or paused; holds its resource until stopped or played to its end. While audio hasn't started (a browser before the
	page's first key or pointer press) it waits, its pause and volume kept, and starts once audio runs. */
class AudioPlayback {
	var waiting = true;
	var paused = false;
	var stopped = false;
	var resource:AudioResource;
	var loop:Bool;

	/** The adapter's voice; 0 while it waits for audio to start, or when it couldn't start. */
	public var id(default, null):Int = 0;

	/** Whether it was stopped, played to its end, or never started; its resource reference is released then. */
	public var finished(default, null):Bool = false;

	/** The adapter's resource it plays, kept as it started: a reload may replace the resource's. */
	public var source(default, null):Int;

	/** A playback of resource (whose playback reference the caller retained) at volume, looping if asked: it starts now if audio runs, waits if
		audio is available but hasn't started, and finishes at once otherwise. AudioResources.play makes it. */
	public function new(resource:AudioResource, loop:Bool, volume:Float) {
		this.resource = resource;
		this.loop = loop;
		this.volume = volume;
		source = resource.id;
		var backend = resource.backend;
		if (!backend.available) {
			waiting = false;
			stopped = true;
			end();
		} else if (backend.running)
			begin();
	}

	// Starts its voice: one that can't start (no free voice) finishes it.
	function begin():Void {
		waiting = false;
		id = resource.startVoice(loop, volume);
		if (id == 0) {
			stopped = true;
			end();
		} else if (paused)
			resource.backend.pause(id, true);
	}

	function end():Void {
		if (!finished) {
			finished = true;
			resource.releasePlayback();
		}
	}

	/** Playing or Paused while it lasts (waiting counts as playing); then Stopped (stop(), or it never started) or Complete (it played to its
		end). */
	public var state(get, never):PlayState;

	function get_state():PlayState
		return finished ? (stopped ? Stopped : Complete) : paused ? Paused : Playing;

	/** Stops it and releases its resource reference. False once it has finished. */
	public function stop():Bool {
		if (finished)
			return false;
		if (id != 0)
			resource.backend.stop(id);
		stopped = true;
		end();
		return true;
	}

	/** Pauses it where it is. False unless it's playing. */
	public function pause():Bool {
		if (finished || paused)
			return false;
		if (id != 0)
			resource.backend.pause(id, true);
		paused = true;
		return true;
	}

	/** Plays on from where it was paused. False unless it's paused. */
	public function resume():Bool {
		if (finished || !paused)
			return false;
		if (id != 0)
			resource.backend.pause(id, false);
		paused = false;
		return true;
	}

	/** Its volume, 0 to 1. Clamped to 0..1 (NaN is 0); once it has finished, kept but not heard. */
	public var volume(default, set):Float;

	function set_volume(volume:Float):Float {
		volume = volume > 0 ? (volume < 1 ? volume : 1) : 0;
		this.volume = volume;
		if (id != 0)
			resource.backend.setVolume(id, volume);
		return volume;
	}

	/** Starts it once audio runs, and finishes it, releasing its resource reference, once the adapter no longer plays it. AudioResources.poll
		calls it. */
	public function poll():Void {
		if (finished)
			return;
		if (waiting) {
			if (resource.backend.running)
				begin();
			return;
		}
		if (!resource.backend.isPlaying(id))
			end();
	}
}
