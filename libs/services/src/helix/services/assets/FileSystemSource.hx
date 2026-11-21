package helix.services.assets;

import haxe.io.Bytes;
import helix.platform.IFileSystem;
import helix.platform.StreamSource;

/** Reads files as they are from a file system, and writes them there when it is writable.

	Natively the shipped files are usually a read-only `NativeFileSystemAdapter` over `ISystem.getProgramDirectory()`. Its files are
	never checked: they are what shipped. A game's own files are a `NativeFileSystemAdapter` over `ISystem.getDataDirectory()`, made
	writable, or in a page a `BrowserFileSystemAdapter` named for it.

	Its root is the file system's (`IFileSystem.root`). Natively, when the root is a directory, a path is read as a directory path: `\`
	is a separator on Windows, where a drive letter's case is ignored, and `..` climbs a directory. A page's database stores names alone:
	a relative path's `.` and `..` are followed, and an absolute path is not under any database's root.

	A link under the root is followed: a file reached through it is read and written, even when it is outside the root. */
class FileSystemSource extends AssetSource {
	final fileSystem:IFileSystem;
	final canWrite:Bool;
	#if sys
	// The root as an absolute directory path, `/` between its names, a drive letter in lower case; found when first needed.
	var directory:Null<String> = null;
	#end

	/** Creates the source over a file system.

		@param fileSystem  The file system the files are read from.
		@param writable  Optional, false by default. Whether `Assets.write` writes files to it. */
	public function new(fileSystem:IFileSystem, writable = false) {
		super();
		this.fileSystem = fileSystem;
		canWrite = writable;
	}

	override function get_writable():Bool
		return canWrite;

	function nameOf(path:String):Null<String> {
		if (path.indexOf("://") >= 0)
			return null;
		#if sys
		var windows = Sys.systemName() == "Windows";
		if (windows)
			path = StringTools.replace(path, "\\", "/");
		if (StringTools.startsWith(path, "/") || windows && ~/^[A-Za-z]:\//.match(path)) {
			var full = absolute(path), root = getDirectory();
			if (full == null)
				return null;
			if (full == root)
				return "";
			var under = StringTools.endsWith(root, "/") ? root : root + "/";
			return StringTools.startsWith(full, under) ? full.substr(under.length) : null;
		}
		#else
		if (StringTools.startsWith(path, "/"))
			return null;
		#end
		return AssetSource.follow(path);
	}

	function locationOf(name:String):String {
		#if sys
		var root = getDirectory();
		#else
		var root = fileSystem.root;
		#end
		return name == "" ? root : StringTools.endsWith(root, "/") ? root + name : root + "/" + name;
	}

	#if sys
	function getDirectory():String {
		if (directory == null) {
			var root = sys.FileSystem.absolutePath(fileSystem.root);
			if (Sys.systemName() == "Windows")
				root = StringTools.replace(root, "\\", "/");
			directory = absolute(root);
		}
		return directory;
	}

	// An absolute path with `/` between its names, its `.` and `..` followed, a drive letter in lower case; null when it climbs above its
	// drive or the file system's root.
	static function absolute(path:String):Null<String> {
		var drive = ~/^[A-Za-z]:/.match(path) ? path.substr(0, 2).toLowerCase() : "";
		var names = AssetSource.follow(path.substr(drive.length));
		return names == null ? null : drive + "/" + names;
	}
	#end

	function read(name:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		request.cancel = fileSystem.read(name, AssetSource.MAX_BYTES, bytes -> if (!request.aborted) loaded(bytes), () -> request.next(missing),
			message -> request.next(() -> failed(message)));

	function refetch(name:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		read(name, request, loaded, missing, failed);

	function locate(name:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		fileSystem.locate(name, (location, release) -> {
			if (request.aborted)
				release();
			else
				located(Local(location), release);
		}, () -> request.next(missing), message -> request.next(() -> failed(message)));

	override function write(name:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		fileSystem.write(name, bytes, written, failed);

	override function list(name:String, request:AssetRequest, listed:Array<String>->Void, failed:String->Void):Void
		fileSystem.list(name, listed, () -> listed([]), failed);
}
