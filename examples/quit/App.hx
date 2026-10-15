import helix.app.BaseApp;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Quitting while audio plays and files are loading. Plays music, and after a second starts loading files, keeps the frame busy for half a second
	(like a long synchronous load) and quits: shutdown runs with the loads still in progress, and nothing that was in flight may run after it.
	In a browser quitting stops the frame loop and runs the shutdown, and the canvas keeps the last frame. Q quits now, everywhere; Escape where
	quitting closes a window (in a browser Escape is the browser's: it leaves fullscreen). */
class App extends BaseApp {
	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
	var quitAt = 0.;
	var quitting = false;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX quit");
		services.window.requestSize(640, 200);
		batch = new Batch2D(services.graphics);
		quitAt = services.getTime() + 1;
		services.audioResources.loadStream("music/a_hero_is_born.mp3", result -> switch result {
			case Ready(stream):
				services.audioResources.play(stream, true, .5);
				stream.release();
			case _:
		});
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (input.isFramePressed(Key.Q) || services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.pixels(services.window.getPixelRatio());
		services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x1e2430ff);
		batch.begin(camera);
		Text2D.draw(batch, "HeliX quit   Q: quit now", 12, 12, 16, 0xf5f5f5ff);
		Text2D.draw(batch,
			quitting ? "quit requested: shutdown runs after this frame" : 'loading, stalling and quitting in ${Math.round(Math.max(0, quitAt - services.getTime()) * 10) / 10} s',
			12, 40, 16, 0xc8c8c8ff);
		batch.end();
		services.graphics.endFrame();
		if (!quitting && services.getTime() >= quitAt) {
			quitting = true;
			// Only in flight at the quit: loads begun and never used.
			services.textures.load("sprites/logo/wg-logo-white-alpha.png", true, _ -> {});
			services.textures.load("textures/tiles.png", false, _ -> {});
			services.audioResources.loadStream("music/a_hero_is_born.mp3", _ -> {});
			// A long synchronous frame.
			var busyUntil = services.getTime() + .5;
			while (services.getTime() < busyUntil) {}
			services.quit();
		}
	}

	override public function cleanup():Void {
		trace("quit: shutdown");
		services.harness.publish({shutdown: true});
		batch.destroy();
	}
}
