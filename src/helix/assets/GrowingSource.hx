package helix.assets;

import haxe.io.Bytes;

/** A file arriving from the host, readable while it downloads: the asset service writes each part as it comes (AudioLocation.Downloading), a
	native output's decoder reads what has arrived. The whole file's room is taken at the start (its length is known), so the bytes never move
	and what has arrived is the first received of them. Host thread only: the service writes from the fetch's parts, which arrive there, and the
	reader copies from it there. */
class GrowingSource {
	/** The file's bytes, total long: the first received of them have arrived, the rest are zero. */
	public var bytes(default, null):Bytes;

	/** How many bytes have arrived, 0 to total. */
	public var received(default, null) = 0;

	/** The file's length in bytes (the response's Content-Length). */
	public var total(default, null):Int;

	/** Whether the whole file has arrived. */
	public var done(default, null) = false;

	/** Why the download failed, or null while it hasn't: then no more will arrive. */
	public var failure(default, null):Null<String> = null;

	/** A file of total bytes (at least 0), none arrived yet. */
	public function new(total:Int) {
		this.total = total;
		bytes = Bytes.alloc(total);
		done = total == 0;
	}

	/** A source with the whole of bytes arrived. */
	public static function of(bytes:Bytes):GrowingSource {
		var source = new GrowingSource(0);
		source.bytes = bytes;
		source.total = source.received = bytes.length;
		source.done = true;
		return source;
	}

	/** Adds part after what has arrived; done once the file is whole. False, adding nothing, past the file's length or once it ended. */
	@:allow(helix.assets.AssetService)
	function append(part:Bytes):Bool {
		if (done || failure != null || part.length > total - received)
			return false;
		bytes.blit(received, part, 0, part.length);
		received += part.length;
		done = received == total;
		return true;
	}

	/** Ends the download short, for message; nothing once the file is whole. */
	@:allow(helix.assets.AssetService)
	function fail(message:String):Void
		if (!done && failure == null)
			failure = message;
}
