import helix.host.IHost;
import helix.input.IInput;
import helix.assets.IAssets.AssetResult;
import helix.debug.Autopilot;
class App {
 var host:IHost;var renderer:Renderer;var game:Game;var input=new Controls();var menu=new Menu();var sounds:Sounds;var pilot:Autopilot;
 var started:Float;var readyMs=0.;var firstFrameMs=0.;var frames=0;var replay=false;var freeze=-1;var measured=600;
 var accumulator=0.;var inputTick=0;var previous=0.;var cpu:Array<Float>=[];var intervals:Array<Float>=[];var audioEnabled:Bool;
 var sim:Array<Float>=[];var render:Array<Float>=[];var maxSteps=0;var clampedFrames=0;var stopped=false;var ready=false;var soundReady=false;var pilotReady=true;var fast=false;
 function new(host:IHost){this.host=host;started=host.now();audioEnabled=host.diagnostics.option("audio","1")=="1";replay=host.diagnostics.option("replay","0")=="1";freeze=number("tick",-1,-1,10000);measured=number("frames",600,60,3600);fast=host.diagnostics.option("fast","0")=="1";}
 function number(name:String,fallback:Int,min:Int,max:Int):Int {var value=Std.parseInt(host.diagnostics.option(name,Std.string(fallback)));if(value==null||value<min||value>max)throw 'Invalid '+name;return value;}
 function init():Void {
  game=new Game(number("seed",12345,1,2147483647));renderer=new Renderer(host.graphics);host.diagnostics.expose(inspect);
  var script=host.diagnostics.option("autopilot","");pilotReady=script=="";
  if(!pilotReady)host.assets.load(script,result->{switch(result){case Cancelled:throw new haxe.Exception("Autopilot load cancelled");
    case Failed(message):throw new haxe.Exception('Autopilot load failed: '+message);case Loaded(bytes):pilot=new Autopilot(bytes.toString());pilotReady=true;prepare();}});
  sounds=new Sounds(host.audioResources,error->{if(error!=null)throw new haxe.Exception('Sound load failed: '+error);soundReady=true;prepare();});
 }
 function prepare():Void {
  if(ready||!soundReady||!pilotReady)return;
  if(pilot!=null)game=new Game(pilot.seed);
  if(freeze>=0){for(i in 0...freeze){input.replay(i);game.step(input);}inputTick=freeze;}
  ready=true;readyMs=(host.now()-started)*1000;
 }
 function inspect():Dynamic return {ready:ready,loadedSounds:sounds==null?0:sounds.loaded,game:game.snapshot(),menu:{selected:menu.selected,hovered:menu.hovered},autopilot:pilot==null?null:pilot.snapshot(),frames:frames,inputTick:inputTick,vertices:renderer.vertices,draws:renderer.draws,uploadBytes:renderer.uploadBytes,geometryHash:renderer.geometryHash,width:host.width(),height:host.height(),pixelRatio:host.pixelRatio(),focused:host.focused};
 static function stats(values:Array<Float>):Dynamic {var sorted=values.copy();sorted.sort((a,b)->a<b?-1:a>b?1:0);var sum=0.;for(value in values)sum+=value;return {meanMs:sum/values.length,p95Ms:sorted[Std.int(Math.ceil(values.length*.95))-1],maxMs:sorted[sorted.length-1]};}
 function step():Bool {
  var source:IInput=host.input;
  if(pilot!=null){source=pilot.advance(game.probe);if(pilot.done)return false;}
  if(replay&&pilot==null)input.replay(inputTick);else{input.read(source);menu.update(game,input,source,host.width(),host.height());}
  if(input.quit&&host.canQuit){host.quit();stopped=true;return false;}
  game.step(input);source.consume();sounds.play(game,audioEnabled,host.focused);inputTick++;return true;
 }
 function publish():Void {
  var info=inspect();info.startupMs=readyMs;info.firstSubmissionMs=firstFrameMs;info.host=host.diagnostics.info();
  if(freeze<0&&pilot==null&&cpu.length>0){var sum=0.,late=0;for(value in intervals){sum+=value;if(value>25)late++;}info.phases={cpu:stats(cpu),simulation:stats(sim),render:stats(render)};info.fps=1000*intervals.length/sum;info.latePercent=late*100./intervals.length;info.measuredFrames=cpu.length;info.warmupFrames=60;info.maxSteps=maxSteps;info.clampedFrames=clampedFrames;}
  host.diagnostics.capture();host.diagnostics.publish(info);
 }
 function frame(dt:Float):Void {
  if(stopped||host.width()<=0||host.height()<=0)return;
  if(!ready){renderer.render(game,input,host.width(),host.height(),false,menu,false);if(firstFrameMs==0)firstFrameMs=(host.now()-started)*1000;return;}
  var began=host.now(),steps=0;
  if(freeze<0){
   if(pilot!=null&&fast){for(_ in 0...120){if(!step())break;steps++;}}
   else if(replay){if(step())steps++;}
   else if(host.focused){if(dt>.1)clampedFrames++;accumulator+=Math.min(dt,.1);while(accumulator>=1/60&&steps<6){if(!step())break;steps++;accumulator-=1/60;}}
   else{accumulator=0;sounds.play(game,false,false);}
  }
  maxSteps=Std.int(Math.max(maxSteps,steps));var simEnd=host.now();renderer.render(game,input,host.width(),host.height(),freeze>=0,menu);var ended=host.now();frames++;
  if(frames==1&&firstFrameMs==0)firstFrameMs=(ended-started)*1000;
  if(frames>60&&frames<=measured+60&&freeze<0&&pilot==null){cpu.push((ended-began)*1000);sim.push((simEnd-began)*1000);render.push((ended-simEnd)*1000);intervals.push((began-previous)*1000);}previous=began;
  if(freeze>=0||pilot!=null&&pilot.done||pilot==null&&frames==measured+60){publish();if(freeze>=0||pilot!=null||host.diagnostics.option("autoclose","0")=="1"){stopped=true;host.quit();}}
 }
 function cleanup():Void {sounds.cleanup();host.audio.shutdown();renderer.cleanup();}
 public static function start(host:IHost):Void {var app=new App(host);host.run(app.init,app.frame,app.cleanup);}
}
