package helix.raylib;

/** Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`. */
@:allow(helix.raylib)
class Sound {
	/** Gets the number of frames, at 44100 a second, or 0 until the sound is loaded. */
	public var frameCount(default, null) = 0;

	// The service's sound once decoded or made, shared by its file's loads and by its aliases; its voice last played; plays asked for
	// before it was decoded; its file ("" for one made from a wave); the samples of one made from a wave, and its channels; the sound
	// an alias shares, and an owner's aliases.
	@:allow(helix.raylib)
	var sound:Null<helix.services.audio.Sound> = null;
	// A sound made from a wave and unloaded while its aliases play: its samples, freed with the last alias.
	@:allow(helix.raylib)
	var held:Null<helix.services.audio.Sound> = null;
	@:allow(helix.raylib)
	var voice:Null<helix.services.audio.Voice> = null;
	@:allow(helix.raylib)
	var volume = 1.;
	@:allow(helix.raylib)
	var pitch = 1.;
	@:allow(helix.raylib)
	var pan = .5;
	@:allow(helix.raylib)
	var waiting = 0;
	@:allow(helix.raylib)
	var unloaded = false;
	@:allow(helix.raylib)
	var path = "";
	@:allow(helix.raylib)
	var samples:Null<haxe.io.Bytes> = null;
	@:allow(helix.raylib)
	var source:Null<Sound> = null;
	@:allow(helix.raylib)
	var aliases:Array<Sound> = [];

	@:allow(helix.raylib)
	function new() {}
}
