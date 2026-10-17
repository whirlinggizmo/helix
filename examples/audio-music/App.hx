import helix.app.BaseApp;
import helix.audio.Audio;
import helix.audio.AudioClip;
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

/** Looping music and a one-shot click. The music is streamed (decoded as it plays), the click decoded as it loads. The sound plays off the frame's
	thread on both targets (natively the mixer's, on the web the browser's), so it plays on through a slow frame: S stalls one for 300 ms.
	Space plays the click, M pauses and resumes the music, Escape quits where quitting means anything. */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var music:Null<AudioPlayback>;
	var click:Null<AudioClip>;

	override public function init():Void {
		Window.title = "HeliX audio";
		Window.requestSize(720, 240);
		batch = new Batch2D();
		var audio = Audio.instance;
		audio.loadStream("audio/music/a_hero_is_born.mp3", stream -> play(stream));
		audio.loadClip("audio/sfx/click_004.ogg", clip -> click = clip);
	}

	// The music opened: the playback holds the stream; the program lets its own reference go.
	function play(stream:AudioStream):Void {
		music = Audio.play(stream, true, .5);
		stream.release();
	}

	static function stateName(state:helix.audio.PlayState):String
		return switch (state) {
			case Playing: "playing";
			case Paused: "paused";
			case Stopped: "stopped";
			case Complete: "complete";
		};

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (input.isFramePressed(Key.Space) && click != null)
			Audio.play(click);
		if (input.isFramePressed(Key.S)) {
			// A deliberately slow frame.
			var until = Time.time + .3;
			while (Time.time < until) {}
		}
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
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x12141cff);
		batch.begin(camera);
		var y = vy + 30;
		y += batch.drawTextWrapped("HeliX audio", vx + 24, y, 28, vw - 48, 0xf5f5f5ff) + 15;
		y += batch.drawTextWrapped(music == null ? "music: loading..." : switch (music.state) {
			case Playing: "music: playing (mp3, streamed, looping)";
			case Paused: "music: paused";
			case Stopped: "music: couldn't start";
			case Complete: "music: ended";
		}, vx + 24, y, 18, vw - 48, 0x66bfffff) + 7.5;
		y += batch.drawTextWrapped(click != null ? "click: ready (ogg)" : "click: loading...", vx + 24, y, 18, vw - 48, 0x00e430ff) + 17.5;
		batch.drawTextWrapped("[SPACE] play click   [M] pause music   [S] stall 300 ms"
			+ (Host.canQuit() ? "   [ESC] quit" : ""), vx
			+ 24, y, 16, vw
			- 48,
			0xc8c8c8ff);
		fps.draw(batch, vx + 24, vy + 8);
		batch.end();
		Graphics.endFrame();
	}
}
