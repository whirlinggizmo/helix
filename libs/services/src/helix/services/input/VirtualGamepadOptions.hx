package helix.services.input;

import helix.math.Bounds2D;

/** Specifies a virtual gamepad (`VirtualGamepad`). Every field has a default, so options set only what they change. Each field here is
	both sticks' default. A field set in a stick's own options replaces it for that stick. Positions and sizes are framebuffer pixels. */
@:structInit
class VirtualGamepadOptions {
	/** Where each stick's base goes. Defaults to `Floating`. */
	@:optional public final basePlacement:Null<VirtualStickBase>;

	/** How far each stick's knob moves before the stick reads, as a share of the radius. Defaults to 0.12. */
	@:optional public final deadZone:Null<Float>;

	/** Bounds cut out of the sticks' touch zones. */
	@:optional public final blockedBounds:Null<Array<Bounds2D>>;

	/** The left stick. */
	@:optional public final left:Null<VirtualStickOptions>;

	/** The right stick. */
	@:optional public final right:Null<VirtualStickOptions>;
}
