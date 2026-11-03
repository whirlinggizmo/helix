package helix.platform.adapters.export.filesystem;

import haxe.io.Bytes;
import haxe.io.Path;
import helix.platform.IExport;
import helix.platform.adapters.shared.AtomicFile;

/** Provides `IExport` natively: the file is written into a directory, made when first needed, whole or not at all (`AtomicFile`). */
class FileSystemExportAdapter implements IExport {
	var directory:String;

	/** Creates the adapter.

		@param options  The directory files go to. */
	public function new(options:FileSystemExportAdapterOptions)
		directory = options.directory;

	public function export(name:String, mimeType:String, bytes:Bytes, exported:(where:String) -> Void, failed:String->Void):Void {
		if (name == "" || name.indexOf("/") >= 0 || name.indexOf("\\") >= 0 || name.charAt(0) == ".")
			throw "Invalid export name";
		var path = Path.join([directory, name]);
		try
			AtomicFile.write(path, bytes)
		catch (error:Dynamic) {
			failed(Std.string(error));
			return;
		}
		exported(path);
	}
}
