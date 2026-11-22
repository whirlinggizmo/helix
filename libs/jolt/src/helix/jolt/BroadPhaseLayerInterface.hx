package helix.jolt;

/** Represents a map from object layers to broad phase layers, set as `JoltSettings.mBroadPhaseLayerInterface`. Made as a
	`BroadPhaseLayerInterfaceTable`. */
class BroadPhaseLayerInterface {
	@:allow(helix.jolt) var numBroadPhaseLayers = 0;
	@:allow(helix.jolt) var map:Array<Int> = [];

	function new() {}
}
