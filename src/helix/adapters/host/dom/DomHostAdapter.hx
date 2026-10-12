package helix.adapters.host.dom;
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
import js.Browser;
import js.html.CanvasElement;

class DomHostAdapter implements IHost implements IDiagnostics {
 public var graphics(default,null):IGraphics;public var input(default,null):IInput;public var audio(default,null):IAudio;public var diagnostics(default,null):IDiagnostics;public var assets(default,null):IAssets;
 public var fetch(default,null):IFetch;public var storage(default,null):IStorage;public var audioResources(default,null):AudioResources;
 public var focused(default,null)=true;public var canQuit(default,null)=false;
 var resources:AssetService;var canvas:CanvasElement;var stopped=false;var closed=false;var services:HostServices;
 var params=new js.html.URLSearchParams(Browser.window.location.search);
 public function new(compose:(CanvasElement,Bool)->HostServices){
  diagnostics=this;canvas=cast Browser.document.getElementById("canvas");resize();services=compose(canvas,option("tick","-1")!="-1");
  graphics=services.graphics;input=services.input;audio=services.audio;fetch=services.fetch;storage=services.storage;
  resources=new AssetService(fetch,storage,services.packaged,services.base);assets=resources;audioResources=new AudioResources(assets,audio);
  Browser.window.addEventListener("resize",_->resize());
  Browser.window.addEventListener("keydown",_->services.unlockAudio());canvas.addEventListener("pointerdown",_->services.unlockAudio());
  Browser.window.addEventListener("blur",_->{focused=false;services.focusInput(false);services.suspendAudio();});
  Browser.window.addEventListener("focus",_->{focused=true;services.focusInput(true);});
  Browser.document.addEventListener("visibilitychange",_->{focused=!Browser.document.hidden;services.focusInput(focused);if(!focused)services.suspendAudio();});
  Browser.window.addEventListener("unhandledrejection",e->failure((cast e:Dynamic).reason));
  Browser.window.addEventListener("error",e->failure((cast e:Dynamic).error));
  canvas.addEventListener("webglcontextlost",e->{e.preventDefault();stopped=true;Browser.document.getElementById("status").textContent="Graphics context lost. Reload to recover.";});
 }
 function failure(error:Dynamic):Void {stopped=true;var message=Std.string(error);Browser.document.getElementById("status").textContent=message;Browser.console.error(message);}
 function resize():Void {canvas.width=Std.int(Math.max(1,Browser.window.innerWidth*pixelRatio()));canvas.height=Std.int(Math.max(1,Browser.window.innerHeight*pixelRatio()));}
 public function run(init:Void->Void,frame:Float->Void,cleanup:Void->Void):Void {
  init();var previous=now();var loop:Float->Void=null;
  loop=_-> {if(stopped)return;var current=now(),cpuStart=current;lastFrameInterval=(current-previous)*1000;resources.poll();audioResources.poll();services.pollInput();frame(current-previous);lastFrameCpu=(now()-cpuStart)*1000;previous=current;if(!stopped)Browser.window.requestAnimationFrame(loop);};
  Browser.window.requestAnimationFrame(loop);Browser.window.addEventListener("pagehide",_->{if(!closed){closed=true;audioResources.shutdown();resources.shutdown();cleanup();services.shutdownInput();}});
 }
 public function now():Float return Browser.window.performance.now()/1000;
 public function width():Int return canvas.width;public function height():Int return canvas.height;
 public function pixelRatio():Float return Browser.window.devicePixelRatio;
 public function option(name:String,fallback:String):String {var v=params.get(name);return v==null?fallback:v;}
 public function publish(value:Dynamic):Void {js.Syntax.code("window.result={0}",value);}
 public function expose(inspect:Void->Dynamic):Void {js.Syntax.code("window.inspect={0};window.graphicsContract={1};window.hostInfo={2}",inspect,graphics,info);}
 public function capture(name:String=""):Void {if(name!="")Browser.window.dispatchEvent(new js.html.CustomEvent("helix-capture",{detail:name}));}
 public function quit():Void stopped=true;
 var lastFrameCpu=0.;var lastFrameInterval=0.;
 public function frameCpu():Float return lastFrameCpu;
 public function frameInterval():Float return lastFrameInterval;
 public function frameAudit():Dynamic return null;
 public function memoryPhase(begin:Bool):Dynamic {var m:Dynamic=js.Syntax.code("performance.memory");return m==null?null:{usedBytes:m.usedJSHeapSize,totalBytes:m.totalJSHeapSize,limitBytes:m.jsHeapSizeLimit};}
 public function info():Dynamic return services.info();
}
