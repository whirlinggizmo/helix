package helix.assets;

import haxe.io.Bytes;

enum StorageResult {
	Stored(bytes:Bytes);
	Missing;
	Failed(message:String);
	Cancelled;
}

enum StorageWriteResult {
	Written;
	Failed(message:String);
	Cancelled;
}

typedef LocalAudio = {var location:String; var release:Void->Void;}

enum StorageSourceResult {
	Local(value:LocalAudio);
	Missing;
	Failed(message:String);
	Cancelled;
}

/** App cache; local audio leases avoid a second network transfer. */
interface IStorage {
	function read(path:String, complete:StorageResult->Void):IRequest;
	function write(path:String, bytes:Bytes, complete:StorageWriteResult->Void):IRequest;
	function remove(path:String, complete:StorageWriteResult->Void):IRequest;
	function source(path:String, complete:StorageSourceResult->Void):IRequest;
	function poll():Void;
	function shutdown():Void;
}
