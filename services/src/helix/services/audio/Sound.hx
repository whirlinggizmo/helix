package helix.services.audio;

/** Represents a sound ready to play, either decoded whole (`Audio.load`) or opened to be read as it plays (`Audio.stream`). */
@:allow(helix.services.audio)
class Sound {
	// The output's clip or stream, and what lets go of a located stream's file; unloaded once let go.
	var id:Int;
	var release:Null<Void->Void>;
	var unloaded = false;

	@:allow(helix.services.audio)
	function new(path:String, streamed:Bool, id:Int, release:Null<Void->Void>) {
		this.path = path;
		this.streamed = streamed;
		this.id = id;
		this.release = release;
	}

	/** Gets the path it was loaded from. */
	public var path(default, null):String;

	/** Gets a value indicating whether the sound is read as it plays (`Audio.stream`) rather than held whole. */
	public var streamed(default, null):Bool;
}
