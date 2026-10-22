import helix.time.Ticker;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.time.Time;
import helix.input.Key;
import helix.math.Interpolate;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.host.ScreenShape;

/** Fixed-rate simulation (ticks) against drawing (frames). A deliberately slow 10 Hz tick moves two squares at the same speed: the top one is drawn
	where the latest tick left it, so it steps; the bottom one between its last two ticks, by the tick fraction, so it moves smoothly at any frame rate.
	Space pauses the game's clock (Time.clock), and so the ticks, while frames go on; Enter counts presses in the tick and in the frame, which always match, as each press is
	seen by exactly one tick. Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var WIDTH = 800;
	static inline var HEIGHT = 450;
	static inline var SQUARE = 40;
	static inline var LEFT = 40;
	static inline var RIGHT = WIDTH - 80;
	static inline var SPEED = 240.;

	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var ticker:Ticker;
	var previousX = LEFT * 1.;
	var x = LEFT * 1.;
	var ticks = 0;
	var tickPresses = 0;
	var framePresses = 0;

	override public function init():Void {
		Window.title = "HeliX tick";
		Window.requestSize(WIDTH, HEIGHT);
		batch = new Batch2D();
		ticker = new Ticker(Input.instance, 10);
	}

	function tick():Void {
		previousX = x;
		x += SPEED * ticker.delta;
		if (x > RIGHT) {
			x = LEFT;
			previousX = x;
		} // not smoothed across the wrap
		ticks++;
		if (Input.isPressed(Key.Enter))
			tickPresses++;
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (input.isFramePressed(Key.Enter))
			framePresses++;
		if (input.isFramePressed(Key.Space))
			if (Time.clock.paused)
				Time.clock.resume();
			else
				Time.clock.pause();
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		ticker.advance(Time.clock.elapsed, () -> tick());
		var t = ticker.fraction;
		fps.update(dt, Time.frameCpu);
		// The text and the squares in the design for the window's shape: the text wrapped to what's visible of it, and the squares' track
		// (LEFT to RIGHT) drawn across the visible width.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		var scale = (vw - 2 * LEFT - SQUARE) / (RIGHT - LEFT);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff181a22);
		batch.begin(camera);
		var y = vy + 20;
		y += batch.drawTextWrapped("HeliX tick: a 10 Hz simulation, drawn every frame", vx + 20, y, 20, vw - 40, 0xfff5f5f5) + 5;
		y += batch.drawTextWrapped('frame delta ${fixed(dt, 4)} s   tick fraction ${fixed(t, 2)}   ticks $ticks   '
			+ (Time.clock.paused ? "paused (Space resumes)" : "running (Space pauses)"),
			vx
			+ 20, y, 16, vw
			- 40, 0xffc8c8c8)
			+ 4;
		y += batch.drawTextWrapped('Enter presses: tick $tickPresses, frame $framePresses', vx + 20, y, 16, vw - 40, 0xffc8c8c8) + 36;
		y += batch.drawTextWrapped("where the latest tick left it", vx + 20, y, 16, vw - 40, 0xff828282) + 5;
		batch.rect(vx + LEFT + (x - LEFT) * scale, y, SQUARE, SQUARE, 0xffffa100);
		y += SQUARE + 55;
		y += batch.drawTextWrapped("between the last two ticks, by the tick fraction", vx + 20, y, 16, vw - 40, 0xff828282) + 5;
		batch.rect(vx + LEFT + (Interpolate.lerp(previousX, x, t) - LEFT) * scale, y, SQUARE, SQUARE, 0xff66bfff);
		fps.draw(batch, vx + 20, vy + vh - 30);
		batch.end();
		Graphics.endFrame();
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
