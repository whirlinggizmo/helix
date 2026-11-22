package helix.jolt;

/** Represents a map from object layers to broad phase layers, set in a table.

	```haxe
	var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(2, 2);
	broadPhaseLayers.MapObjectToBroadPhaseLayer(LAYER_NON_MOVING, new BroadPhaseLayer(0));
	broadPhaseLayers.MapObjectToBroadPhaseLayer(LAYER_MOVING, new BroadPhaseLayer(1));
	``` */
class BroadPhaseLayerInterfaceTable extends BroadPhaseLayerInterface {
	/** Creates a map with every object layer in broad phase layer 0.

		@param inNumObjectLayers  The number of object layers.
		@param inNumBroadPhaseLayers  The number of broad phase layers. */
	public function new(inNumObjectLayers:Int, inNumBroadPhaseLayers:Int) {
		super();
		throw "not built yet";
	}

	/** Puts an object layer in a broad phase layer.

		@param inObjectLayer  The object layer.
		@param inBroadPhaseLayer  The broad phase layer. */
	public function MapObjectToBroadPhaseLayer(inObjectLayer:Int, inBroadPhaseLayer:BroadPhaseLayer):Void {
		throw "not built yet";
	}
}
