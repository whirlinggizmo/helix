package helix.jolt;

/** Represents a list of body ids, filled by `PhysicsSystem.GetActiveBodies` and read by the bulk reads of `BodyInterface`. Reused from
	one step to the next, it allocates only when it grows. */
class BodyIDVector {
	/** Creates an empty list. */
	public function new() {
		ids = [];
		count = 0;
	}

	/** Returns the number of ids.

		@return  The count. */
	public function size():Int {
		return count;
	}

	/** Returns an id.

		@param inIndex  The id's index, 0 to `size() - 1`.
		@return  The id. */
	public function at(inIndex:Int):BodyID {
		return ids[inIndex];
	}

	/** Adds an id at the end.

		@param inBodyID  The id. */
	public function push_back(inBodyID:BodyID):Void {
		if (count < ids.length)
			ids[count] = inBodyID;
		else
			ids.push(inBodyID);
		count++;
	}

	/** Removes every id, keeping the memory. */
	public function clear():Void {
		count = 0;
	}

	@:allow(helix.jolt) var ids:Array<BodyID>;
	@:allow(helix.jolt) var count:Int;

	/** Fills the list from the bulk buffer's first `length` ints. */
	@:allow(helix.jolt) function readBulk(length:Int):Void {
		var base = helix.jolt.internal.Io.bulk(length * 4);
		count = 0;
		for (n in 0...length)
			push_back(new BodyID(helix.jolt.internal.Io.bulkI(base, n)));
	}
}
