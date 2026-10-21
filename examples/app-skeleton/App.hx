import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A window cleared each frame, and nothing drawn. No keys. */
class App extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Window.title = "HeliX skeleton";
		Window.requestSize(800, 600);
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		camera.setViewport(Window.framebufferWidth, Window.framebufferHeight);
		Graphics.beginFrame(camera.framebufferWidth, camera.framebufferHeight, 0xf5f5f5ff);
		batch.begin(camera);
		batch.end();
		Graphics.endFrame();
	}
}
