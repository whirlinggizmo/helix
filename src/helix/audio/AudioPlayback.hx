package helix.audio;

/** One active/paused playback; holds its resource until stopped or naturally finished. */
class AudioPlayback {
	var id:Int;
	var finished = false;
	var resource:AudioResource;
	var source:Int;

	public function getId():Int
		return id;

	public function isFinished():Bool
		return finished;

	/** The backend resource it plays, kept as it started: a reload may replace the resource's. */
	public function getSource():Int
		return source;

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

	public function stop():Void {
		if (!finished) {
			resource.getBackend().stop(id);
			end();
		}
	}

	public function pause(paused = true):Void {
		if (!finished)
			resource.getBackend().pause(id, paused);
	}

	public function setVolume(volume:Float):Void {
		if (!finished)
			resource.getBackend().setVolume(id, volume);
	}

	public function poll():Void {
		if (!finished && !resource.getBackend().isPlaying(id))
			end();
	}
}
