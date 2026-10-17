import helix.app.BaseApp;
import helix.host.Services;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A window cleared each frame, and nothing drawn. No keys. */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Services.window.setTitle("HeliX skeleton");
		Services.window.requestSize(800, 600);
		batch = new Batch2D(Services.graphics);
	}

	override public function frame(dt:Float):Void {
		camera.setViewport(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight());
		Services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0xf5f5f5ff);
		batch.begin(camera);
		batch.end();
		Services.graphics.endFrame();
	}
}
