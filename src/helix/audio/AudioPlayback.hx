package helix.audio;

/** One playback, playing or paused; holds its resource until stopped or played to its end. While audio hasn't started (a browser before the
	page's first key or pointer press) it waits, its pause and volume kept, and starts once audio runs. */
class AudioPlayback {
	var id = 0;
	var waiting = true;
	var finished = false;
	var paused = false;
	var stopped = false;
	var resource:AudioResource;
	var source:Int;
	var loop:Bool;
	var volume:Float;

	/** The adapter's voice; 0 while it waits for audio to start, or when it couldn't start. */
	public function getId():Int
		return id;

	/** Whether it was stopped, played to its end, or never started; its resource reference is released then. */
	public function isFinished():Bool
		return finished;

	/** The adapter's resource it plays, kept as it started: a reload may replace the resource's. */
	public function getSource():Int
		return source;

	/** A playback of resource (whose playback reference the caller retained) at volume, looping if asked: it starts now if audio runs, waits if
		audio is available but hasn't started, and finishes at once otherwise. AudioResources.play makes it. */
	public function new(resource:AudioResource, loop:Bool, volume:Float) {
		this.resource = resource;
		this.loop = loop;
		this.volume = volume;
		source = resource.getId();
		var backend = resource.getBackend();
		if (!backend.isAvailable()) {
			waiting = false;
			stopped = true;
			end();
		} else if (backend.isRunning())
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
			resource.getBackend().pause(id, true);
	}

	function end():Void {
		if (!finished) {
			finished = true;
			resource.releasePlayback();
		}
	}

	/** Playing or Paused while it lasts (waiting counts as playing); then Stopped (stop(), or it never started) or Complete (it played to its
		end). */
	public function getState():PlayState
		return finished ? (stopped ? Stopped : Complete) : paused ? Paused : Playing;

	/** Stops it and releases its resource reference. False once it has finished. */
	public function stop():Bool {
		if (finished)
			return false;
		if (id != 0)
			resource.getBackend().stop(id);
		stopped = true;
		end();
		return true;
	}

	/** Pauses it where it is. False unless it's playing. */
	public function pause():Bool {
		if (finished || paused)
			return false;
		if (id != 0)
			resource.getBackend().pause(id, true);
		paused = true;
		return true;
	}

	/** Plays on from where it was paused. False unless it's paused. */
	public function resume():Bool {
		if (finished || !paused)
			return false;
		if (id != 0)
			resource.getBackend().pause(id, false);
		paused = false;
		return true;
	}

	/** Its volume, 0 to 1. */
	public function getVolume():Float
		return volume;

	/** Sets its volume, 0 to 1 (before it starts, it starts at it). False, changing nothing, for a volume outside 0 to 1, or once finished. */
	public function setVolume(volume:Float):Bool {
		if (finished || !Math.isFinite(volume) || volume < 0 || volume > 1)
			return false;
		this.volume = volume;
		if (id != 0)
			resource.getBackend().setVolume(id, volume);
		return true;
	}

	/** Starts it once audio runs, and finishes it, releasing its resource reference, once the adapter no longer plays it. AudioResources.poll
		calls it. */
	public function poll():Void {
		if (finished)
			return;
		if (waiting) {
			if (resource.getBackend().isRunning())
				begin();
			return;
		}
		if (!resource.getBackend().isPlaying(id))
			end();
	}
}
