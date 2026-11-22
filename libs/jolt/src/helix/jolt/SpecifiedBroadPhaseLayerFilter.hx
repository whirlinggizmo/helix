package helix.jolt;

/** Represents one broad phase layer, the only one a query tests. */
class SpecifiedBroadPhaseLayerFilter extends BroadPhaseLayerFilter {
	/** Creates the filter.

		@param inBroadPhaseLayer  The broad phase layer. */
	public function new(inBroadPhaseLayer:BroadPhaseLayer) {
		super();
		kind = 2;
		value = inBroadPhaseLayer.GetValue();
	}
}
