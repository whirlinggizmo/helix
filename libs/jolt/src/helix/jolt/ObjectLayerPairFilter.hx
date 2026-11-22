package helix.jolt;

/** Represents which object layers collide, set as `JoltSettings.mObjectLayerPairFilter`. Made as an `ObjectLayerPairFilterTable`. */
class ObjectLayerPairFilter {
	@:allow(helix.jolt) var numObjectLayers = 0;
	@:allow(helix.jolt) var pairs:Array<Bool> = [];

	function new() {}

	/** Returns whether two object layers collide.

		@param inLayer1  One layer.
		@param inLayer2  The other layer.
		@return  True when bodies in the two layers collide. */
	public function ShouldCollide(inLayer1:Int, inLayer2:Int):Bool {
		return inLayer1 >= 0
			&& inLayer2 >= 0
			&& inLayer1 < numObjectLayers
			&& inLayer2 < numObjectLayers
			&& pairs[inLayer1 * numObjectLayers + inLayer2];
	}
}
