package helix.graphics;

import haxe.io.Bytes;

/** How a screenshot ended: where it was saved and its PNG file, or why it wasn't. */
enum ScreenshotResult {
	Saved(where:String, png:Bytes);
	Failed(message:String);
}
