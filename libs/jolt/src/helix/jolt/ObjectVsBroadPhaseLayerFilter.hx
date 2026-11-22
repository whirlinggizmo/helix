package helix.jolt;

/** Represents which broad phase layers each object layer meets, set as `JoltSettings.mObjectVsBroadPhaseLayerFilter`. Made as an
	`ObjectVsBroadPhaseLayerFilterTable`. */
class ObjectVsBroadPhaseLayerFilter {
	@:allow(helix.jolt) var broadPhaseLayers:BroadPhaseLayerInterface;
	@:allow(helix.jolt) var objectPairs:ObjectLayerPairFilter;

	function new() {}

	/** Returns whether an object layer meets a broad phase layer: whether it collides with an object layer in it. */
	@:allow(helix.jolt) function meets(inObjectLayer:Int, inBroadPhaseLayer:Int):Bool {
		for (layer in 0...broadPhaseLayers.map.length)
			if (broadPhaseLayers.map[layer] == inBroadPhaseLayer && objectPairs.ShouldCollide(inObjectLayer, layer))
				return true;
		return false;
	}
}
