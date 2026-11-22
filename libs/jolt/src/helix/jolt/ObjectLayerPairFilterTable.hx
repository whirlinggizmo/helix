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
		numObjectLayers = inNumObjectLayers;
		pairs = [for (_ in 0...inNumObjectLayers * inNumObjectLayers) false];
	}

	/** Returns the number of object layers.

		@return  The count. */
	public function GetNumObjectLayers():Int {
		return numObjectLayers;
	}

	/** Makes two object layers collide, each with the other.

		@param inLayer1  One layer.
		@param inLayer2  The other layer, or the same one. */
	public function EnableCollision(inLayer1:Int, inLayer2:Int):Void {
		set(inLayer1, inLayer2, true);
	}

	/** Makes two object layers pass through each other.

		@param inLayer1  One layer.
		@param inLayer2  The other layer, or the same one. */
	public function DisableCollision(inLayer1:Int, inLayer2:Int):Void {
		set(inLayer1, inLayer2, false);
	}

	function set(inLayer1:Int, inLayer2:Int, inCollide:Bool):Void {
		if (inLayer1 < 0 || inLayer2 < 0 || inLayer1 >= numObjectLayers || inLayer2 >= numObjectLayers)
			return;
		pairs[inLayer1 * numObjectLayers + inLayer2] = inCollide;
		pairs[inLayer2 * numObjectLayers + inLayer1] = inCollide;
	}
}
