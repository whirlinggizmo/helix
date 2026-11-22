package helix.jolt;

/** Represents which object layers collide, set as `JoltSettings.mObjectLayerPairFilter`. Made as an `ObjectLayerPairFilterTable`. */
class ObjectLayerPairFilter {
	function new() {}

	/** Returns whether two object layers collide.

		@param inLayer1  One layer.
		@param inLayer2  The other layer.
		@return  True when bodies in the two layers collide. */
	public function ShouldCollide(inLayer1:Int, inLayer2:Int):Bool {
		throw "not built yet";
	}
}
