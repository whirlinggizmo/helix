package helix.adapters.storage.filesystem;

import helix.assets.IStorage;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.assets.AssetPath;
import helix.core.WorkQueue;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.thread.Thread;
import sys.thread.Deque;
/** Bounded worker queue; completed writes replace a sibling temporary file. */
class FileStorageAdapter implements IStorage {
 var root:String;var readonly:Bool;var done=new Deque<Void->Void>();var queue=new WorkQueue();var jobs:Array<Void->Void>=[];var requests:Array<IRequest>=[];var active=0;var live=true;var serial=0;
 public function new(root:String,readonly=false){this.root=root;this.readonly=readonly;}
 function path(key:String):String {if(!AssetPath.valid(key))throw "Invalid storage path";return Path.join([root,key]);}
 function job<T>(work:Void->T,complete:T->Void,cancelled:T):IRequest {
  var request:Request=null;request=new Request(()->{requests.remove(request);queue.add(()->complete(cancelled));});requests.push(request);
  jobs.push(()->{if(request.isSettled())return;if(!live){request.cancel();return;}active++;Thread.create(()->{var result=work();done.add(()->{active--;if(request.finish()){requests.remove(request);complete(result);}});});});return request;
 }
 public function read(key:String,complete:StorageResult->Void):IRequest return job(()->try {var file=path(key);if(!sys.FileSystem.exists(file))Missing;else if(sys.FileSystem.stat(file).size>8*1024*1024)Failed("Stored file exceeds byte limit");else Stored(sys.io.File.getBytes(file));}catch(error:Dynamic)Failed(Std.string(error)),complete,Cancelled);
 public function write(key:String,bytes:Bytes,complete:StorageWriteResult->Void):IRequest {
  var copy=bytes.sub(0,bytes.length),suffix=++serial;
  return job(()->try {if(readonly)throw "Read-only storage";if(copy.length>8*1024*1024)throw "Stored file exceeds byte limit";var file=path(key),temp=file+".part-"+suffix;sys.FileSystem.createDirectory(Path.directory(file));try {sys.io.File.saveBytes(temp,copy);sys.FileSystem.rename(temp,file);}catch(error:Dynamic){if(sys.FileSystem.exists(temp))sys.FileSystem.deleteFile(temp);throw error;}Written;}catch(error:Dynamic)StorageWriteResult.Failed(Std.string(error)),complete,StorageWriteResult.Cancelled);
 }
 public function remove(key:String,complete:StorageWriteResult->Void):IRequest return job(()->try {if(readonly)throw "Read-only storage";var file=path(key);if(sys.FileSystem.exists(file))sys.FileSystem.deleteFile(file);Written;}catch(error:Dynamic)StorageWriteResult.Failed(Std.string(error)),complete,StorageWriteResult.Cancelled);
 public function source(key:String,complete:StorageSourceResult->Void):IRequest return job(()->try {var file=path(key);if(!sys.FileSystem.exists(file))StorageSourceResult.Missing;else StorageSourceResult.Local({location:file,release:()->{}});}catch(error:Dynamic)StorageSourceResult.Failed(Std.string(error)),complete,StorageSourceResult.Cancelled);
 public function poll():Void {while(true){var work=done.pop(false);if(work==null)break;queue.add(work);}while(live&&active<2&&jobs.length>0)jobs.shift()();queue.poll();}
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();jobs=[];queue.poll();}
}
