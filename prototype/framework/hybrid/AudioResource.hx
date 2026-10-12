package hybrid;
/** One owner plus active playback references. release() drops the owner's reference. */
class AudioResource {
 public var id(default,null):Int;public var backend(default,null):IAudio;
 public var disposed(default,null)=false;var references=1;var ownerReleased=false;var destroy:Void->Void;
 public function new(id:Int,backend:IAudio,destroy:Void->Void){this.id=id;this.backend=backend;this.destroy=destroy;}
 public function retainPlayback():Void {if(ownerReleased)throw "Released audio resource";references++;}
 public function releasePlayback():Void {references--;if(references==0){disposed=true;destroy();}}
 public function release():Void {if(!ownerReleased){ownerReleased=true;releasePlayback();}}
}
