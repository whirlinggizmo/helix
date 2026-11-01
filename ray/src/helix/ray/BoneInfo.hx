package helix.ray;

/** Represents raylib's `BoneInfo`: one bone of a skeleton, its name and its parent. */
@:structInit
class BoneInfo {
	/** Gets or sets the name: its node's, cut to 31 bytes as raylib's holds it. */
	public var name:String;

	/** Gets or sets the parent, by its index in the same bones, or -1 for a root. */
	public var parent:Int;

	/** Creates a BoneInfo, each part omitted empty or 0, as raylib's struct starts.

		@param name  The name.
		@param parent  The parent's index, or -1 for a root. */
	public function new(name:String = "", parent:Int = 0) {
		this.name = name;
		this.parent = parent;
	}
}
