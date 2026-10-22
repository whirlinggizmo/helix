import helix.assets.Assets;
import helix.audio.Audio;
import helix.audio.AudioPlayback;
import helix.audio.AudioStream;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.time.Time;
import helix.host.ScreenShape;

/** Both of ensure's options at once: a source (where this call's bytes come from) and forceFetch (past the cache). The asset's path is a bogus
	one, with nothing at the host under it, so a plain ensure would fail; the source names where the bytes really are, relative to the host as a
	browser reads a URL against a directory, so it's the same call on every target. The bytes are kept under the bogus path, and once the ensure
	is done that path streams as looping music. M pauses and resumes it; Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var KEY = "audio/music/invalid.mp3";
	static inline var SOURCE = "audio/music/a_hero_is_born.mp3";

	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var music:Null<AudioPlayback>;
	var state = 'ensuring $KEY from $SOURCE...';

	override public function init():Void {
		Window.title = "HeliX force fetch";
		Window.requestSize(720, 240);
		batch = new Batch2D();
		// The bytes are local once ensured, under the key: stream the key.
		Assets.ensure(KEY, _ -> Audio.loadStream(KEY, stream -> play(stream), message -> state = message), message -> state = 'ensure failed: $message', null,
			{source: SOURCE, forceFetch: true});
	}

	// The stream opened: played, the playback holding it.
	function play(stream:AudioStream):Void {
		music = Audio.music.play(stream, true, .5);
		stream.release();
		state = '$KEY played from the bytes of $SOURCE';
	}

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (input.isFramePressed(Key.M) && music != null && !music.pause())
			music.resume();
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff12141c);
		batch.begin(camera);
		var y = vy + 30;
		y += batch.drawTextWrapped("HeliX audio + force fetch", vx + 24, y, 28, vw - 48, 0xfff5f5f5) + 15;
		y += batch.drawTextWrapped(music == null ? "music: loading..." : music.state == Paused ? "music: paused" : "music: playing (mp3, looping)", vx + 24,
			y, 18, vw - 48, 0xff66bfff)
			+ 7.5;
		y += batch.drawTextWrapped(state, vx + 24, y, 14, vw - 48, 0xffc8c8c8) + 22.5;
		batch.drawTextWrapped("[M] toggle music" + (Host.canQuit() ? "   [ESC] quit" : ""), vx + 24, y, 16, vw - 48, 0xffc8c8c8);
		fps.draw(batch, vx + 24, vy + 8);
		batch.end();
		Graphics.endFrame();
	}
}
