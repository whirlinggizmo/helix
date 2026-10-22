package helix.asset;

/** Validates asset and storage keys, for the asset service, the shared StorageService and model files, and resolves a path one file names relative to itself. */
class AssetPath {
	/** Whether path is a safe relative path: 1 to 256 characters of A-Z, a-z, 0-9, '_', '.', '-' and '/', with no empty, "." or ".." segment (so no leading slash and no URL). */
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

	/** The asset path of uri (a file another names, relative to it: a model's buffers and images, a sprite sheet's image) beside the file at path: its %-escapes decoded and its "." and ".."
		segments followed. Null for one that isn't a relative path inside the assets (a URL, an absolute path, one climbing above them). */
	public static function resolve(path:String, uri:String):Null<String> {
		var decoded = try StringTools.urlDecode(uri) catch (e:Dynamic) return null;
		if (decoded.indexOf(":") >= 0 || StringTools.startsWith(decoded, "/"))
			return null;
		var parts = path.split("/");
		parts.pop();
		for (part in decoded.split("/")) {
			if (part == "" || part == ".")
				continue;
			if (part == "..") {
				if (parts.length == 0)
					return null;
				parts.pop();
			} else
				parts.push(part);
		}
		var joined = parts.join("/");
		return isValid(joined) ? joined : null;
	}
}
