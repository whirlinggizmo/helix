package helix.platform;

/** Provides the rule for the paths `IFileSystem` accepts, which every file system adapter checks, so a name is refused the same way on
	every target. */
class FilePath {
	/** Returns whether a path is one `IFileSystem` accepts: plain names of letters, digits, `_`, `-` and `.` joined by `/`, at most 256
		characters, none empty, `.` or `..`.

		@param path  The path.
		@return  True when it is. */
	public static function isValid(path:String):Bool
		return whyInvalid(path) == null;

	/** Returns why a path isn't one `IFileSystem` accepts, or null when it is.

		@param path  The path.
		@return  "Invalid file path: <reason>", such as `Invalid file path: "my level.json" contains a character other than letters,
			digits, _, - and .`, or null. */
	public static function whyInvalid(path:String):Null<String> {
		if (path == null || path.length == 0)
			return "Invalid file path: the path is empty";
		if (path.length > 256)
			return 'Invalid file path: "$path" is longer than 256 characters';
		for (i in 0...path.length) {
			var c = path.charCodeAt(i);
			if (!(c >= 65 && c <= 90 || c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 95 || c == 46 || c == 45 || c == 47))
				return 'Invalid file path: "$path" contains a character other than letters, digits, _, - and .';
		}
		if (StringTools.startsWith(path, "/"))
			return 'Invalid file path: "$path" is absolute';
		for (part in path.split("/"))
			if (part == "" || part == "." || part == "..")
				return 'Invalid file path: "$path" contains ${part == "" ? "an empty name" : '"$part"'}';
		return null;
	}

	/** Returns whether a name can be one directory's on every OS, as a program's company and product are: 1 to 64 characters, not `.` or
		`..`, no `/ \\ : * ? " < > |` or control characters, and no space or `.` at its end, which Windows drops.

		@param name  The name.
		@return  True when it can. */
	public static function isDirectoryName(name:String):Bool {
		if (name == null || name.length == 0 || name.length > 64 || name == "." || name == "..")
			return false;
		var last = name.charAt(name.length - 1);
		if (last == " " || last == ".")
			return false;
		for (i in 0...name.length) {
			var c = name.charCodeAt(i);
			if (c < 32 || '/\\:*?"<>|'.indexOf(name.charAt(i)) >= 0)
				return false;
		}
		return true;
	}
}
