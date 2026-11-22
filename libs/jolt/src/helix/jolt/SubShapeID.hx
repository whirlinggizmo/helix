package helix.jolt;

/** Represents the part of a shape a query hit: a compound's child, a mesh's triangle. Holds no object, and compares by value. */
abstract SubShapeID(Int) {
	/** Creates the id of the whole shape. */
	public inline function new() {
		this = 0xffffffff;
	}

	/** Returns the id's value.

		@return  The value. */
	public function GetValue():Int {
		throw "not built yet";
	}
}
