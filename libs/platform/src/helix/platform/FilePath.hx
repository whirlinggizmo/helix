package helix.platform;

/** Provides the rule for the paths `IFileSystem` takes, which every file system adapter checks, and which helix-services' `Assets`
	holds every source to, so a name is refused the same way on every target. */
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
