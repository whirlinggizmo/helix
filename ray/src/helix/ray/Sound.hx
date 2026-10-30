package helix.ray;

/** Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`. */
class Sound {
	// The service's sound once decoded, shared by its file's loads; its voice last played; plays asked for before it was decoded; its file.
	@:allow(helix.ray)
	var sound:Null<helix.services.audio.Sound> = null;
	@:allow(helix.ray)
	var voice:Null<helix.services.audio.Voice> = null;
	@:allow(helix.ray)
	var volume = 1.;
	@:allow(helix.ray)
	var waiting = 0;
	@:allow(helix.ray)
	var unloaded = false;
	@:allow(helix.ray)
	var path = "";

	@:allow(helix.ray)
	function new() {}
}
