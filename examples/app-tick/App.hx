import helix.app.BaseApp;
import helix.app.Ticker;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Fixed-rate simulation (ticks) against drawing (frames). A deliberately slow 10 Hz tick moves two squares at the same speed: the top one is drawn
	where the latest tick left it, so it steps; the bottom one between its last two ticks, by the tick fraction, so it moves smoothly at any frame rate.
	Space pauses the ticks (the time scale) while frames go on; Enter counts presses in the tick and in the frame, which always match, as each press is
	seen by exactly one tick. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var WIDTH = 800;
	static inline var HEIGHT = 450;
	static inline var SQUARE = 40;
	static inline var LEFT = 40;
	static inline var RIGHT = WIDTH - 80;
	static inline var SPEED = 240.;

	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var ticker:Ticker;
	var previousX = LEFT * 1.;
	var x = LEFT * 1.;
	var ticks = 0;
	var tickPresses = 0;
	var framePresses = 0;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX tick");
		services.window.setSize(WIDTH, HEIGHT);
		batch = new Batch2D(services.graphics);
		ticker = new Ticker(services.input, 10);
	}

	function tick():Void {
		previousX = x;
		x += SPEED * ticker.getDelta();
		if (x > RIGHT) {
			x = LEFT;
			previousX = x;
		} // not smoothed across the wrap
		ticks++;
		if (services.input.isPressed(Key.Enter))
			tickPresses++;
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (input.isFramePressed(Key.Enter))
			framePresses++;
		if (input.isFramePressed(Key.Space))
			ticker.setTimeScale(ticker.getTimeScale() > 0 ? 0 : 1);
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		ticker.advance(services.getFrameElapsed(), tick);
		var t = ticker.getFraction();
		fps.update(dt, services.getFrameCpu());
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.pixels(services.window.getPixelRatio());
		services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x181a22ff);
		batch.begin(camera);
		Text2D.draw(batch, "HeliX tick: a 10 Hz simulation, drawn every frame", 20, 20, 20, 0xf5f5f5ff);
		Text2D.draw(batch,
			'frame delta ${fixed(dt, 4)} s   tick fraction ${fixed(t, 2)}   ticks $ticks   ' +
			(ticker.getTimeScale() > 0 ? "running (Space pauses)" : "paused (Space resumes)"),
			20, 50, 16, 0xc8c8c8ff);
		Text2D.draw(batch, 'Enter presses: tick $tickPresses, frame $framePresses', 20, 74, 16, 0xc8c8c8ff);
		Text2D.draw(batch, "where the latest tick left it", 20, 130, 16, 0x828282ff);
		batch.rect(x, 155, SQUARE, SQUARE, 0xffa100ff);
		Text2D.draw(batch, "between the last two ticks, by the tick fraction", 20, 250, 16, 0x828282ff);
		batch.rect(previousX + (x - previousX) * t, 275, SQUARE, SQUARE, 0x66bfffff);
		fps.draw(batch, 20, HEIGHT - 30);
		batch.end();
		services.graphics.endFrame();
	}

	static function fixed(value:Float, places:Int):String {
		var s = Std.string(Math.round(value * Math.pow(10, places)) / Math.pow(10, places));
		if (s.indexOf(".") < 0)
			s += ".";
		while (s.length - s.indexOf(".") - 1 < places)
			s += "0";
		return s;
	}
}
