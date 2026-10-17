package helix.assets;

/** Where a load's failure goes: to the caller's failed lambda, or, when it gave none, to the log with the path, so nothing fails silently. Every
	load taking (loaded, ?failed) reports through it. */
class Failure {
	/** Calls failed with message, or, when failed is null, traces "Load failed: path: message" (the path once when message begins with it). */
	public static function report(path:String, message:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(message);
		else
			trace(StringTools.startsWith(message, path) ? 'Load failed: $message' : 'Load failed: $path: $message');
	}
}
