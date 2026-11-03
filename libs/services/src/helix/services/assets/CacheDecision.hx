package helix.services.assets;

import haxe.io.Bytes;
import helix.platform.IFileSystem;

/** Specifies what a server source does for a path, as its cache decides.

	It uses the bytes held in memory, uses its kept copy, reads a shipped file in place, or downloads the file, asking about the copy when
	there is one. */
@:noCompletion
enum CacheDecision {
	/** Uses the bytes held this run. */
	Held(bytes:Bytes);

	/** Uses the kept copy the record describes. */
	UseCopy(record:CopyRecord);

	/** Reads a shipped file in place, which its manifests list at the label; a missing one is downloaded to the label. */
	UseShipped(fileSystem:IFileSystem, label:String);

	/** Downloads the file, asking about the record's copy when there is one, the bytes to have the label when there is one. replacing
		tells whether a record may be there, to be deleted before the new bytes are written. */
	Download(record:Null<CopyRecord>, label:Null<String>, replacing:Bool);
}
