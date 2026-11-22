package helix.jolt;

/** Represents which object layers collide, set in a table.

	```haxe
	var objectFilter = new ObjectLayerPairFilterTable(2);
	objectFilter.EnableCollision(LAYER_NON_MOVING, LAYER_MOVING);
	objectFilter.EnableCollision(LAYER_MOVING, LAYER_MOVING);
	``` */
class ObjectLayerPairFilterTable extends ObjectLayerPairFilter {
	/** Creates a table where no layers collide.

		@param inNumObjectLayers  The number of object layers. */
	public function new(inNumObjectLayers:Int) {
		super();
		throw "not built yet";
	}

	/** Returns the number of object layers.

		@return  The count. */
	public function GetNumObjectLayers():Int {
		throw "not built yet";
	}

	/** Makes two object layers collide, each with the other.

		@param inLayer1  One layer.
		@param inLayer2  The other layer, or the same one. */
	public function EnableCollision(inLayer1:Int, inLayer2:Int):Void {
		throw "not built yet";
	}

	/** Makes two object layers pass through each other.

		@param inLayer1  One layer.
		@param inLayer2  The other layer, or the same one. */
	public function DisableCollision(inLayer1:Int, inLayer2:Int):Void {
		throw "not built yet";
	}
}
