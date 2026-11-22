package helix.box2d;

/** The input of `b2ComputeTimeOfImpact`. */
class B2TOIInput {
	/** The proxy for shape A. */
	public var proxyA:B2ShapeProxy;

	/** The proxy for shape B. */
	public var proxyB:B2ShapeProxy;

	/** The movement of shape A. */
	public var sweepA:B2Sweep;

	/** The movement of shape B. */
	public var sweepB:B2Sweep;

	/** The end of the sweep interval, which runs from 0 to this fraction. */
	public var maxFraction:Float;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2TOIInput(this);
	}
}
