package hybrid;
import hybrid.IAssets;
import hybrid.IStorage;
import hybrid.IFetch;
/** Asset identity/cache policy stays shared. No target conditionals. */
class AssetService implements IAssets {
 var fetcher:IFetch;var cache:IStorage;var packaged:IStorage;var base:Null<String>;var queue=new WorkQueue();
 var live=true;var requests:Array<IRequest>=[];
 public function new(fetcher:IFetch,cache:IStorage,packaged:IStorage,base:Null<String>){this.fetcher=fetcher;this.cache=cache;this.packaged=packaged;this.base=base;}
 function key(path:String):String return haxe.crypto.Sha256.encode((base==null?"packaged":base)+"\n"+path);
 public function load(path:String,complete:AssetResult->Void):Void ensure(path,complete);
 public function ensure(path:String,complete:AssetResult->Void,?progress:AssetProgress->Void):IRequest {
  var child:IRequest=null,request:Request=null;
  function finish(result:AssetResult){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}}
  request=new Request(()->{if(child!=null)child.cancel();requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  function report(phase:String,received:Int,total:Null<Int>){if(progress!=null&&!request.settled)progress({phase:phase,received:received,total:total});}
  function obtained(bytes:haxe.io.Bytes){
   if(request.settled)return;report("storing",bytes.length,bytes.length);if(request.settled)return;
   child=cache.write(key(path),bytes,result->{if(request.settled)return;switch result {case Written:report("ready",bytes.length,bytes.length);finish(Loaded(bytes));case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);}});
  }
  queue.add(()->{
   if(request.settled)return;
   if(!live||!AssetPath.valid(path)){finish(Failed("Invalid asset path or closed service"));return;}
   report("locating",0,null);
   child=cache.read(key(path),result->{if(request.settled)return;switch result {
    case Stored(bytes):report("ready",bytes.length,bytes.length);finish(Loaded(bytes));
    case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);
    case Missing:
     if(base!=null)child=fetcher.fetch({url:base+path},result->{if(request.settled)return;switch result {case Response(value):if(value.status>=200&&value.status<300)obtained(value.bytes);else finish(Failed('Asset HTTP '+value.status+': '+path));case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);}},value->report("downloading",value.received,value.total));
     else child=packaged.read(path,result->{if(request.settled)return;switch result {case Stored(bytes):obtained(bytes);case Missing:finish(Failed("Missing asset: "+path));case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);}});
   }});
  });return request;
 }
 public function streamSource(path:String,complete:AssetSourceResult->Void):IRequest {
  var child:IRequest=null,request:Request=null;
  function finish(result:AssetSourceResult){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}else switch result {case Located(Stored(value)):value.release();case _:}}
  request=new Request(()->{if(child!=null)child.cancel();requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  function local(result:StorageSourceResult){if(request.settled){switch result {case Local(value):value.release();case _:}return;}switch result {
   case Local(value):finish(Located(Stored(value)));case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);
   case Missing:if(base!=null)finish(Located(Remote(base+path)));else child=packaged.source(path,result->switch result {case Local(value):finish(Located(Stored(value)));case Missing:finish(Failed("Missing streamed asset: "+path));case Failed(message):finish(Failed(message));case Cancelled:finish(Cancelled);});
  }}
  queue.add(()->{if(request.settled)return;if(!live||!AssetPath.valid(path)){finish(Failed("Invalid asset path or closed service"));return;}child=cache.source(key(path),local);});return request;
 }
 public function poll():Void {fetcher.poll();cache.poll();packaged.poll();queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();fetcher.shutdown();cache.shutdown();packaged.shutdown();queue.poll();}
}
