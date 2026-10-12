package helix.adapters.fetch.haxehttp;

import helix.assets.IFetch;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import haxe.io.Bytes;
import sys.thread.Thread;
import sys.thread.Deque;
private class FetchOutput extends haxe.io.Output {
 var buffer=new haxe.io.BytesBuffer();var limit:Int;var notify:Int->Void;var received=0;
 public function new(limit:Int,notify:Int->Void){this.limit=limit;this.notify=notify;}
 public override function writeByte(value:Int):Void {var b=Bytes.alloc(1);b.set(0,value);writeBytes(b,0,1);}
 public override function writeBytes(bytes:Bytes,pos:Int,len:Int):Int {if(received+len>limit)throw "Fetch exceeds byte limit";buffer.addBytes(bytes,pos,len);received+=len;notify(received);return len;}
 public function bytes():Bytes return buffer.getBytes();
}
class HaxeHttpFetchAdapter implements IFetch {
 var done=new Deque<Void->Void>();var queue=new WorkQueue();var jobs:Array<Void->Void>=[];var requests:Array<IRequest>=[];var active=0;var live=true;var progressReaders:Array<Void->Void>=[];
 public function new(){}
 public function fetch(spec:FetchRequest,complete:FetchResult->Void,?progress:FetchProgress->Void):IRequest {
  var request:Request=null,readProgress:Void->Void=null;var lock=new sys.thread.Mutex(),received=0,last=-1,total:Null<Int>=null;
  function finish(result:FetchResult){if(request.finish()){requests.remove(request);if(readProgress!=null){readProgress();progressReaders.remove(readProgress);}queue.add(()->complete(result));}}
  request=new Request(()->{requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  var url=spec.url,limit=spec.maxBytes==null?8*1024*1024:spec.maxBytes,timeout=spec.timeoutSeconds==null?15.:spec.timeoutSeconds;
  jobs.push(()->{
   if(request.settled)return;
   if(!live||limit<=0||!Math.isFinite(timeout)||timeout<=0||!(StringTools.startsWith(url,"http://")||StringTools.startsWith(url,"https://"))){finish(Failed("Invalid fetch request or closed service"));return;}
   readProgress=()->{lock.acquire();var count=received,length=total;lock.release();if(count!=last&&progress!=null&&!request.settled){last=count;progress({received:count,total:length});}};progressReaders.push(readProgress);
   active++;Thread.create(()->{
    var result:FetchResult;
    try {
     var http=new haxe.Http(url);http.cnxTimeout=timeout;var status=0,error:Null<String>=null;
     http.onStatus=value->{status=value;lock.acquire();total=Std.parseInt(http.responseHeaders["Content-Length"]);lock.release();};http.onError=value->error=value;
     // Worker publishes a coalesced byte count; application callbacks run only in poll.
     var output=new FetchOutput(limit,value->{lock.acquire();received=value;lock.release();});
     http.customRequest(false,output);
     var headers:Map<String,String>=[];if(http.responseHeaders!=null)for(name=>value in http.responseHeaders)headers[name.toLowerCase()]=value;
     result=status!=0&&(error==null||error=="Http Error #"+status)?Response({status:status,headers:headers,bytes:output.bytes()}):Failed(error==null?"No HTTP response":error);
    }catch(error:Dynamic){result=Failed(Std.string(error));}
    done.add(()->{active--;finish(result);});
   });
  });return request;
 }
 public function poll():Void {for(reader in progressReaders.copy())reader();while(true){var work=done.pop(false);if(work==null)break;queue.add(work);}while(live&&active<2&&jobs.length>0)jobs.shift()();queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();jobs=[];queue.poll();}
}
