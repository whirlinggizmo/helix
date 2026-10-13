import helix.app.BaseApp;
import helix.host.IHost;
import helix.input.IInput;
import helix.debug.Autopilot;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

class App extends BaseApp {
 var host:IHost;var game:Game;var controls=new Controls();var layout=new Layout();var camera=new Camera2D();
 var batch:Batch2D;var renderer:Renderer;var pilot:Autopilot;var accumulator=0.;var ticks=0;var stopped=false;
 function new(host:IHost){super();this.host=host;}
 override public function init():Void {
  var seed=Std.parseInt(host.diagnostics.option("seed","12345"));game=new Game(seed==null?12345:seed);
  batch=new Batch2D(host.graphics);renderer=new Renderer(batch);host.diagnostics.expose(inspect);
  var script=host.diagnostics.option("autopilot","");
  if(script!="")host.assets.load(script,result->switch result {case Loaded(bytes):pilot=new Autopilot(bytes.toString());game=new Game(pilot.seed);case Failed(message):throw 'Autopilot load failed: '+message;case Cancelled:});
 }
 function inspect():Dynamic return {ready:true,game:game.snapshot(),ticks:ticks,vertices:batch.vertices,draws:batch.draws,portrait:layout.portrait,zoom:camera.zoom,width:host.width(),height:host.height()};
 function step():Void {
  var source:IInput=host.input;if(pilot!=null){source=pilot.advance(game.probe);if(pilot.done){host.diagnostics.publish(inspect());pilot=null;stopped=host.diagnostics.option("autoclose","0")=="1";if(stopped)host.quit();return;}}
  game.step(controls.read(source,ticks,game,layout,camera));source.consume();ticks++;
 }
 override public function frame(dt:Float):Void {
  if(stopped||host.width()<=0||host.height()<=0)return;
  layout.update(host.width(),host.height());camera.viewport(host.width(),host.height());camera.fit(0,0,layout.worldWidth,layout.worldHeight);
  if(!host.focused&&game.state=="playing")game.state="paused";
  accumulator+=Math.min(dt,.1);var steps=0;while(accumulator>=1/60&&steps<6){step();accumulator-=1/60;steps++;}
  renderer.render(game,layout,camera,ticks);
 }
 override public function cleanup():Void {batch.cleanup();host.graphics.shutdown();}
 public static function start(host:IHost):Void host.run(new App(host));
}
