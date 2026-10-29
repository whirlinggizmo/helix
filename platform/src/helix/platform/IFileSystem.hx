package helix.platform;

import haxe.io.Bytes;

/** Defines files on this machine under one root, read and written whole by path.

	Natively the root is a directory on disk. In a page it is an IndexedDB database. A file on a server is read through `IHttp` instead.

	There is no listing, no making directories, no seeking and no metadata. A file is reached by its path. It is read whole or located for
	streaming, and written whole or not at all. These are a page's limits, kept natively so a program works the same on both.

	A path is plain names joined by `/`, such as `audio/music.ogg`. Names use letters, digits, `_`, `-` and `.`, and the path is at most
	256 characters. An absolute path, an empty name, `.` or `..` is refused through `failed`.

	One of each call's callbacks is called once, on the main thread, never during the call. `missing` is called when the file isn't there,
	and `failed` receives why for anything else.

	```haxe
	files.read("levels/1.json", 1 << 20, bytes -> start(bytes), () -> trace("no level 1"), why -> trace(why));
	```
 */
interface IFileSystem extends IPollable {
	/** Gets the root as the adapter received it, which is a directory or a database's name. */
	var root(get, never):String;

	/** Gets a value indicating whether files can be written here.

		It is false when the file system was opened read-only, as over the files a program ships with. */
	var canWrite(get, never):Bool;

	/** Reads a whole file.

		@param path  The file's path under the root.
		@param maxBytes  The largest file to read; a larger one fails.
		@param loaded  Receives the file's bytes.
		@param missing  Called when there is no file at the path.
		@param failed  Receives why it can't be read.
		@return  The abort: nothing is called after it. */
	function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void;

	/** Writes a whole file, replacing what is there.

		A reader never sees half of it. The directories above the file are made.
		@param path  The file's path under the root.
		@param bytes  The file's contents.
		@param written  Called once the file is kept.
		@param failed  Receives why the file can't be written: a root that can't be written (`canWrite`), no room, or the platform's
			reason. */
	function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void;

	/** Deletes a file.

		Deleting a file that isn't there succeeds.
		@param path  The file's path under the root.
		@param deleted  Called once the file is gone.
		@param failed  Receives why the file can't be deleted. */
	function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void;

	/** Deletes every file under the root, as when clearing a cache.

		@param deleted  Called once the files are gone.
		@param failed  Receives why the files can't be deleted. */
	function deleteFiles(deleted:Void->Void, failed:String->Void):Void;

	/** Finds where a file is, so it can be played as it is read without loading it whole.

		Natively the location is the file's path. In a page it is a URL the audio output plays, kept until `release` is called.
		@param path  The file's path under the root.
		@param located  Receives the location and a function that releases it. That function is called once, when the location is no
			longer read.
		@param missing  Called when there is no file at the path.
		@param failed  Receives why it can't be located. */
	function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the file system. What is still running finishes without calling back. */
	function dispose():Void;
}
