package helix.audio;

/** Fully decoded, reusable audio resource. */
class AudioClip extends AudioResource {
	/** The asset it was loaded from, which a reload replaces in place. */
	public var path(default, null):Null<String>;

	/** Owns backend clip id, loaded from path when given; AudioResources.loadClip creates it. */
	@:noCompletion
	public function new(id:Int, backend:IAudio, ?path:String) {
		super(id, backend, null);
		this.path = path;
	}

	override function startVoice(loop:Bool, volume:Float):Int
		return backend.playClip(id, loop, volume);

	// The current backend clip: a reload may have replaced the one it was made with.
	override function dispose():Void
		backend.destroyClip(id);
}
