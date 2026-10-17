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
	var batch:Batch2D;
	var camera = new Camera2D();
	var quitAt = 0.;
	var quitting = false;

	override public function init():Void {
		Services.window.setTitle("HeliX quit");
		Services.window.requestSize(640, 200);
		batch = new Batch2D(Services.graphics);
		quitAt = Services.getTime() + 1;
		Services.audioResources.loadStream("music/a_hero_is_born.mp3", result -> switch result {
			case Ready(stream):
				Services.audioResources.play(stream, true, .5);
				stream.release();
			case _:
		});
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (input.isFramePressed(Key.Q) || Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		// The quit, before this frame is drawn: its text says so, and it's the frame the canvas keeps.
		if (!quitting && Services.getTime() >= quitAt) {
			quitting = true;
			// Only in flight at the quit: loads begun and never used.
			Services.textures.load("sprites/logo/wg-logo-white-alpha.png", true, _ -> {});
			Services.textures.load("textures/tiles.png", false, _ -> {});
			Services.audioResources.loadStream("music/a_hero_is_born.mp3", _ -> {});
			// A long synchronous frame.
			var busyUntil = Services.getTime() + .5;
			while (Services.getTime() < busyUntil) {}
			Services.quit();
		}
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		Services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x1e2430ff);
		batch.begin(camera);
		var y = vy + 12;
		y += Text2D.drawWrapped(batch, "HeliX quit   Q: quit now", vx + 12, y, 16, vw - 24, 0xf5f5f5ff) + 8;
		Text2D.drawWrapped(batch,
			quitting ? "quit requested: shutdown runs after this frame" : 'loading, stalling and quitting in ${Math.round(Math.max(0, quitAt - Services.getTime()) * 10) / 10} s',
			vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		trace("quit: shutdown");
		Services.harness.publish({shutdown: true});
		batch.destroy();
	}
}
