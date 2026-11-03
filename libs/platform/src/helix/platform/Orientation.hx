package helix.platform;

/** Specifies which way up a game wants the screen (`IWindow.requestOrientation`). */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Orientation(Int) to Int {
	/** As the player holds it, with any lock released. */
	var Any;

	/** Wider than tall, with the long side across. */
	var Landscape;

	/** Taller than wide, as a phone held upright. */
	var Portrait;
}
