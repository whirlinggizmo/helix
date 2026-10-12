package helix.adapters.host.sokol;
import helix.adapters.input.sokol.internal.InputBridge;
import helix.adapters.host.sokol.internal.HostBridge;
import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.host.HostServices;
import helix.host.IHost;
import helix.assets.IAssets;
import helix.graphics.IGraphics;
import helix.input.IInput;
import helix.audio.IAudio;
import helix.debug.IDiagnostics;
import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.assets.AssetService;
import helix.audio.AudioResources;
class SokolHostAdapter implements IHost implements IDiagnostics {
 public var graphics(default,null):IGraphics;public var input(default,null):IInput;public var audio(default,null):IAudio;public var diagnostics(default,null):IDiagnostics;public var assets(default,null):IAssets;
 public var fetch(default,null):IFetch;public var storage(default,null):IStorage;public var audioResources(default,null):AudioResources;
 public var focused(default,null)=true;public var canQuit(default,null)=true;
 static var instance:SokolHostAdapter;var resources:AssetService;var services:HostServices;var compose:Void->HostServices;
 var initCallback:Void->Void;var frameCallback:Float->Void;var cleanupCallback:Void->Void;var inspectCallback:Void->Dynamic;
 public function new(compose:Void->HostServices){this.compose=compose;instance=this;diagnostics=this;}
 public function run(init:Void->Void,frame:Float->Void,cleanup:Void->Void):Void {
  initCallback=init;frameCallback=frame;cleanupCallback=cleanup;
  HostBridge.run(cpp.Callable.fromStaticFunction(onInit),cpp.Callable.fromStaticFunction(onFrame),cpp.Callable.fromStaticFunction(onCleanup));
 }
 static function onInit():Void {
  instance.services=instance.compose();var s=instance.services;
  instance.fetch=s.fetch;instance.storage=s.storage;instance.input=s.input;instance.audio=s.audio;instance.graphics=s.graphics;
  instance.resources=new AssetService(s.fetch,s.storage,s.packaged,s.base);instance.assets=instance.resources;
  instance.audioResources=new AudioResources(instance.assets,instance.audio);instance.initCallback();
 }
 static function onFrame(dt:cpp.Float32):Void {
  var cpuStart=instance.now();
  instance.resources.poll();instance.audioResources.poll();instance.services.pollInput();instance.focused=InputBridge.focused()!=0;instance.frameCallback(dt);
  var path=Sys.getEnv("HELIX_LIVE");if(path!=null&&instance.inspectCallback!=null){var value=instance.inspectCallback();value.host=instance.info();sys.io.File.saveContent(path,haxe.Json.stringify(value));}
  instance.lastFrameCpu=(instance.now()-cpuStart)*1000;
 }
 static function onCleanup():Void {instance.audioResources.shutdown();instance.resources.shutdown();instance.cleanupCallback();instance.services.shutdownInput();}
 public function now():Float return haxe.Timer.stamp();
 public function width():Int return HostBridge.width();public function height():Int return HostBridge.height();public function pixelRatio():Float return HostBridge.pixelRatio();
 public function option(name:String,fallback:String):String {var value=Sys.getEnv("HELIX_"+name.toUpperCase());return value==null?fallback:value;}
 public function publish(value:Dynamic):Void {var json=haxe.Json.stringify(value);Sys.println(json);var path=Sys.getEnv("HELIX_RESULT");if(path!=null)sys.io.File.saveContent(path,json+"\n");}
 public function expose(inspect:Void->Dynamic):Void inspectCallback=inspect;
 public function capture():Void {var path=Sys.getEnv("HELIX_CAPTURE");if(path!=null)GraphicsBridge.capture(path);}
 public function quit():Void HostBridge.quit();
 var lastFrameCpu=0.;
 public function frameCpu():Float return lastFrameCpu;
 public function info():Dynamic return services.info();
}
