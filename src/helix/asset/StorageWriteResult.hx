package helix.asset;

/** How a write or remove ended: Written, a failure message, or cancellation. */
enum StorageWriteResult {
	Written;
	Failed(message:String);
	Cancelled;
}
