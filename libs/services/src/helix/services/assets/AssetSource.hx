package helix.services.assets;

import haxe.io.Bytes;
import helix.platform.GrowingSource;
import helix.platform.StreamSource;

/** Specifies a place `Assets` finds files. Construct a `FileSystemSource` or a `ServerSource`. */
@:allow(helix.services.assets)
abstract class AssetSource {
	/** The largest file read whole. */
	static inline final MAX_BYTES = 1 << 30;

	/** Creates the source, as one of its kinds. */
	function new() {}

	/** Returns where this source reads a path from: the path, its `.` and `..` followed by the rules of this source's root, joined to
		the root when it is relative, or as it is when it is absolute and under the root.

		@param path  The path as passed to `Assets`.
		@return  The location, or null when the path is not under this source's root. */
	public function resolve(path:String):Null<String> {
		var name = nameOf(path);
		return name == null ? null : locationOf(name);
	}

	/** Gets a value indicating whether `Assets.write` writes to this source. */
	public var writable(get, never):Bool;

	function get_writable():Bool
		return false;

	/** Returns a path's name under the root, its `.` and `..` followed: "" for the root itself, or null when it isn't under the root. */
	abstract function nameOf(path:String):Null<String>;

	/** Returns where a name under the root is: the root joined to it. */
	abstract function locationOf(name:String):String;

	/** Reads a whole file: loaded receives it, missing is called when this source hasn't it, failed receives why it can't be read. */
	abstract function read(name:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void;

	/** Brings a file in again because it changed, past every cache, keeping the new copy in the old's place; as read answers. */
	abstract function refetch(name:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void;

	/** Finds a file to be played as it is read; as read answers, located receiving the source and its release. */
	abstract function locate(name:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void;

	/** Writes a whole file, when the source is writable: written is called once it is written, failed receives why it can't be. */
	function write(name:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		failed("the asset source isn't writable");

	/** Lists a directory's files and subdirectories, none when it isn't there; the path as passed is the request's. */
	function list(name:String, request:AssetRequest, listed:Array<String>->Void, failed:String->Void):Void
		listed([]);

	/** Lists the names of the copies this source's cache keeps under a directory, its subdirectories' too; none when it keeps none. */
	function listCopies(name:String, request:AssetRequest, listed:Array<String>->Void, failed:String->Void):Void
		listed([]);

	/** Returns the last bytes of a stream of this source's downloading in two parts, or null. */
	function tailOf(source:GrowingSource):Null<Bytes>
		return null;

	/** Empties the copies this source keeps; cleared is called once they are gone, or at once when it keeps none. */
	function clearCache(cleared:Void->Void, failed:String->Void):Void
		cleared();

	/** Deletes the copy this source keeps of a file; deleted is called once it is gone, or at once when it keeps none. */
	function deleteCopy(name:String, deleted:Void->Void, failed:String->Void):Void
		deleted();

	/** Returns a relative path with its `.` and `..` followed and its empty names dropped: "" when it names the root, or null when it
		climbs above it. */
	static function follow(path:String):Null<String> {
		var names = [];
		for (name in path.split("/"))
			if (name == "..") {
				if (names.length == 0)
					return null;
				names.pop();
			} else if (name != "" && name != ".")
				names.push(name);
		return names.join("/");
	}
}
