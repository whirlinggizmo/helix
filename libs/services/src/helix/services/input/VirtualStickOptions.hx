package helix.services.input;

import helix.math.Bounds2D;
import helix.math.Vector2D;

/** Specifies one stick of a virtual gamepad. A field left out takes the gamepad's options, or their default. */
@:structInit
class VirtualStickOptions {
	/** Whether it's on the screen. Defaults to true. */
	@:optional public final enabled:Null<Bool>;

	/** Where a finger can land to take it. */
	@:optional public final touchZone:Null<Bounds2D>;

	/** Where the base goes. */
	@:optional public final basePlacement:Null<VirtualStickBase>;

	/** Where the base stays with `Fixed` placement. */
	@:optional public final fixedBasePosition:Null<Vector2D>;

	/** How far the knob travels for a full push. Defaults to 60 times the window's pixel ratio. */
	@:optional public final radius:Null<Float>;

	/** How far the knob moves before the stick reads, as a share of the radius. */
	@:optional public final deadZone:Null<Float>;
}
