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

	/** Loads a whole file: loaded receives it, missing is called when this source hasn't it, failed receives why it can't be read. */
	abstract function load(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void;

	/** Brings a file in again because it changed, past every cache, keeping the new copy in the old's place; as load answers. */
	abstract function refetch(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void;

	/** Finds a file to be played as it is read; as load answers, located receiving the source and its release. */
	abstract function locate(path:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void;

	/** Returns the path of a file this source serves at a URL, or null for a URL it doesn't. */
	function pathOf(url:String):Null<String>
		return null;

	/** Returns the last bytes of a stream of this source's downloading in two parts, or null. */
	function tailOf(source:GrowingSource):Null<Bytes>
		return null;

	/** Empties the copies this source keeps; cleared is called once they are gone, or at once when it keeps none. */
	function clearCache(cleared:Void->Void, failed:String->Void):Void
		cleared();

	/** Deletes the copy this source keeps of a file; deleted is called once it is gone, or at once when it keeps none. */
	function deleteCopy(path:String, deleted:Void->Void, failed:String->Void):Void
		deleted();
}
