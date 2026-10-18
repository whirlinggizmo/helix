package helix.adapters.audiodecoder.libsndfile;

import haxe.io.Bytes;
import helix.adapters.audiodecoder.libsndfile.internal.CodecBridge;
import helix.adapters.shared.IPcmFiles;
import helix.assets.GrowingSource;

/** Audio files natively over libsndfile (WAV, Ogg Vorbis and Opus, MP3), read as mono at 44100 Hz for a native output to stream. A download is
	copied into the codec's memory (a file's length taken at its open), the rest of it as it arrives, at each read; the C reads it through
	libsndfile's virtual I/O. An Ogg file opened before its end plays to the end of its stream (libsndfile can't learn its length without its
	last bytes); an MP3 without a Xing or Info header opens only once whole (libsndfile scans it for its length). */
class LibsndfilePcmFiles implements IPcmFiles {
	// The downloads' handles: each one's source, and how much of it the codec has; under lock, as a stored file's handle may be closed on another thread.
	var arriving:Map<Int, {source:GrowingSource, copied:Int}> = [];
	var lock = new sys.thread.Mutex();

	/** libsndfile's files. */
	public function new() {}

	public function open(path:String):Int
		return CodecBridge.codecFile(path);

	public function openArriving(source:GrowingSource):Int {
		if (source.received == 0)
			return 0;
		var handle = CodecBridge.codecArriving(cpp.Pointer.arrayElem(source.bytes.getData(), 0).raw, source.received, source.total);
		if (handle != 0) {
			lock.acquire();
			arriving[handle] = {source: source, copied: source.received};
			lock.release();
		}
		return handle;
	}

	public function position(handle:Int):Int
		return CodecBridge.codecPosition(handle);

	public function read(handle:Int, into:Bytes, frames:Int):Int {
		lock.acquire();
		var download = arriving[handle];
		lock.release();
		if (download != null && download.copied < download.source.received) {
			var source = download.source;
			CodecBridge.codecArrive(handle, cpp.Pointer.arrayElem(source.bytes.getData(), download.copied).raw, source.received - download.copied);
			download.copied = source.received;
		}
		return CodecBridge.codecRead(handle, cpp.Pointer.arrayElem(into.getData(), 0).raw, frames);
	}

	public function rewind(handle:Int):Bool
		return CodecBridge.codecRewind(handle) == 1;

	public function close(handle:Int):Void {
		lock.acquire();
		arriving.remove(handle);
		lock.release();
		CodecBridge.codecClose(handle);
	}
}
