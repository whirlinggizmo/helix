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
		services.window.requestSize(WIDTH, HEIGHT);
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
		// The text and the squares in the design for the window's shape: the text wrapped to what's visible of it, and the squares' track
		// (LEFT to RIGHT) drawn across the visible width.
		ScreenShape.update(services);
		var presentation = services.presentation;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth(),
			vh = presentation.getVisibleHeight();
		var scale = (vw - 2 * LEFT - SQUARE) / (RIGHT - LEFT);
		services.graphics.beginFrame(services.window.getFramebufferWidth(), services.window.getFramebufferHeight(), 0x181a22ff);
		batch.begin(camera);
		var y = vy + 20;
		y += Text2D.drawWrapped(batch, "HeliX tick: a 10 Hz simulation, drawn every frame", vx + 20, y, 20, vw - 40, 0xf5f5f5ff) + 5;
		y += Text2D.drawWrapped(batch,
			'frame delta ${fixed(dt, 4)} s   tick fraction ${fixed(t, 2)}   ticks $ticks   '
			+ (ticker.getTimeScale() > 0 ? "running (Space pauses)" : "paused (Space resumes)"),
			vx
			+ 20, y, 16, vw
			- 40, 0xc8c8c8ff)
			+ 4;
		y += Text2D.drawWrapped(batch, 'Enter presses: tick $tickPresses, frame $framePresses', vx + 20, y, 16, vw - 40, 0xc8c8c8ff) + 36;
		y += Text2D.drawWrapped(batch, "where the latest tick left it", vx + 20, y, 16, vw - 40, 0x828282ff) + 5;
		batch.rect(vx + LEFT + (x - LEFT) * scale, y, SQUARE, SQUARE, 0xffa100ff);
		y += SQUARE + 55;
		y += Text2D.drawWrapped(batch, "between the last two ticks, by the tick fraction", vx + 20, y, 16, vw - 40, 0x828282ff) + 5;
		batch.rect(vx + LEFT + (previousX + (x - previousX) * t - LEFT) * scale, y, SQUARE, SQUARE, 0x66bfffff);
		fps.draw(batch, vx + 20, vy + vh - 30);
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
