package helix.jolt;

/** Represents which bodies a query tests. Made as an `IgnoreSingleBodyFilter` or an `IgnoreMultipleBodiesFilter`. */
class BodyFilter {
	@:allow(helix.jolt) var kind = 0;
	@:allow(helix.jolt) var value = 0;

	function new() {}
}
