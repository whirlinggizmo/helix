package helix.assets;

import haxe.io.Bytes;
typedef FetchRequest={var url:String;@:optional var maxBytes:Int;@:optional var timeoutSeconds:Float;@:optional var noCache:Bool;}
typedef FetchProgress={var received:Int;var total:Null<Int>;}
typedef FetchResponse={var status:Int;var headers:Map<String,String>;var bytes:Bytes;}
enum FetchResult {Response(value:FetchResponse);Failed(message:String);Cancelled;}
/** Bounded whole-response GET, incrementally read. Progress/completion on host thread.
    HTTP error status is a response, not a transport failure. */
interface IFetch {
 function fetch(request:FetchRequest,complete:FetchResult->Void,?progress:FetchProgress->Void):IRequest;
 function poll():Void;
 function shutdown():Void;
}
