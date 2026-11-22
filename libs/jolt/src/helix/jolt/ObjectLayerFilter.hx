package helix.jolt;

/** Represents which object layers a query tests. Made as a `DefaultObjectLayerFilter` or a `SpecifiedObjectLayerFilter`. */
class ObjectLayerFilter {
	@:allow(helix.jolt) var kind = 0;
	@:allow(helix.jolt) var value = 0;

	function new() {}
}
