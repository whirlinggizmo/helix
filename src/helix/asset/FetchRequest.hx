package helix.asset;

/** A GET of url: maxBytes limits the body (default 8 MiB), timeoutSeconds bounds the whole transfer (default 15), noCache bypasses HTTP caches
	(default false), headers are sent with it (none by default). */
typedef FetchRequest = {
	final url:String;
	@:optional final maxBytes:Int;
	@:optional final timeoutSeconds:Float;
	@:optional final noCache:Bool;
	@:optional final headers:Map<String, String>;
}
