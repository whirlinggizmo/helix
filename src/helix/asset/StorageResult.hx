package helix.asset;

import haxe.io.Bytes;

/** How a read ended: the stored bytes, Missing, a failure message, or cancellation. */
enum StorageResult {
	Stored(bytes:Bytes);
	Missing;
	Failed(message:String);
	Cancelled;
}
