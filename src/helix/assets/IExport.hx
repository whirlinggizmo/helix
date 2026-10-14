package helix.assets;

import haxe.io.Bytes;

/** Where an exported file went: a path natively, the downloaded file's name in a browser; or why it couldn't be. */
enum ExportResult {
	Exported(where:String);
	Failed(message:String);
}

/** Hands a finished file to the user on a platform: a browser downloads it, natively it is written into the directory the profile chose (the
	user's pictures, say). What is exported and what it is called are the caller's (Screenshots names its files). */
interface IExport {
	/** Hands bytes over as a file called name (a plain file name: no directory, not hidden), of mimeType ("image/png"); a file of that name
		natively is replaced. done runs once on the host thread, during this call or later: Exported, or Failed (no room, no permission). Throws
		for a name that isn't a plain file name. */
	public function export(name:String, mimeType:String, bytes:Bytes, done:ExportResult->Void):Void;
}
