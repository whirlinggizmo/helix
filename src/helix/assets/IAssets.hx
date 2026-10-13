package helix.assets;

import haxe.io.Bytes;
import helix.assets.IStorage.LocalAudio;

enum AssetResult {
	Loaded(bytes:Bytes);
	Failed(message:String);
	Cancelled;
}

enum AudioLocation {
	Stored(value:LocalAudio);
	Remote(url:String);
}

enum AssetSourceResult {
	Located(value:AudioLocation);
	Failed(message:String);
	Cancelled;
}

typedef AssetProgress = {var phase:String; var received:Int; var total:Null<Int>;}

interface IAssets {
	function load(path:String, complete:AssetResult->Void):Void;
	function ensure(path:String, complete:AssetResult->Void, ?progress:AssetProgress->Void):IRequest;
	function streamSource(path:String, complete:AssetSourceResult->Void):IRequest;

	/** Tell target when path's file changes and has loaded again (development hot reload). One target per path once. */
	function subscribe(path:String, target:IReloadable):Void;

	function unsubscribe(path:String, target:IReloadable):Void;
}
