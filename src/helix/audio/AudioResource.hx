package helix.audio;

/** One owner plus active playback references. release() drops the owner's reference. */
class AudioResource {
	@:allow(helix.audio.AudioResources) var id:Int;
	var backend:IAudio;
	var disposed = false;

	/** The backend clip or stream id, which a reload may replace. */
	public function getId():Int
		return id;

	/** The audio adapter that owns the backend resource. */
	public function getBackend():IAudio
		return backend;

	/** Whether the owner and every playback have released it, so its backend resource is destroyed. */
	public function isDisposed():Bool
		return disposed;

	var references = 1;
	var ownerReleased = false;
	var destroy:Void->Void;

	/** Owns backend resource id with the owner's reference; destroy runs when the last reference is released. */
	public function new(id:Int, backend:IAudio, destroy:Void->Void) {
		this.id = id;
		this.backend = backend;
		this.destroy = destroy;
	}

	/** Adds a reference for a starting playback. Throws once the owner has released it. */
	public function retainPlayback():Void {
		if (ownerReleased)
			throw "Released audio resource";
		references++;
	}

	/** Drops a playback's reference; the last reference destroys the backend resource. */
	public function releasePlayback():Void {
		references--;
		if (references == 0) {
			disposed = true;
			dispose();
		}
	}

	function dispose():Void
		destroy();

	/** Drops the owner's reference, once; the backend resource is destroyed when no playback still holds it. */
	public function release():Void {
		if (!ownerReleased) {
			ownerReleased = true;
			releasePlayback();
		}
	}
}
