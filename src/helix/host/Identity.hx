package helix.host;

/** Who the program is, for what HeliX keeps for it: a company and a product, each one safe file name. Natively it names the cache directory
	(<user cache>/<company>/<product>); in the browser, the page's cache database. */
class Identity {
	var company:String;
	var product:String;

	/** product and company, cleaned (cleanName). Throws for a name that cleans to nothing or is too long. */
	public function new(product:String, company = "DefaultCompany") {
		var p = cleanName(product), c = cleanName(company);
		if (p == null || c == null)
			throw 'Identity names must be file names: "$company" / "$product"';
		this.product = p;
		this.company = c;
	}

	/** The company, cleaned; "DefaultCompany" unless given. */
	public function getCompany():String
		return company;

	/** The product, cleaned: the program's own name. */
	public function getProduct():String
		return product;

	/** name as one file name every desktop accepts: characters no file system takes (<>:"/\|? *, control characters) become _, leading and
		trailing dots and spaces go, and a Windows device name (CON, PRN, AUX, NUL, COM1-9, LPT1-9, with any extension) gets a leading _.
		null for a name that's empty once cleaned, or 128 characters or more (refused, never cut). */
	public static function cleanName(name:String):Null<String> {
		if (name == null || name.length >= 128)
			return null;
		var kept = new StringBuf();
		for (i in 0...name.length) {
			var c = StringTools.fastCodeAt(name, i);
			kept.add(c < 0x20 || "<>:\"/\\|?*".indexOf(String.fromCharCode(c)) >= 0 ? "_" : String.fromCharCode(c));
		}
		var text = kept.toString(), start = 0, end = text.length;
		while (start < end && (text.charAt(start) == "." || text.charAt(start) == " "))
			start++;
		while (end > start && (text.charAt(end - 1) == "." || text.charAt(end - 1) == " "))
			end--;
		if (start == end)
			return null;
		text = text.substring(start, end);
		var stem = text.split(".")[0].toUpperCase();
		var device = ["CON", "PRN", "AUX", "NUL"].contains(stem)
			|| stem.length == 4
			&& (StringTools.startsWith(stem, "COM") || StringTools.startsWith(stem, "LPT"))
			&& stem.charAt(3) >= "1"
			&& stem.charAt(3) <= "9";
		return device ? "_" + text : text;
	}

	#if sys
	/** Where this program's cache goes on this desktop: under $XDG_CACHE_HOME (or ~/.cache) on Linux, ~/Library/Caches on macOS, and
		%LOCALAPPDATA%\<company>\<product>\cache on Windows (that folder is the program's own, not only its cache). null when the user's
		directories aren't known. */
	public function getCacheDirectory():Null<String> {
		var system = Sys.systemName();
		if (system == "Windows") {
			var local = Sys.getEnv("LOCALAPPDATA");
			return local == null || local == "" ? null : haxe.io.Path.join([local, company, product, "cache"]);
		}
		var home = Sys.getEnv("HOME");
		if (system == "Mac")
			return home == null || home == "" ? null : haxe.io.Path.join([home, "Library/Caches", company, product]);
		var xdg = Sys.getEnv("XDG_CACHE_HOME");
		var base = xdg != null
			&& StringTools.startsWith(xdg, "/") ? xdg : home == null || home == "" ? null : haxe.io.Path.join([home, ".cache"]);
		return base == null ? null : haxe.io.Path.join([base, company, product]);
	}
	#end
}
