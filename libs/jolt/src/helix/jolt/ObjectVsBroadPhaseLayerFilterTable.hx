package helix.jolt;

/** Represents which broad phase layers each object layer meets, worked out from the object layers that collide and the broad phase
	layer each is in. */
class ObjectVsBroadPhaseLayerFilterTable extends ObjectVsBroadPhaseLayerFilter {
	/** Creates the filter.

		@param inBroadPhaseLayerInterface  The map from object layers to broad phase layers.
		@param inNumBroadPhaseLayers  The number of broad phase layers.
		@param inObjectLayerPairFilter  The object layers that collide.
		@param inNumObjectLayers  The number of object layers. */
	public function new(inBroadPhaseLayerInterface:BroadPhaseLayerInterfaceTable, inNumBroadPhaseLayers:Int,
			inObjectLayerPairFilter:ObjectLayerPairFilterTable, inNumObjectLayers:Int) {
		super();
		broadPhaseLayers = inBroadPhaseLayerInterface;
		objectPairs = inObjectLayerPairFilter;
	}
}
