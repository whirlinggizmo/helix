package helix.audio;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.assets.IAssets;
import helix.audio.IAudio;
enum AudioLoadResult<T> {Ready(resource:T);Failed(message:String);Cancelled;}
/** Shared audio loading/policy/lifetime; adapters own decoding and delivery mechanisms. */
class AudioResources {
 var assets:IAssets;var backend:IAudio;var playbacks:Array<AudioPlayback>=[];var resources:Array<AudioResource>=[];var requests:Array<IRequest>=[];var queue=new WorkQueue();var live=true;
 public function new(assets:IAssets,backend:IAudio){this.assets=assets;this.backend=backend;}
 public function loadClip(path:String,complete:AudioLoadResult<AudioClip>->Void):IRequest {
  var child:IRequest=null,request:Request=null;
  function finish(result:AudioLoadResult<AudioClip>){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}else switch result {case Ready(resource):resource.release();case _:}}
  request=new Request(()->{if(child!=null)child.cancel();requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  if(!live){queue.add(()->finish(Failed("Closed audio resource service")));return request;}
  child=assets.ensure(path,result->{if(request.settled)return;switch result {
   case Loaded(bytes):child=backend.decodeClip(bytes,result->{if(request.settled)return;switch result {
    case Decoded(samples):try {var resource=new AudioClip(backend.createClip(samples),backend);resources.push(resource);finish(Ready(resource));}catch(error:Dynamic)finish(Failed(Std.string(error)));
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
  child=assets.streamSource(path,result->{if(request.settled){switch result {case Located(Stored(value)):value.release();case _:}return;}switch result {
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
  if(!live||resource.backend!=backend)throw "Invalid audio resource service";
  resource.retainPlayback();var id:Int;
  try {id=backend.play(resource.id,loop,volume);}catch(error:Dynamic){resource.releasePlayback();throw error;}
  var playback=new AudioPlayback(id,resource);if(!playback.finished)playbacks.push(playback);return playback;
 }
 public function poll():Void {backend.poll();resources=[for(resource in resources)if(!resource.disposed)resource];for(playback in playbacks.copy()){playback.poll();if(playback.finished)playbacks.remove(playback);}queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();for(playback in playbacks)playback.stop();playbacks=[];for(resource in resources)resource.release();resources=[];queue.poll();}
}
