package helix.assets;

/** Validates asset and storage keys, for the asset service, the shared Storage and model files. */
class AssetPath {
	/** Whether path is a safe relative path: 1 to 256 characters of A-Z, a-z, 0-9, '_', '.', '-' and '/', with no empty, "." or ".." segment (so no leading slash and no URL). */
	public static function valid(path:String):Bool {
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
}
