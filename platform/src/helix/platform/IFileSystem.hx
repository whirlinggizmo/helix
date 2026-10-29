package helix.platform;

import haxe.io.Bytes;

/** Defines files on this machine under one root, read and written whole by path: natively a directory on disk, in a page an IndexedDB
	database. A file on a server is `IHttp`'s.

	There is no listing, no directories to make, no seeking and no metadata: a file is reached by its path, read whole or located for
	streaming, and written whole or not at all. Those are a page's limits, kept natively so a program works the same on both.

	A path is plain names joined by `/` (`audio/music.ogg`): letters, digits, `_`, `-` and `.`, at most 256 characters. An absolute path,
	an empty name, `.` or `..` is refused, as `failed`. One of each call's callbacks is called once, on the main thread, never during the
	call; `missing` is a file that isn't there, `failed` anything else, with why.

	```haxe
	files.read("levels/1.json", 1 << 20, bytes -> start(bytes), () -> trace("no level 1"), why -> trace(why));
	```
 */
interface IFileSystem extends IPollable {
	/** Gets the root, as the adapter was given it: a directory, or a database's name. */
	var root(get, never):String;

	/** Gets a value indicating whether files can be written here: false when opened read-only, as over the files a program ships with. */
	var canWrite(get, never):Bool;

	/** Reads a whole file.

		@param path  The file's path under the root.
		@param maxBytes  The largest file to read; a larger one fails.
		@param loaded  Receives the file's bytes.
		@param missing  Called when there is no file at the path.
		@param failed  Receives why it can't be read.
		@return  The abort: nothing is called after it. */
	function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void;

	/** Writes a whole file, replacing what is there; a reader never sees half of it.

		@param path  The file's path under the root; the directories above it are made.
		@param bytes  The file's contents.
		@param written  Called once it is kept.
		@param failed  Receives why it can't be written: a root that can't be (`canWrite`), no room, or the platform's reason. */
	function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void;

	/** Deletes a file; deleting one that isn't there succeeds.

		@param path  The file's path under the root.
		@param deleted  Called once it is gone.
		@param failed  Receives why it can't be deleted. */
	function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void;

	/** Deletes every file under the root, for a cache.

		@param deleted  Called once they are gone.
		@param failed  Receives why they can't be deleted. */
	function deleteFiles(deleted:Void->Void, failed:String->Void):Void;

	/** Finds where a file is, for playing it as it is read, without loading it whole.

		Natively the file's path; in a page a URL the audio output plays, kept until `release` is called.
		@param path  The file's path under the root.
		@param located  Receives the location and the function that releases it, called once when it is no longer read.
		@param missing  Called when there is no file at the path.
		@param failed  Receives why it can't be located. */
	function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll; call once a frame. */
	function poll():Void;

	/** Closes the file system; what is still running finishes without answering. */
	function dispose():Void;
}
