import helix.app.BaseApp;
import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A window cleared each frame, and nothing drawn. No keys. */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Window.setTitle("HeliX skeleton");
		Window.requestSize(800, 600);
		batch = new Batch2D(Graphics.instance);
	}

	override public function frame(dt:Float):Void {
		camera.setViewport(Window.getFramebufferWidth(), Window.getFramebufferHeight());
		Graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0xf5f5f5ff);
		batch.begin(camera);
		batch.end();
		Graphics.endFrame();
	}
}
