package helix.audio;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.assets.IAssets;
import helix.audio.IAudio;
import helix.assets.IReloadable;
enum AudioLoadResult<T> {Ready(resource:T);Failed(message:String);Cancelled;}
/** Shared audio loading/policy/lifetime; adapters own decoding and delivery mechanisms. */
class AudioResources implements IReloadable {
 var assets:IAssets;var backend:IAudio;var playbacks:Array<AudioPlayback>=[];var resources:Array<AudioResource>=[];var requests:Array<IRequest>=[];var queue=new WorkQueue();var live=true;
 /** Backend clips a reload replaced, destroyed once nothing started from them still plays. */
 var retired:Array<Int>=[];
 public function new(assets:IAssets,backend:IAudio){this.assets=assets;this.backend=backend;}
 public function loadClip(path:String,complete:AudioLoadResult<AudioClip>->Void):IRequest {
  var child:IRequest=null,request:Request=null;
  function finish(result:AudioLoadResult<AudioClip>){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}else switch result {case Ready(resource):resource.release();case _:}}
  request=new Request(()->{if(child!=null)child.cancel();requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  if(!live){queue.add(()->finish(Failed("Closed audio resource service")));return request;}
  child=assets.ensure(path,result->{if(request.isSettled())return;switch result {
   case Loaded(bytes):child=backend.decodeClip(bytes,result->{if(request.isSettled())return;switch result {
    case Decoded(samples):try {var resource=new AudioClip(backend.createClip(samples),backend,path);resources.push(resource);assets.subscribe(path,this);finish(Ready(resource));}catch(error:Dynamic)finish(Failed(Std.string(error)));
    case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);
   }});
   case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);
  }});return request;
 }
 public function loadStream(path:String,complete:AudioLoadResult<AudioStream>->Void):IRequest {
  var child:IRequest=null,request:Request=null;
  function finish(result:AudioLoadResult<AudioStream>){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}else switch result {case Ready(resource):resource.release();case _:}}
  request=new Request(()->{if(child!=null)child.cancel();requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  if(!live){queue.add(()->finish(Failed("Closed audio resource service")));return request;}
  child=assets.streamSource(path,result->{if(request.isSettled()){switch result {case Located(Stored(value)):value.release();case _:}return;}switch result {
   case Located(source):
    var release=switch source {case Stored(value):value.release;case Remote(_):()->{};}
    child=backend.createStream(source,result->switch result {
     case Created(id):var resource=new AudioStream(id,backend,release);resources.push(resource);finish(Ready(resource));
     case Failed(message):release();finish(Failed(message));case Cancelled:release();finish(Cancelled);
    });
   case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);
  }});return request;
 }
 public function play(resource:AudioResource,loop=false,volume=1.):AudioPlayback {
  if(!live||resource.getBackend()!=backend)throw "Invalid audio resource service";
  resource.retainPlayback();var id:Int;
  try {id=backend.play(resource.id,loop,volume);}catch(error:Dynamic){resource.releasePlayback();throw error;}
  var playback=new AudioPlayback(id,resource);if(!playback.isFinished())playbacks.push(playback);return playback;
 }
 /** A clip's file changed: decode it, then give each clip from that path a new backend clip in place. */
 public function reloaded(path:String,bytes:haxe.io.Bytes):Void {
  if(!live)return;
  backend.decodeClip(bytes,result->switch result {
   case Decoded(samples):
    for(resource in resources)if(!resource.isDisposed()&&Std.isOfType(resource,AudioClip)&&(cast resource:AudioClip).getPath()==path){retired.push(resource.id);resource.id=backend.createClip(samples);}
   case Failed(message):throw 'Reloaded clip failed to decode: '+path+': '+message;
   case Cancelled:
  });
 }
 public function poll():Void {backend.poll();
  for(id in retired.copy())if(!Lambda.exists(playbacks,p->!p.isFinished()&&p.getSource()==id)){retired.remove(id);backend.destroyClip(id);}resources=[for(resource in resources)if(!resource.isDisposed())resource];for(playback in playbacks.copy()){playback.poll();if(playback.isFinished())playbacks.remove(playback);}queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();for(playback in playbacks)playback.stop();playbacks=[];for(resource in resources)resource.release();resources=[];for(id in retired)backend.destroyClip(id);retired=[];queue.poll();}
}
