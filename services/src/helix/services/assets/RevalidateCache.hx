package helix.services.assets;

import haxe.io.Bytes;
import helix.platform.IFileSystem;

/** Uses a copy without asking while the server's Cache-Control says it is fresh, and asks the server about any other copy.

	A copy is known by the server's ETag and Last-Modified. An unchanged file keeps its copy, a changed one replaces it, and a file the
	server says is gone (4xx) removes it. When the server doesn't answer, the copy is used. Nothing is hashed. */
class RevalidateCache extends AssetCache {
	final copies:KeptCopies;

	/** Creates the cache over a file system used for nothing else, which `Assets.clearCache` empties.

		@param fileSystem  Where copies are kept: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory()`, in a page a
			`BrowserFileSystemAdapter` named by it. */
	public function new(fileSystem:IFileSystem) {
		super();
		copies = new KeptCopies(fileSystem);
	}

	function decide(server:ServerSource, path:String, request:AssetRequest, decided:CacheDecision->Void):Void
		copies.decide(server, path, request, false, decided);

	function readCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, gone:Void->Void):Void
		copies.readCopy(server, path, request, record, loaded, gone);

	function locateCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, located:(String, Void->Void) -> Void, gone:Void->Void,
			failed:String->Void):Void
		copies.locateCopy(server, path, request, record, located, gone, failed);

	function keep(server:ServerSource, path:String, bytes:Bytes, record:CopyRecord, replacing:Bool, kept:Void->Void, failed:String->Void):Void
		copies.keep(server, path, bytes, record, replacing, kept, failed);

	function renew(server:ServerSource, path:String, record:CopyRecord):Void
		copies.writeRecord(server, path, record);

	function forget(server:ServerSource, path:String, forgotten:Void->Void, failed:String->Void):Void
		copies.forget(server, path, forgotten, failed);

	function clearCopies(server:ServerSource, cleared:Void->Void, failed:String->Void):Void
		copies.clearCopies(cleared, failed);
}
