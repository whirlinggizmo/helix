package helix.platform.adapters.shared;

/** Provides a page's finger ids from the browser's pointer ids: a landing finger receives the smallest id no finger down has, as the native
	events adapter numbers SDL's fingers. */
@:noCompletion
class FingerIds {
	// The browser's pointer id of the finger down in each id; null where the id is free.
	final pointers:Array<Null<Int>> = [];

	/** Creates the ids, with no finger down. */
	public function new() {}

	/** Returns the id a landing finger receives: the smallest no finger down has.

		@param pointer  The browser's pointer id.
		@return  The finger's id. */
	public function land(pointer:Int):Int {
		var id = pointers.indexOf(null);
		if (id < 0) {
			id = pointers.length;
			pointers.push(pointer);
		} else
			pointers[id] = pointer;
		return id;
	}

	/** Returns a finger's id.

		@param pointer  The browser's pointer id.
		@return  The id, or -1 for a pointer that isn't down. */
	public function find(pointer:Int):Int
		return pointers.indexOf(pointer);

	/** Frees a lifting finger's id for the next finger to land.

		@param pointer  The browser's pointer id.
		@return  The id the finger had, or -1 for a pointer that isn't down. */
	public function lift(pointer:Int):Int {
		var id = pointers.indexOf(pointer);
		if (id >= 0)
			pointers[id] = null;
		return id;
	}
}
