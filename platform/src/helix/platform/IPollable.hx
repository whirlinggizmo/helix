package helix.platform;

/** Defines a contract that answers later: what it was asked for is delivered in its `poll`, on the main thread, and at no other time.

	The program calls `poll` once a frame on each one it made; one it forgets never answers. `IEvents`, `IHttp`, `IFileSystem`, `IAudio`,
	`IAudioDecoder` and `IImageDecoder` are pollable; a layer above that answers later is too, polled the same way. */
interface IPollable {
	/** Delivers what finished since the last poll; call once a frame. */
	function poll():Void;
}
