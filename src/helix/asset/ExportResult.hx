package helix.asset;

/** Where an exported file went: a path natively, the downloaded file's name in a browser; or why it couldn't be. */
enum ExportResult {
	Exported(where:String);
	Failed(message:String);
}
