package helix.audio;

/** One owner plus active playback references. release() drops the owner's reference. */
class AudioResource {
	/** The backend clip or stream id, which a reload may replace. */
	@:allow(helix.audio.AudioResources)
	public var id(default, null):Int;

	/** The audio adapter that owns the backend resource. */
	@:noCompletion
	public var backend(default, null):IAudio;

	/** Whether the owner and every playback have released it, so its backend resource is destroyed. */
	public var disposed(default, null):Bool = false;

	var references = 1;
	var ownerReleased = false;
	var destroy:Void->Void;

	/** Owns backend resource id with the owner's reference; destroy runs when the last reference is released. */
	@:noCompletion
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

	/** Starts a voice of it at volume, looping if asked: the adapter's voice, or 0 when it can't start. Each kind starts its own. */
	@:allow(helix.audio.AudioPlayback)
	function startVoice(loop:Bool, volume:Float):Int
		throw "A resource of no kind";

	/** Drops the owner's reference, once; the backend resource is destroyed when no playback still holds it. */
	public function release():Void {
		if (!ownerReleased) {
			ownerReleased = true;
			releasePlayback();
		}
	}
}
