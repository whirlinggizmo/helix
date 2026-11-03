package helix.services.assets;

import haxe.io.Bytes;
import helix.platform.IFileSystem;
import helix.platform.StreamSource;

/** Reads files as they are from a file system.

	Natively this is usually the files the program ships with, a read-only `NativeFileSystemAdapter` over
	`ISystem.getProgramDirectory()`. Its files are never checked: they are what shipped. */
class FileSystemSource extends AssetSource {
	final fileSystem:IFileSystem;

	/** Creates the source over a file system.

		@param fileSystem  The file system the files are read from. */
	public function new(fileSystem:IFileSystem) {
		super();
		this.fileSystem = fileSystem;
	}

	function load(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		request.cancel = fileSystem.read(path, AssetSource.MAX_BYTES, bytes -> if (!request.aborted) loaded(bytes), () -> request.next(missing),
			message -> request.next(() -> failed(message)));

	function refetch(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		load(path, request, loaded, missing, failed);

	function locate(path:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		fileSystem.locate(path, (location, release) -> {
			if (request.aborted)
				release();
			else
				located(Local(location), release);
		}, () -> request.next(missing), message -> request.next(() -> failed(message)));
}
