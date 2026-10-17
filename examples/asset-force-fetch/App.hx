import helix.app.BaseApp;
import helix.audio.AudioPlayback;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Both of ensure's options at once: a source (where this call's bytes come from) and forceFetch (past the cache). The asset's path is a bogus
	one, with nothing at the host under it, so a plain ensure would fail; the source names where the bytes really are, relative to the host as a
	browser reads a URL against a directory, so it's the same call on every target. The bytes are kept under the bogus path, and once the ensure
	is done that path streams as looping music. M pauses and resumes it; Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var KEY = "music/invalid.mp3";
	static inline var SOURCE = "music/a_hero_is_born.mp3";

	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var music:Null<AudioPlayback>;
	var state = 'ensuring $KEY from $SOURCE...';

	override public function init():Void {
		Services.window.setTitle("HeliX force fetch");
		Services.window.requestSize(720, 240);
		batch = new Batch2D(Services.graphics);
		Services.assets.ensure(KEY, result -> switch result {
			case Loaded(_):
				// The bytes are local now, under the key: stream the key.
				Services.audioResources.loadStream(KEY, loaded -> switch loaded {
					case Ready(stream):
						music = Services.audioResources.play(stream, true, .5);
						stream.release();
						state = '$KEY played from the bytes of $SOURCE';
					case Failed(message):
						state = message;
					case Cancelled:
				});
			case Failed(message):
				state = 'ensure failed: $message';
			case Cancelled:
		}, null, {source: SOURCE, forceFetch: true});
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (input.isFramePressed(Key.M) && music != null && !music.pause())
			music.resume();
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		fps.update(dt, Services.getFrameCpu());
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		Services.graphics.beginFrame(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight(), 0x12141cff);
		batch.begin(camera);
		var y = vy + 30;
		y += Text2D.drawWrapped(batch, "HeliX audio + force fetch", vx + 24, y, 28, vw - 48, 0xf5f5f5ff) + 15;
		y += Text2D.drawWrapped(batch, music == null ? "music: loading..." : music.getState() == Paused ? "music: paused" : "music: playing (mp3, looping)",
			vx + 24, y, 18, vw - 48, 0x66bfffff)
			+ 7.5;
		y += Text2D.drawWrapped(batch, state, vx + 24, y, 14, vw - 48, 0xc8c8c8ff) + 22.5;
		Text2D.drawWrapped(batch, "[M] toggle music" + (Services.canQuit() ? "   [ESC] quit" : ""), vx + 24, y, 16, vw - 48, 0xc8c8c8ff);
		fps.draw(batch, vx + 24, vy + 8);
		batch.end();
		Services.graphics.endFrame();
	}
}
