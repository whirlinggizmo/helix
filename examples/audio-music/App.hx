import helix.app.BaseApp;
import helix.audio.AudioClip;
import helix.audio.AudioPlayback;
import helix.audio.AudioStream;
import helix.debug.FpsOverlay;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Looping music and a one-shot click. The music is streamed (decoded as it plays), the click decoded as it loads. The sound plays off the frame's
	thread on both targets (natively the mixer's, on the web the browser's), so it plays on through a slow frame: S stalls one for 300 ms.
	Space plays the click, M pauses and resumes the music, Escape quits where quitting means anything. */
class App extends BaseApp {
	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var music:Null<AudioPlayback>;
	var click:Null<AudioClip>;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX audio");
		host.window.setSize(720, 240);
		batch = new Batch2D(host.graphics);
		host.diagnostics.expose(() -> ({music: music == null ? "loading" : stateName(music.getState()), click: click != null} : Dynamic));
		var audio = host.audioResources;
		audio.loadStream("music/a_hero_is_born.mp3", result -> switch result {
			case Ready(stream):
				// The playback holds the stream; the program lets its own reference go.
				music = audio.play(stream, true, .5);
				stream.release();
			case Failed(message): trace(message);
			case Cancelled:
		});
		audio.loadClip("sounds/click_004.ogg", result -> switch result {
			case Ready(clip): click = clip;
			case Failed(message): trace(message);
			case Cancelled:
		});
	}

	static function stateName(state:helix.audio.PlayState):String
		return switch (state) {
			case Playing: "playing";
			case Paused: "paused";
			case Stopped: "stopped";
			case Complete: "complete";
		};

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (input.isFramePressed(Key.Space) && click != null)
			host.audioResources.play(click);
		if (input.isFramePressed(Key.S)) {
			// A deliberately slow frame.
			var until = host.getTime() + .3;
			while (host.getTime() < until) {}
		}
		if (input.isFramePressed(Key.M) && music != null && !music.pause())
			music.resume();
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		fps.update(dt, host.diagnostics.getFrameCpu());
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.pixels(host.getPixelRatio());
		batch.begin(camera, 0x12141cff);
		Text2D.draw(batch, "HeliX audio", 24, 30, 28, 0xf5f5f5ff);
		Text2D.draw(batch, music == null ? "music: loading..." : switch (music.getState()) {
			case Playing: "music: playing (mp3, streamed, looping)";
			case Paused: "music: paused";
			case Stopped: "music: couldn't start";
			case Complete: "music: ended";
		}, 24, 80, 18, 0x66bfffff);
		Text2D.draw(batch, click != null ? "click: ready (ogg)" : "click: loading...", 24, 110, 18, 0x00e430ff);
		Text2D.draw(batch, "[SPACE] play click   [M] pause music   [S] stall 300 ms" + (host.canQuit() ? "   [ESC] quit" : ""), 24, 150, 16, 0xc8c8c8ff);
		fps.draw(batch, 24, 8);
		batch.end();
	}
}
