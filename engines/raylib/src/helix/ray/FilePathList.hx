package helix.ray;

/** Represents raylib's `FilePathList`: paths, as a directory listing or a drop gives them. */
class FilePathList {
	/** Gets or sets how many paths the list was made for: 8192 for `LoadDirectoryFilesExAsync`'s, the count for
		`LoadDirectoryFilesAsync`'s, and 0 for `LoadDroppedFiles`'s, as raylib's. */
	public var capacity:Int = 0;

	/** Gets or sets how many paths there are. */
	public var count:Int = 0;

	/** Gets or sets the paths. */
	public var paths:Array<String> = [];

	/** Creates an empty list. */
	public function new() {}
}
