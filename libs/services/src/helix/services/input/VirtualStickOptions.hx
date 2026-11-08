package helix.services.input;

import helix.math.Bounds2D;
import helix.math.Vector2D;

/** Represents how one stick of a `VirtualGamepad` starts. A field left out takes the gamepad's options, or their default. */
@:structInit
class VirtualStickOptions {
	/** Gets a value indicating whether the stick is enabled. Defaults to true. */
	@:optional public final enabled:Null<Bool>;

	/** Gets where the stick captures a landing finger. */
	@:optional public final touchZone:Null<Bounds2D>;

	/** Gets where the base goes. */
	@:optional public final basePlacement:Null<VirtualStickBase>;

	/** Gets where the base stays with `Fixed` placement. */
	@:optional public final fixedBasePosition:Null<Vector2D>;

	/** Gets how far the knob travels for a full push. Defaults to 60 times the window's pixel ratio. */
	@:optional public final radius:Null<Float>;

	/** Gets how far the knob moves before the stick reads, as a share of the radius. */
	@:optional public final deadZone:Null<Float>;
}
