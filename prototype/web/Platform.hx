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
import js.Browser;
import js.html.CanvasElement;

class Platform implements IHost implements IDiagnostics {
 public var graphics(default,null):IGraphics;public var input(default,null):IInput;public var audio(default,null):IAudio;public var diagnostics(default,null):IDiagnostics;public var assets(default,null):IAssets;
 public var fetch(default,null):IFetch;public var storage(default,null):IStorage;public var audioResources(default,null):AudioResources;
 public var focused(default,null)=true;public var canQuit(default,null)=false;
 var resources:AssetService;var canvas:CanvasElement;var stopped=false;var closed=false;var keyboard:InputBackend;var mixer:AudioBackend;
 var params=new js.html.URLSearchParams(Browser.window.location.search);
 public function new(){
  diagnostics=this;fetch=new FetchBackend();storage=new StorageBackend("hybrid-asteroids-cache-v1");resources=new AssetService(fetch,storage,new StorageBackend("hybrid-unused-packaged-v1"),"assets/");assets=resources;canvas=cast Browser.document.getElementById("canvas");resize();graphics=new GraphicsBackend(canvas,option("tick","-1")!="-1");
  keyboard=new InputBackend(canvas);input=keyboard;mixer=new AudioBackend();audio=mixer;audioResources=new AudioResources(assets,audio);
  Browser.window.addEventListener("resize",_->resize());
  Browser.window.addEventListener("keydown",_->mixer.unlock());canvas.addEventListener("pointerdown",_->mixer.unlock());
  Browser.window.addEventListener("blur",_->{focused=false;keyboard.active=false;keyboard.clear();mixer.suspend();});
  Browser.window.addEventListener("focus",_->{focused=true;keyboard.active=true;});
  Browser.document.addEventListener("visibilitychange",_->{focused=!Browser.document.hidden;keyboard.active=focused;if(!focused){keyboard.clear();mixer.suspend();}});
  Browser.window.addEventListener("unhandledrejection",e->failure((cast e:Dynamic).reason));
  Browser.window.addEventListener("error",e->failure((cast e:Dynamic).error));
  canvas.addEventListener("webglcontextlost",e->{e.preventDefault();stopped=true;Browser.document.getElementById("status").textContent="Graphics context lost. Reload to recover.";});
 }
 function failure(error:Dynamic):Void {stopped=true;var message=Std.string(error);Browser.document.getElementById("status").textContent=message;Browser.console.error(message);}
 function resize():Void {canvas.width=Std.int(Math.max(1,Browser.window.innerWidth*pixelRatio()));canvas.height=Std.int(Math.max(1,Browser.window.innerHeight*pixelRatio()));}
 public function run(init:Void->Void,frame:Float->Void,cleanup:Void->Void):Void {
  init();var previous=now();var loop:Float->Void=null;
  loop=_-> {if(stopped)return;var current=now();resources.poll();audioResources.poll();keyboard.poll();frame(current-previous);previous=current;if(!stopped)Browser.window.requestAnimationFrame(loop);};
  Browser.window.requestAnimationFrame(loop);Browser.window.addEventListener("pagehide",_->{if(!closed){closed=true;audioResources.shutdown();resources.shutdown();cleanup();}});
 }
 public function now():Float return Browser.window.performance.now()/1000;
 public function width():Int return canvas.width;public function height():Int return canvas.height;
 public function pixelRatio():Float return Browser.window.devicePixelRatio;
 public function option(name:String,fallback:String):String {var v=params.get(name);return v==null?fallback:v;}
 public function publish(value:Dynamic):Void {js.Syntax.code("window.result={0}",value);}
 public function expose(inspect:Void->Dynamic):Void {js.Syntax.code("window.inspect={0};window.graphicsContract={1};window.hostInfo={2}",inspect,graphics,info);}
 public function capture():Void {}
 public function quit():Void stopped=true;
 public function info():Dynamic {
  var gl=(cast graphics:GraphicsBackend).gl,ext=gl.getExtension("WEBGL_debug_renderer_info"),value=mixer.info();
  value.backend="raw-webgl2";value.renderer=gl.getParameter(ext==null?js.html.webgl.WebGL2RenderingContext.RENDERER:untyped ext.UNMASKED_RENDERER_WEBGL);return value;
 }
}
