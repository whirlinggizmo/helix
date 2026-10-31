package helix.ray;

/** Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`. */
@:allow(helix.ray)
class Sound {
	/** Gets the number of frames, at 44100 a second; 0 until the sound is loaded. */
	public var frameCount(default, null) = 0;

	// The service's sound once decoded or made, shared by its file's loads and by its aliases; its voice last played; plays asked for
	// before it was decoded; its file ("" for one made from a wave); the samples of one made from a wave, and its channels; the sound
	// an alias shares, and an owner's aliases.
	@:allow(helix.ray)
	var sound:Null<helix.services.audio.Sound> = null;
	@:allow(helix.ray)
	var voice:Null<helix.services.audio.Voice> = null;
	@:allow(helix.ray)
	var volume = 1.;
	@:allow(helix.ray)
	var pitch = 1.;
	@:allow(helix.ray)
	var pan = .5;
	@:allow(helix.ray)
	var waiting = 0;
	@:allow(helix.ray)
	var unloaded = false;
	@:allow(helix.ray)
	var path = "";
	@:allow(helix.ray)
	var samples:Null<haxe.io.Bytes> = null;
	@:allow(helix.ray)
	var source:Null<Sound> = null;
	@:allow(helix.ray)
	var aliases:Array<Sound> = [];

	@:allow(helix.ray)
	function new() {}
}
