package helix.raylib;

/** Represents raylib's `BoneInfo`: one bone of a skeleton, its name and its parent.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class BoneInfo {
	/** Gets or sets the name, its node's cut to 31 bytes as raylib's struct holds it. */
	public var name:String;

	/** Gets or sets the parent, by its index in the same bones, or -1 for a root. */
	public var parent:Int;

	/** Creates a bone, each omitted part empty or 0, as raylib's struct starts.

		@param name  The name.
		@param parent  The parent's index, or -1 for a root. */
	public function new(name:String = "", parent:Int = -1) {
		this.name = name;
		this.parent = parent;
	}

	/** Returns a separate copy.

		@param out  Optional. The BoneInfo to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:BoneInfo):BoneInfo {
		if (out == null)
			return new BoneInfo(name, parent);
		out.name = name;
		out.parent = parent;
		return out;
	}
}
