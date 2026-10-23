package helix.asset;

import haxe.io.Bytes;
import helix.asset.ExportResult;

/** Hands a finished file to the user on a platform: a browser downloads it, natively it is written into the directory the profile chose (the
	user's pictures, say). What is exported and what it is called are the caller's (Screenshots names its files). */
@:noCompletion
interface IExport {
	/** Hands bytes over as a file called name (a plain file name: no directory, not hidden), of mimeType ("image/png"); a file of that name
		natively is replaced. done runs once on the host thread, during this call or later: Exported, or Failed (no room, no permission). Throws
		for a name that isn't a plain file name. */
	public function export(name:String, mimeType:String, bytes:Bytes, done:ExportResult->Void):Void;
}
