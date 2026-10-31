package helix.platform.adapters.shared;

/** Provides what the system adapters share for `ISystem.openUrl`: which URLs are opened. */
@:noCompletion
class SystemUrl {
	/** Returns whether a URL is one `openUrl` opens: http, https or mailto, with no character a shell or a script could misread.

		@param url  The URL.
		@return  True for one it opens. */
	public static function isOpenable(url:String):Bool {
		var lower = url.toLowerCase();
		if (!StringTools.startsWith(lower, "http://")
			&& !StringTools.startsWith(lower, "https://")
			&& !StringTools.startsWith(lower, "mailto:"))
			return false;
		for (i in 0...url.length) {
			var c = url.charCodeAt(i);
			if (c <= 32 || c == "'".code || c == '"'.code || c == "`".code || c == "\\".code || c == 127)
				return false;
		}
		return true;
	}
}
