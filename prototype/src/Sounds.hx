import hybrid.AudioResources;
import hybrid.AudioClip;
import hybrid.AudioPlayback;
import hybrid.AudioResources.AudioLoadResult;
class Sounds {
 public static final names=["start","fire","bang_large","bang_medium","bang_small","extra_life","game_over","thrust"];
 public var loaded(default,null)=0;var clips:Array<AudioClip>=[for(_ in 0...8) null];var audio:AudioResources;var loop:AudioPlayback;var closed=false;
 public function new(audio:AudioResources,complete:Null<String>->Void){
  this.audio=audio;
  for(i in 0...names.length){var index=i;audio.loadClip("sounds/"+names[i]+".ogg",result->{
   switch(result){
    case Ready(resource):if(closed){resource.release();return;}clips[index]=resource;loaded++;if(loaded==8)complete(null);
    case Failed(message):if(!closed){cleanup();complete(message);}
    case Cancelled:
   }
  });}
 }
 public function play(game:Game,enabled:Bool,focused:Bool=true):Void {
  if(enabled&&focused)for(kind in game.sounds)audio.play(clips[kind],false,kind==1 ? 0.5 : 0.75);
  var thrust=enabled&&focused&&game.state=="playing"&&game.thrusting&&game.respawnDelay==0;
  if(thrust&&(loop==null||loop.finished))loop=audio.play(clips[7],true,.45);else if(!thrust&&loop!=null){loop.stop();loop=null;}
 }
 public function cleanup():Void {if(closed)return;closed=true;if(loop!=null)loop.stop();loop=null;for(clip in clips)if(clip!=null)clip.release();}
}
