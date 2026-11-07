package helix.raylib;

/** Represents raylib's `FilePathList`: the paths of a directory's listing or of a drop. */
class FilePathList {
	/** Gets or sets the list's capacity, as raylib's: 8192 for `LoadDirectoryFilesExAsync`'s, the count for `LoadDirectoryFilesAsync`'s and
		0 for `LoadDroppedFiles`'s. */
	public var capacity:Int = 0;

	/** Gets or sets how many paths there are. */
	public var count:Int = 0;

	/** Gets or sets the paths. */
	public var paths:Array<String> = [];

	/** Creates an empty list. */
	public function new() {}
}
