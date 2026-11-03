package helix.platform.adapters.filesystem.native;

/** Represents the directory `NativeFileSystemAdapter` holds and how. */
@:structInit
class NativeFileSystemAdapterOptions {
	/** Gets the directory, made when first written. */
	public final directory:String;

	/** Gets a value indicating whether writing, removing and clearing are refused, as for the files a program ships with; false by
		default. */
	public final readOnly:Bool = false;
}
