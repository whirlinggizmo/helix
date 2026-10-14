package helix.adapters.audiodecoder.libsndfile;

import haxe.io.Bytes;
import helix.adapters.audiodecoder.libsndfile.internal.CodecBridge;
import helix.adapters.internal.IPcmFiles;

/** Audio files natively over libsndfile (WAV, Ogg Vorbis and Opus, MP3), read as mono at 44100 Hz for a native output to stream. */
class LibsndfileFiles implements IPcmFiles {
	/** libsndfile's files. */
	public function new() {}

	public function open(path:String):Int
		return CodecBridge.codecFile(path);

	public function read(handle:Int, into:Bytes, frames:Int):Int
		return CodecBridge.codecRead(handle, cpp.Pointer.arrayElem(into.getData(), 0).raw, frames);

	public function rewind(handle:Int):Bool
		return CodecBridge.codecRewind(handle) == 1;

	public function close(handle:Int):Void
		CodecBridge.codecClose(handle);
}
