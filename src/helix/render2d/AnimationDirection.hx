package helix.render2d;

/** Which way a SpriteAnimation plays through its frames (Aseprite's tag directions). */
enum abstract AnimationDirection(Int) {
	/** First to last. */
	var Forward;

	/** Last to first. */
	var Reverse;

	/** First to last and back, the ends shown once a turn. */
	var PingPong;

	/** Last to first and back, the ends shown once a turn. */
	var PingPongReverse;
}
