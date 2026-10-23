package helix.asset;

/** How ensure finds a file. source: where its bytes come from instead of its own path, a path read against the host as a browser reads a URL
	against a directory, or a whole URL; they're kept under the path asked for, remembering where they came from: a later plain load of the path
	asks about the copy there, and it streams from there when it's stale, as the host has nothing at the path. forceFetch: go past the cache to the host (or the packaged files),
	replacing what the cache holds. */
typedef EnsureOptions = {
	@:optional final source:String;
	@:optional final forceFetch:Bool;
}
