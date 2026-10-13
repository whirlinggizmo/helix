package helix.audio;

/** One owner plus active playback references. release() drops the owner's reference. */
class AudioResource {
	@:allow(helix.audio.AudioResources) var id:Int;
	var backend:IAudio;
	var disposed = false;

	public function getId():Int
		return id;

	public function getBackend():IAudio
		return backend;

	public function isDisposed():Bool
		return disposed;

	var references = 1;
	var ownerReleased = false;
	var destroy:Void->Void;

	public function new(id:Int, backend:IAudio, destroy:Void->Void) {
		this.id = id;
		this.backend = backend;
		this.destroy = destroy;
	}

	public function retainPlayback():Void {
		if (ownerReleased)
			throw "Released audio resource";
		references++;
	}

	public function releasePlayback():Void {
		references--;
		if (references == 0) {
			disposed = true;
			dispose();
		}
	}

	function dispose():Void
		destroy();

	public function release():Void {
		if (!ownerReleased) {
			ownerReleased = true;
			releasePlayback();
		}
	}
}
