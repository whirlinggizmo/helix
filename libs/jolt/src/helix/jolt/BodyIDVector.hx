package helix.jolt;

/** Represents a list of body ids, filled by `PhysicsSystem.GetActiveBodies` and read by the bulk reads of `BodyInterface`. Reused from
	one step to the next, it allocates only when it grows. */
class BodyIDVector {
	/** Creates an empty list. */
	public function new() {
		throw "not built yet";
	}

	/** Returns the number of ids.

		@return  The count. */
	public function size():Int {
		throw "not built yet";
	}

	/** Returns an id.

		@param inIndex  The id's index, 0 to `size() - 1`.
		@return  The id. */
	public function at(inIndex:Int):BodyID {
		throw "not built yet";
	}

	/** Adds an id at the end.

		@param inBodyID  The id. */
	public function push_back(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Removes every id, keeping the memory. */
	public function clear():Void {
		throw "not built yet";
	}
}
