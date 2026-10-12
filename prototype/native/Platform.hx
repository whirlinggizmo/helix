import hybrid.IHost;
import hybrid.IAssets;
import hybrid.IGraphics;
import hybrid.IInput;
import hybrid.IAudio;
import hybrid.IDiagnostics;
import hybrid.IFetch;
import hybrid.IStorage;
import hybrid.AssetService;
import hybrid.AudioResources;
class Platform implements IHost implements IDiagnostics {
 public var graphics(default,null):IGraphics;public var input(default,null):IInput;public var audio(default,null):IAudio;public var diagnostics(default,null):IDiagnostics;public var assets(default,null):IAssets;
 public var fetch(default,null):IFetch;public var storage(default,null):IStorage;public var audioResources(default,null):AudioResources;
 public var focused(default,null)=true;public var canQuit(default,null)=true;
 static var instance:Platform;var resources:AssetService;var keyboard:InputBackend;var mixer:AudioBackend;
 var initCallback:Void->Void;var frameCallback:Float->Void;var cleanupCallback:Void->Void;var inspectCallback:Void->Dynamic;
 public function new(){instance=this;diagnostics=this;}
 public function run(init:Void->Void,frame:Float->Void,cleanup:Void->Void):Void {
  initCallback=init;frameCallback=frame;cleanupCallback=cleanup;
  Native.run(cpp.Callable.fromStaticFunction(onInit),cpp.Callable.fromStaticFunction(onFrame),cpp.Callable.fromStaticFunction(onCleanup));
 }
 static function onInit():Void {
  instance.fetch=new FetchBackend();
  var root=haxe.io.Path.directory(Sys.programPath());var cache=Sys.getEnv("HY_CACHE");if(cache==null)cache=haxe.io.Path.join([root,"cache"]);
  instance.storage=new StorageBackend(cache);
  instance.resources=new AssetService(instance.fetch,instance.storage,new StorageBackend(haxe.io.Path.join([root,"assets"]),true),Sys.getEnv("HY_ASSET_HOST"));instance.assets=instance.resources;instance.keyboard=new InputBackend();instance.input=instance.keyboard;instance.mixer=new AudioBackend();instance.audio=instance.mixer;
  instance.audioResources=new AudioResources(instance.assets,instance.audio);instance.graphics=new GraphicsBackend();instance.initCallback();
 }
 static function onFrame(dt:cpp.Float32):Void {
  instance.resources.poll();instance.audioResources.poll();instance.keyboard.poll();instance.focused=Native.focused()!=0;instance.frameCallback(dt);
  var path=Sys.getEnv("HY_LIVE");if(path!=null&&instance.inspectCallback!=null){var value=instance.inspectCallback();value.host=instance.info();sys.io.File.saveContent(path,haxe.Json.stringify(value));}
 }
 static function onCleanup():Void {instance.audioResources.shutdown();instance.resources.shutdown();instance.cleanupCallback();instance.keyboard.shutdown();}
 public function now():Float return haxe.Timer.stamp();
 public function width():Int return Native.width();public function height():Int return Native.height();public function pixelRatio():Float return Native.pixelRatio();
 public function option(name:String,fallback:String):String {var value=Sys.getEnv("HY_"+name.toUpperCase());return value==null?fallback:value;}
 public function publish(value:Dynamic):Void {var json=haxe.Json.stringify(value);Sys.println(json);var path=Sys.getEnv("HY_RESULT");if(path!=null)sys.io.File.saveContent(path,json+"\n");}
 public function expose(inspect:Void->Dynamic):Void inspectCallback=inspect;
 public function capture():Void {var path=Sys.getEnv("HY_CAPTURE");if(path!=null)Native.capture(path);}
 public function quit():Void Native.quit();
 public function info():Dynamic {var value=mixer.info();value.backend="sokol-glcore";value.renderer=Std.string(Native.renderer());return value;}
}
