package helix.platform;

import haxe.io.Bytes;

/** Represents a file arriving from a download, readable while it arrives.

	The downloader appends each part as it comes; a native audio output reads what has arrived. The whole file's room is taken at the start,
	since its length is known, so the bytes never move and what has arrived is the first `received` of them. Use it on the main thread only. */
class GrowingSource {
	/** Gets the file's bytes, `total` long: the first `received` of them have arrived, the rest are zero. */
	public var bytes(default, null):Bytes;

	/** Gets how many bytes have arrived, 0 to `total`. */
	public var received(default, null) = 0;

	/** Gets the file's length in bytes. */
	public var total(default, null):Int;

	/** Gets a value indicating whether the whole file has arrived. */
	public var done(default, null) = false;

	/** Gets why the download failed, or null while it hasn't; once set, no more arrives. */
	public var failure(default, null):Null<String> = null;

	/** Creates a source with none of its bytes arrived yet.

		@param total  The file's length in bytes, 0 or more. */
	public function new(total:Int) {
		this.total = total;
		bytes = Bytes.alloc(total);
		done = total == 0;
	}

	/** Returns a source with the whole of a file arrived.

		@param bytes  The file.
		@return  The source, done. */
	public static function of(bytes:Bytes):GrowingSource {
		var source = new GrowingSource(0);
		source.bytes = bytes;
		source.total = source.received = bytes.length;
		source.done = true;
		return source;
	}

	/** Adds a part after what has arrived; the source is done once the file is whole.

		@param part  The next bytes of the file.
		@return  False, adding nothing, past the file's length or once the download ended. */
	public function append(part:Bytes):Bool {
		if (done || failure != null || part.length > total - received)
			return false;
		bytes.blit(received, part, 0, part.length);
		received += part.length;
		done = received == total;
		return true;
	}

	/** Ends the download short; does nothing once the file is whole or already failed.

		@param message  Why it failed. */
	public function fail(message:String):Void
		if (!done && failure == null)
			failure = message;
}
