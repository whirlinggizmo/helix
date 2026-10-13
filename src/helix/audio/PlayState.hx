package helix.audio;

/** Where a playback is: playing, paused, stopped (by stop(), or it never started), or complete (it played to its end). */
enum abstract PlayState(Int) {
	var Stopped;
	var Playing;
	var Paused;
	var Complete;
}
