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

	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var music:Null<AudioPlayback>;
	var state = 'ensuring $KEY from $SOURCE...';

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX force fetch");
		services.window.requestSize(720, 240);
		batch = new Batch2D(services.graphics);
		services.assets.ensure(KEY, result -> switch result {
			case Loaded(_):
				// The bytes are local now, under the key: stream the key.
				services.audioResources.loadStream(KEY, loaded -> switch loaded {
					case Ready(stream):
						music = services.audioResources.play(stream, true, .5);
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
		var input = services.input;
		if (input.isFramePressed(Key.M) && music != null && !music.pause())
			music.resume();
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		fps.update(dt, services.getFrameCpu());
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.pixels(services.window.getPixelRatio());
		services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x12141cff);
		batch.begin(camera);
		Text2D.draw(batch, "HeliX audio + force fetch", 24, 30, 28, 0xf5f5f5ff);
		Text2D.draw(batch, music == null ? "music: loading..." : music.getState() == Paused ? "music: paused" : "music: playing (mp3, looping)", 24, 80, 18,
			0x66bfffff);
		Text2D.draw(batch, state, 24, 110, 14, 0xc8c8c8ff);
		Text2D.draw(batch, "[M] toggle music" + (services.canQuit() ? "   [ESC] quit" : ""), 24, 150, 16, 0xc8c8c8ff);
		fps.draw(batch, 24, 8);
		batch.end();
		services.graphics.endFrame();
	}
}
