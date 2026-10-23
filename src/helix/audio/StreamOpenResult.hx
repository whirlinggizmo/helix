package helix.audio;

/** How opening a stream ended: its id, or a failure message. */
enum StreamOpenResult {
	Opened(id:Int);
	Failed(message:String);
}
