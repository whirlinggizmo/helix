package helix.services.input;

import helix.math.Bounds2D;

/** Represents how a `VirtualGamepad` starts. Every field has a default, so options set only what they change. Its placement and dead
	zone are both sticks' defaults. A field set in a stick's own options replaces it for that stick. Positions and sizes are framebuffer pixels. */
@:structInit
class VirtualGamepadOptions {
	/** Gets where each stick's base goes. Defaults to `Floating`. */
	@:optional public final basePlacement:Null<VirtualStickBase>;

	/** Gets how far each stick's knob moves before the stick reads, as a share of the radius. Defaults to 0.12. */
	@:optional public final deadZone:Null<Float>;

	/** Gets bounds where a landing finger stays free, even within a stick's touch zone. */
	@:optional public final blockedBounds:Null<Array<Bounds2D>>;

	/** Gets the left stick. */
	@:optional public final left:Null<VirtualStickOptions>;

	/** Gets the right stick. */
	@:optional public final right:Null<VirtualStickOptions>;

	/** Gets the buttons. Defaults to no buttons. */
	@:optional public final buttons:Null<Array<VirtualButtonOptions>>;
}
