package helix.jolt;

/** Represents a broad phase layer: a group of object layers kept in a tree of their own, such as the bodies that never move. Holds no
	object. */
abstract BroadPhaseLayer(Int) {
	/** Creates a broad phase layer.

		@param inLayer  The layer's number, 0 to 255. */
	public inline function new(inLayer:Int) {
		this = inLayer;
	}

	/** Returns the layer's number.

		@return  The number. */
	public inline function GetValue():Int {
		return this;
	}
}
