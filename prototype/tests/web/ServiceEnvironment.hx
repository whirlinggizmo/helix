class ServiceEnvironment {
 public var remoteStreams=true;public var base:String;public var storage:StorageBackend;public var packaged:StorageBackend;public var audio:AudioBackend;
 public function new(){var params=new js.html.URLSearchParams(js.Browser.window.location.search);base=js.Browser.window.location.origin;storage=new StorageBackend(params.get("db"));packaged=new StorageBackend(params.get("db")+"-unused");audio=new AudioBackend();audio.unlock();}
 public function start(poll:Void->Void,done:Void->Bool,result:Void->Dynamic):Void {
  var started=haxe.Timer.stamp(),timer=0;timer=js.Browser.window.setInterval(()->{try {poll();if(done()){js.Browser.window.clearInterval(timer);js.Syntax.code("window.serviceResult={0}",result());}else if(haxe.Timer.stamp()-started>30)throw "Service test timeout";}catch(error:Dynamic){js.Browser.window.clearInterval(timer);js.Syntax.code("window.serviceResult={0}",{passed:false,error:Std.string(error),stack:haxe.CallStack.toString(haxe.CallStack.exceptionStack())});}},5);
 }
}
