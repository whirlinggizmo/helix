package helix.adapter.shared;

import haxe.io.Bytes;
import helix.asset.GrowingSource;

/** Audio files read as mono 32-bit float PCM at 44100 Hz, a part at a time: what a native output streams from, supplied by a codec adapter.
	Callable from any thread, a handle at a time; a download's (openArriving) from the host thread only, as its source is written there. */
interface IPcmFiles {
	/** Opens the audio file at path; its handle, or 0 when it can't be read. */
	public function open(path:String):Int;

	/** Opens the audio file arriving in source from what has arrived of it; its handle, or 0 when it can't be read from that (ask again once
		more has arrived: a codec may need more of a file to open it, or all of it). What arrives later reaches the handle as it reads; a read
		past what has arrived takes it as the file's end, so the caller reads only while the download is ahead of position. */
	public function openArriving(source:GrowingSource):Int;

	/** How far into its file handle's decoder has read, in bytes. */
	public function position(handle:Int):Int;

	/** Reads up to frames frames into into (4 bytes each): how many, 0 at the end, or below 0 for an error. */
	public function read(handle:Int, into:Bytes, frames:Int):Int;

	/** Goes back to the start; false when it can't. */
	public function rewind(handle:Int):Bool;

	/** Closes handle. */
	public function close(handle:Int):Void;
}
