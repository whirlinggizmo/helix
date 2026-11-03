package helix.platform;

import haxe.io.Bytes;

/** Represents a file arriving from a download, readable while it arrives.

	The downloader appends each part as it comes, and a native audio output reads what has arrived. The file's length is known, so room
	for the whole file is allocated at the start. The bytes therefore never move, and what has arrived is the first `received` of them.
	It must be used on the main thread only. */
class GrowingSource {
	/** Gets the file's bytes, `total` long. The first `received` of them have arrived, and the rest are zero. */
	public var bytes(default, null):Bytes;

	/** Gets how many bytes have arrived, 0 to `total`. */
	public var received(default, null) = 0;

	/** Gets the file's length in bytes. */
	public var total(default, null):Int;

	/** Gets a value indicating whether the whole file has arrived. */
	public var done(default, null) = false;

	/** Gets why the download failed, or null while it hasn't. Once it is set, nothing more arrives. */
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

	/** Adds a part after what has arrived.

		The source is done once the file is whole.
		@param part  The next bytes of the file.
		@return  False, adding nothing, when the part goes past the file's length or the download has ended. */
	public function append(part:Bytes):Bool {
		if (done || failure != null || part.length > total - received)
			return false;
		bytes.blit(received, part, 0, part.length);
		received += part.length;
		done = received == total;
		return true;
	}

	/** Ends the download short.

		It does nothing once the file is whole or the download has already failed.
		@param message  Why the download failed. */
	public function fail(message:String):Void
		if (!done && failure == null)
			failure = message;
}
