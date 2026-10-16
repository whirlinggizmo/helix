package helix.adapters.shared;

import haxe.io.Bytes;

/** Audio files read as mono 32-bit float PCM at 44100 Hz, a part at a time: what a native output streams from, supplied by a codec adapter.
	Callable from any thread, a handle at a time. */
interface IPcmFiles {
	/** Opens the audio file at path; its handle, or 0 when it can't be read. */
	public function open(path:String):Int;

	/** Reads up to frames frames into into (4 bytes each): how many, 0 at the end, or below 0 for an error. */
	public function read(handle:Int, into:Bytes, frames:Int):Int;

	/** Goes back to the start; false when it can't. */
	public function rewind(handle:Int):Bool;

	/** Closes handle. */
	public function close(handle:Int):Void;
}
