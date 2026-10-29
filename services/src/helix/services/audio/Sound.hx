package helix.services.audio;

/** Represents a sound ready to play: decoded whole (`Audio.load`) or opened to be read as it plays (`Audio.stream`). */
class Sound {
	@:allow(helix.services.audio)
	function new() {}

	/** Gets the path it was loaded from. */
	public var path(default, null):String;

	/** Gets a value indicating whether it's read as it plays (`Audio.stream`) rather than held whole. */
	public var streamed(default, null):Bool;
}
