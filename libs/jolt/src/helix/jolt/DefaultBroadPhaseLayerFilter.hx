package helix.jolt;

/** Represents the broad phase layers an object layer meets: a query testing what a body of that layer would collide with. */
class DefaultBroadPhaseLayerFilter extends BroadPhaseLayerFilter {
	/** Creates the filter.

		@param inObjectVsBroadPhaseLayerFilter  The filter from the settings (`JoltInterface.GetObjectVsBroadPhaseLayerFilter`).
		@param inObjectLayer  The object layer. */
	public function new(inObjectVsBroadPhaseLayerFilter:ObjectVsBroadPhaseLayerFilter, inObjectLayer:Int) {
		super();
		kind = 1;
		value = inObjectLayer;
	}
}
