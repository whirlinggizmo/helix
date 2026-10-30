package helix.ray;

/** Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`. */
class Sound {
	// The service's sound once decoded; its voice last played; plays asked for before it was decoded; the load's abort while in flight.
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
	var cancel:Null<Void->Void> = null;

	@:allow(helix.ray)
	function new() {}
}
