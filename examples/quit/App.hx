import helix.app.BaseApp;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Quitting while audio plays and files are loading. Plays music, and after a second starts loading files, keeps the frame busy for half a second
	(like a long synchronous load) and quits: shutdown runs with the loads still in progress, and nothing that was in flight may run after it.
	In a browser quitting stops the frame loop and runs the shutdown, and the canvas keeps the last frame. Q quits now, everywhere; Escape where
	quitting closes a window (in a browser Escape is the browser's: it leaves fullscreen). */
class App extends BaseApp {
	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var quitAt = 0.;
	var quitting = false;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX quit");
		host.window.setSize(640, 200);
		batch = new Batch2D(host.graphics);
		quitAt = host.getTime() + 1;
		host.diagnostics.expose(() -> ({quitting: quitting} : Dynamic));
		host.audioResources.loadStream("music/a_hero_is_born.mp3", result -> switch result {
			case Ready(stream):
				host.audioResources.play(stream, true, .5);
				stream.release();
			case _:
		});
	}

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (input.isFramePressed(Key.Q) || host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.pixels(host.getPixelRatio());
		host.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x1e2430ff);
		batch.begin(camera);
		Text2D.draw(batch, "HeliX quit   Q: quit now", 12, 12, 16, 0xf5f5f5ff);
		Text2D.draw(batch,
			quitting ? "quit requested: shutdown runs after this frame" : 'loading, stalling and quitting in ${Math.round(Math.max(0, quitAt - host.getTime()) * 10) / 10} s',
			12, 40, 16, 0xc8c8c8ff);
		batch.end();
		host.graphics.endFrame();
		if (!quitting && host.getTime() >= quitAt) {
			quitting = true;
			// Only in flight at the quit: loads begun and never used.
			host.textures.load("sprites/logo/wg-logo-white-alpha.png", true, _ -> {});
			host.textures.load("textures/tiles.png", false, _ -> {});
			host.audioResources.loadStream("music/a_hero_is_born.mp3", _ -> {});
			// A long synchronous frame.
			var busyUntil = host.getTime() + .5;
			while (host.getTime() < busyUntil) {}
			host.quit();
		}
	}

	override public function cleanup():Void {
		trace("quit: shutdown");
		host.diagnostics.publish({shutdown: true});
		batch.destroy();
	}
}
