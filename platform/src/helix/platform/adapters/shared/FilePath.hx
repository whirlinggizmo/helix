package helix.platform.adapters.shared;

/** The paths `IFileSystem` takes, checked the same way by every adapter. */
@:noCompletion
class FilePath {
	/** Returns whether a path is one `IFileSystem` takes: plain names of letters, digits, `_`, `-` and `.` joined by `/`, at most 256
		characters, none empty, `.` or `..`.

		@param path  The path.
		@return  True when it is. */
	public static function isValid(path:String):Bool {
		if (path == null || path.length == 0 || path.length > 256)
			return false;
		for (i in 0...path.length) {
			var c = path.charCodeAt(i);
			if (!(c >= 65 && c <= 90 || c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 95 || c == 46 || c == 45 || c == 47))
				return false;
		}
		for (part in path.split("/"))
			if (part == "" || part == "." || part == "..")
				return false;
		return true;
	}

	/** The failure for a path `isValid` refuses. */
	public static inline var INVALID = "Invalid file path";
}
