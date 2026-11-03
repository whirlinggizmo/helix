package helix.platform.adapters.export.filesystem;

/** Represents where `FileSystemExportAdapter` writes. */
@:structInit
class FileSystemExportAdapterOptions {
	/** Gets the directory files go to, made when first needed. */
	public final directory:String;
}
