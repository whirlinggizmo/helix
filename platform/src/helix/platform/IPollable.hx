package helix.platform;

/** Defines a contract that answers later, delivering what it was asked for in its `poll` on the main thread and at no other time.

	The program calls `poll` once a frame on each pollable it made. One it forgets to poll never answers. A service never polls the
	pollables it was provided, so one built over an `IFileSystem` or an `IAudio` leaves their polls to the program.

	`IEvents`, `IHttp`, `IFileSystem`, `IAudio`, `IAudioDecoder` and `IImageDecoder` are pollable. A layer above them that answers later
	is pollable too, and is polled the same way. */
interface IPollable {
	/** Delivers what finished since the last poll. The program calls it once a frame. */
	function poll():Void;
}
