package helix.ray;

/** Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`. */
class Sound {
	/** Gets the number of frames, 0 until it is decoded. */
	@:allow(helix.ray)
	public var frameCount(default, null):Int = 0;

	// The platform's clip, 0 until decoded; the voice last played, 0 for none; plays asked for before it was decoded.
	@:allow(helix.ray)
	var clip = 0;
	@:allow(helix.ray)
	var voice = 0;
	@:allow(helix.ray)
	var volume = 1.;
	@:allow(helix.ray)
	var waiting = 0;
	@:allow(helix.ray)
	var unloaded = false;

	@:allow(helix.ray)
	function new() {}
}
