package helix.audio;
import helix.assets.IRequest;
import haxe.io.Bytes;
import helix.assets.IAssets.AudioLocation;
enum StreamResult {Created(id:Int);Failed(message:String);Cancelled;}
enum ClipDecodeResult {Decoded(samples:Bytes);Failed(message:String);Cancelled;}
/** Adapter-level IDs. Public resource/playback lifetime lives in AudioResources. */
interface IAudio {
 function decodeClip(encoded:Bytes,complete:ClipDecodeResult->Void):IRequest;
 function createClip(samples:Bytes):Int;
 function createStream(source:AudioLocation,complete:StreamResult->Void):IRequest;
 function play(resource:Int,loop:Bool=false,volume:Float=1):Int;
 function stop(playback:Int):Void;
 function pause(playback:Int,paused:Bool):Void;
 function setVolume(playback:Int,volume:Float):Void;
 function isPlaying(playback:Int):Bool;
 function destroyClip(clip:Int):Void;
 function destroyStream(stream:Int):Void;
 function poll():Void;
 function shutdown():Void;
}
