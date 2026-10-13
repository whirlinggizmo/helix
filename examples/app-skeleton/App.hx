import helix.app.BaseApp;
import helix.host.IHost;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A window cleared each frame, and nothing drawn. No keys. (libwgf's app-skeleton) */
class App extends BaseApp {
 var host:IHost;var batch:Batch2D;var camera=new Camera2D();
 public function new(host:IHost){super();this.host=host;}
 override public function init():Void {host.window.setTitle("HeliX skeleton");host.window.setSize(800,600);batch=new Batch2D(host.graphics);}
 override public function frame(dt:Float):Void {camera.setViewport(host.getFramebufferWidth(),host.getFramebufferHeight());batch.begin(camera,0xf5f5f5ff);batch.end();}
}
