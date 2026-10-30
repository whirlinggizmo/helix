package helix.ray;

/** Represents raylib's `Music`: a sound played as it is read, never held whole, through helix-services' `Audio.stream`. */
class Music {
	/** Gets or sets whether it starts again from its beginning when it ends; true until set, as raylib's. */
	public var looping = true;

	/** Gets the number of frames: 0 here, as the stream doesn't tell its length. */
	public var frameCount(default, null) = 0;

	// The service's streamed sound once opened; its voice; whether a play waits for it to open; its settings; its open's abort.
	@:allow(helix.ray)
	var sound:Null<helix.services.audio.Sound> = null;
	@:allow(helix.ray)
	var voice:Null<helix.services.audio.Voice> = null;
	@:allow(helix.ray)
	var waiting = false;
	@:allow(helix.ray)
	var volume = 1.;
	@:allow(helix.ray)
	var pitch = 1.;
	@:allow(helix.ray)
	var pan = .5;
	@:allow(helix.ray)
	var failed = false;
	@:allow(helix.ray)
	var cancel:Null<Void->Void> = null;

	@:allow(helix.ray)
	function new() {}
}
