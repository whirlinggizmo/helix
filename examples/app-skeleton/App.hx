import helix.app.BaseApp;
import helix.host.Services;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A window cleared each frame, and nothing drawn. No keys. */
class App extends BaseApp {
	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX skeleton");
		services.window.setSize(800, 600);
		batch = new Batch2D(services.graphics);
	}

	override public function frame(dt:Float):Void {
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0xf5f5f5ff);
		batch.begin(camera);
		batch.end();
		services.graphics.endFrame();
	}
}
