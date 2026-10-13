package helix.audio;

/** One active/paused playback; holds its resource until stopped or naturally finished. */
class AudioPlayback {
	var id:Int;
	var finished = false;
	var resource:AudioResource;
	var source:Int;

	/** The backend playback id; 0 when the backend could not start it. */
	public function getId():Int
		return id;

	/** Whether it was stopped, played to its end, or never started; its resource reference is released then. */
	public function isFinished():Bool
		return finished;

	/** The backend resource it plays, kept as it started: a reload may replace the resource's. */
	public function getSource():Int
		return source;

	/** Holds a playback reference on resource that the caller retained; an id of 0 finishes it, releasing that reference, at once. AudioResources.play creates it. */
	public function new(id:Int, resource:AudioResource) {
		this.id = id;
		this.resource = resource;
		source = resource.getId();
		if (id == 0)
			end();
	}

	function end():Void {
		if (!finished) {
			finished = true;
			resource.releasePlayback();
		}
	}

	/** Stops it and releases its resource reference; does nothing once finished. */
	public function stop():Void {
		if (!finished) {
			resource.getBackend().stop(id);
			end();
		}
	}

	/** Pauses it, or resumes it when paused is false; does nothing once finished. */
	public function pause(paused = true):Void {
		if (!finished)
			resource.getBackend().pause(id, paused);
	}

	/** Sets its volume, 0 to 1; does nothing once finished. Throws for a volume outside 0 to 1. */
	public function setVolume(volume:Float):Void {
		if (!finished)
			resource.getBackend().setVolume(id, volume);
	}

	/** Finishes it, releasing its resource reference, once the backend no longer plays it. AudioResources.poll calls it. */
	public function poll():Void {
		if (!finished && !resource.getBackend().isPlaying(id))
			end();
	}
}
