package helix.geometry;

import helix.math.Transform3D;

/** Represents a bone of a skeleton: its name, its parent, and where it is at rest. */
class Bone3D {
	/** Gets its name: empty for none. */
	public final name:String;

	/** Gets its parent, an index into its skeleton's `bones`, before it; -1 for a root. */
	public final parent:Int;

	/** Gets where it is at rest, relative to its parent; for a root, relative to the model, with whatever placed it there. */
	public final rest:Transform3D;

	/** Creates a bone.

		@param name  Its name.
		@param parent  Its parent's index, before it; -1 for a root.
		@param rest  Where it is at rest. */
	public function new(name:String, parent:Int, rest:Transform3D) {
		this.name = name;
		this.parent = parent;
		this.rest = rest;
	}
}
