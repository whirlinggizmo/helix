package helix.jolt;

/** Represents which broad phase layers a query tests. Made as a `DefaultBroadPhaseLayerFilter` or a `SpecifiedBroadPhaseLayerFilter`. */
class BroadPhaseLayerFilter {
	@:allow(helix.jolt) var kind = 0;
	@:allow(helix.jolt) var value = 0;

	function new() {}
}
