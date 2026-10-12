package helix.audio;

/** One active/paused playback; holds its resource until stopped or naturally finished. */
class AudioPlayback {
 public var id(default,null):Int;public var finished(default,null)=false;var resource:AudioResource;
 public function new(id:Int,resource:AudioResource){this.id=id;this.resource=resource;if(id==0)end();}
 function end():Void {if(!finished){finished=true;resource.releasePlayback();}}
 public function stop():Void {if(!finished){resource.backend.stop(id);end();}}
 public function pause(paused=true):Void {if(!finished)resource.backend.pause(id,paused);}
 public function setVolume(volume:Float):Void {if(!finished)resource.backend.setVolume(id,volume);}
 public function poll():Void {if(!finished&&!resource.backend.isPlaying(id))end();}
}
