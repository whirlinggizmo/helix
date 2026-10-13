package helix.adapters.fetch.fetchapi;

import helix.assets.IFetch;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import haxe.io.Bytes;
class FetchApiAdapter implements IFetch {
 var queue=new WorkQueue();var jobs:Array<Void->Void>=[];var requests:Array<IRequest>=[];var active=0;var live=true;
 public function new(){}
 public function fetch(spec:FetchRequest,complete:FetchResult->Void,?progress:FetchProgress->Void):IRequest {
  var controller=new js.html.AbortController(),request:Request=null,timer=0,started=false,cancelled=false,progressPending=false;
  function finish(result:FetchResult){if(request.finish()){requests.remove(request);if(started)active--;if(timer!=0)js.Browser.window.clearTimeout(timer);queue.add(()->complete(result));}}
  request=new Request(()->{cancelled=true;controller.abort();requests.remove(request);if(started)active--;if(timer!=0)js.Browser.window.clearTimeout(timer);queue.add(()->complete(Cancelled));});requests.push(request);
  var limit=spec.maxBytes==null?8*1024*1024:spec.maxBytes,timeout=spec.timeoutSeconds==null?15.:spec.timeoutSeconds;
  jobs.push(()->{
   if(request.settled)return;
   if(!live||limit<=0||!Math.isFinite(timeout)||timeout<=0){finish(Failed("Invalid fetch request or closed service"));return;}
   started=true;active++;
   timer=js.Browser.window.setTimeout(()->{controller.abort();finish(Failed("Fetch timeout"));},Std.int(timeout*1000));
   js.Browser.window.fetch(spec.url,{signal:controller.signal,cache:spec.noCache==true?js.html.RequestCache.NO_STORE:js.html.RequestCache.DEFAULT}).then(response->{
    var headers:Map<String,String>=[];response.headers.forEach((value,name,_)->headers[name.toLowerCase()]=value);
    var length=Std.parseInt(headers["content-length"]),total=headers.exists("content-encoding")?null:length;
    var reader:Dynamic=(cast response:Dynamic).body==null?null:(cast response:Dynamic).body.getReader(),buffer=new haxe.io.BytesBuffer(),received=0;
    function accept(data:Bytes):Bool {if(request.settled)return false;received+=data.length;if(received>limit){controller.abort();finish(Failed("Fetch exceeds byte limit"));return false;}buffer.addBytes(data,0,data.length);if(progress!=null&&!progressPending){progressPending=true;queue.add(()->{progressPending=false;if(!cancelled)progress({received:received,total:total});});}return true;}
    if(reader==null){finish(Response({status:response.status,headers:headers,bytes:Bytes.alloc(0)}));return null;}
    var read:Void->Void=null;
    read=()->{reader.read().then(part->{if(request.settled)return null;if(part.done)finish(Response({status:response.status,headers:headers,bytes:buffer.getBytes()}));else{var chunk:js.lib.Uint8Array=cast part.value;if(accept(Bytes.ofData(chunk.buffer.slice(chunk.byteOffset,chunk.byteOffset+chunk.byteLength))))read();}return null;},error->{finish(Failed(Std.string(error)));return null;});};read();return null;
   },error->{finish(Failed(Std.string(error)));return null;});
  });return request;
 }
 public function poll():Void {while(active<2&&jobs.length>0)jobs.shift()();queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();jobs=[];queue.poll();}
}
