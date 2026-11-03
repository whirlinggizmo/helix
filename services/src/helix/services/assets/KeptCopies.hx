package helix.services.assets;

import haxe.Json;
import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.IFileSystem;

/** Represents the copies a server's files are kept as in a file system, each with its record, which `RevalidateCache`, `TrustCache` and
	`ManifestCache` keep their copies in.

	A server's copies are under a directory of its own: the bytes at `files/<path>`, the record at `records/<path>`. The pair is kept in an
	order that never leaves a record beside bytes it doesn't describe: a replacement deletes the old record, writes the bytes, then writes
	the record; a removal deletes the record, then the bytes. A copy is read only with its record, and only when it has the record's byte
	count; otherwise both are deleted and the file is downloaded again. */
@:noCompletion
@:allow(helix.services.assets)
class KeptCopies {
	/** Gets the file system the copies are kept in. */
	public final fileSystem:IFileSystem;

	/** Creates the copies over a file system used for nothing else. */
	public function new(fileSystem:IFileSystem) {
		this.fileSystem = fileSystem;
	}

	/** Decides as `RevalidateCache` does, or as `TrustCache` does when trusted: a copy used while fresh (or always, trusted), asked about
		otherwise, and downloaded when there's none. */
	function decide(server:ServerSource, path:String, request:AssetRequest, trusted:Bool, decided:CacheDecision->Void):Void
		readRecord(server, path, request,
			(record,
					there) -> decided(if (record == null) Download(null, null,
					there) else if (trusted
					|| Date.now().getTime() / 1000 < record.freshUntil) UseCopy(record) else Download(record, null, true)));

	/** Reads a copy's record: null when there's none, or one that doesn't read as a record (an older shape, or a file edited by hand);
		there tells whether a file was at its path. */
	function readRecord(server:ServerSource, path:String, request:AssetRequest, read:(record:Null<CopyRecord>, there:Bool) -> Void):Void {
		request.cancel = fileSystem.read(recordPath(server, path), 1 << 16, bytes -> {
			if (request.aborted)
				return;
			var value:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
			var valid = value != null
				&& Std.isOfType(value.size, Int)
				&& value.size >= 0
				&& Std.isOfType(value.freshUntil, Float)
				&& (value.label == null || Std.isOfType(value.label, String))
				&& (value.etag == null || Std.isOfType(value.etag, String))
				&& (value.lastModified == null || Std.isOfType(value.lastModified, String));
			read(valid ? value : null, true);
		}, () -> if (!request.aborted) read(null, false),
			_ -> if (!request.aborted) read(null, true));
	}

	function readCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, gone:Void->Void):Void {
		function lost()
			forget(server, path, () -> if (!request.aborted) gone(), _ -> if (!request.aborted) gone());
		request.cancel = fileSystem.read(filePath(server, path), AssetSource.MAX_BYTES, bytes -> if (!request.aborted) {
			if (bytes.length == record.size)
				loaded(bytes);
			else
				lost();
		}, () -> if (!request.aborted) lost(), _ -> if (!request.aborted) lost());
	}

	function locateCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, located:(String, Void->Void) -> Void, gone:Void->Void,
			failed:String->Void):Void {
		function lost()
			forget(server, path, () -> if (!request.aborted) gone(), _ -> if (!request.aborted) gone());
		var file = filePath(server, path);
		fileSystem.getInfo(file, (size, _) -> {
			if (request.aborted)
				return;
			if (size != record.size) {
				lost();
				return;
			}
			fileSystem.locate(file, (location, release) -> {
				if (request.aborted)
					release();
				else
					located(location, release);
			}, () -> if (!request.aborted) lost(),
				message -> if (!request.aborted) failed(message));
		}, () -> if (!request.aborted) lost(),
			message -> if (!request.aborted) failed(message));
	}

	function keep(server:ServerSource, path:String, bytes:Bytes, record:CopyRecord, replacing:Bool, kept:Void->Void, failed:String->Void):Void {
		function write()
			fileSystem.write(filePath(server, path), bytes, () -> {
				writeRecord(server, path, record);
				kept();
			}, failed);
		if (replacing)
			fileSystem.deleteFile(recordPath(server, path), write, failed);
		else
			write();
	}

	function writeRecord(server:ServerSource, path:String, record:CopyRecord):Void
		fileSystem.write(recordPath(server, path), Bytes.ofString(Json.stringify(record)), () -> {},
			message -> Log.warn('$path\'s record can\'t be kept: $message', "assets"));

	function forget(server:ServerSource, path:String, forgotten:Void->Void, failed:String->Void):Void
		fileSystem.deleteFile(recordPath(server, path), () -> fileSystem.deleteFile(filePath(server, path), forgotten, failed), failed);

	/** Deletes every copy under a directory of the server's files, and their records, records first. */
	function forgetUnder(server:ServerSource, directory:String, forgotten:Void->Void):Void
		deleteUnder('${server.directory}/records/$directory', () -> deleteUnder('${server.directory}/files/$directory', forgotten));

	// Every file under a directory deleted, its subdirectories' too.
	function deleteUnder(directory:String, deleted:Void->Void):Void
		fileSystem.list(directory, names -> {
			var left = names.length + 1;
			function one()
				if (--left == 0)
					deleted();
			for (name in names)
				if (StringTools.endsWith(name, "/"))
					deleteUnder(directory + "/" + name.substr(0, name.length - 1), one);
				else
					fileSystem.deleteFile(directory + "/" + name, one, _ -> one());
			one();
		}, deleted, _ -> deleted());

	function clearCopies(cleared:Void->Void, failed:String->Void):Void
		fileSystem.deleteFiles(cleared, failed);

	static function recordPath(server:ServerSource, path:String):String
		return '${server.directory}/records/$path';

	static function filePath(server:ServerSource, path:String):String
		return '${server.directory}/files/$path';
}
