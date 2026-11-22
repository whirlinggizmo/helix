package helix.jolt;

/** Represents the settings a `JoltInterface` is constructed with: its limits and its collision layers.

	The three layer fields must be set. `mObjectLayerPairFilter` decides which object layers collide, `mBroadPhaseLayerInterface` maps
	each object layer to a broad phase layer, and `mObjectVsBroadPhaseLayerFilter` decides which broad phase layers an object layer
	meets. */
class JoltSettings {
	/** Gets or sets the most bodies the system holds. Defaults to 10240. */
	public var mMaxBodies:Int = 10240;

	/** Gets or sets the most pairs of bodies whose bounds overlap in one step. Defaults to 65536. */
	public var mMaxBodyPairs:Int = 65536;

	/** Gets or sets the most contacts between bodies in one step. Defaults to 10240. */
	public var mMaxContactConstraints:Int = 10240;

	/** Gets or sets which object layers collide. Must be set. */
	public var mObjectLayerPairFilter:ObjectLayerPairFilter;

	/** Gets or sets which broad phase layer each object layer is in. Must be set. */
	public var mBroadPhaseLayerInterface:BroadPhaseLayerInterface;

	/** Gets or sets which broad phase layers each object layer meets. Must be set. */
	public var mObjectVsBroadPhaseLayerFilter:ObjectVsBroadPhaseLayerFilter;

	/** Creates settings with the default limits and no layers. */
	public function new() {}
}
