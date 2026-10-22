import helix.time.Ticker;
import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.time.Time;
import helix.input.Key;
import helix.math.Interpolate;
import helix.host.ScreenShape;
import helix.render2d.Drawing2D;
import helix.render2d.Shape2D;
import helix.render2d.Stage;

/** Fixed-rate simulation (ticks) against drawing (frames). A deliberately slow 10 Hz tick moves two squares at the same speed: the top one is drawn
	where the latest tick left it, so it steps; the bottom one between its last two ticks, by the tick fraction, so it moves smoothly at any frame rate.
	Space pauses the game's clock (Time.clock), and so the ticks, while frames go on; Enter counts presses in the tick and in the frame, which always match, as each press is
	seen by exactly one tick. Escape quits where quitting means anything.
	The squares are Shape2Ds on the stage, placed at the end of update where they're drawn; the text a Drawing2D drawn again each update. */
class App extends helix.App {
	static inline var WIDTH = 800;
	static inline var HEIGHT = 450;
	static inline var SQUARE = 40;
	static inline var LEFT = 40;
	static inline var RIGHT = WIDTH - 80;
	static inline var SPEED = 240.;

	var text = new Drawing2D();
	var stepped = Shape2D.rectangle(SQUARE, SQUARE, 0xffffa100);
	var smooth = Shape2D.rectangle(SQUARE, SQUARE, 0xff66bfff);
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
		Stage.color = 0xff181a22;
		Stage.addChild(text);
		Stage.addChild(stepped);
		Stage.addChild(smooth);
		Stage.addChild(fps);
		ticker = new Ticker(10);
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

	override public function update(dt:Float):Void {
		if (Input.isFramePressed(Key.Enter))
			framePresses++;
		if (Input.isFramePressed(Key.Space))
			if (Time.clock.paused)
				Time.clock.resume();
			else
				Time.clock.pause();
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		ticker.advance(Time.clock.elapsed, () -> tick());
		var t = ticker.fraction;
		fps.update(dt, Time.frameCpu);
		// The text and the squares in the design for the window's shape: the text wrapped to what's visible of it, and the squares' track
		// (LEFT to RIGHT) drawn across the visible width.
		ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth,
			vh = Screen.visibleHeight;
		var scale = (vw - 2 * LEFT - SQUARE) / (RIGHT - LEFT);
		text.clear();
		var y = vy + 20;
		y += text.drawTextWrapped("HeliX tick: a 10 Hz simulation, drawn every frame", vx + 20, y, 20, vw - 40, 0xfff5f5f5) + 5;
		y += text.drawTextWrapped('frame delta ${fixed(dt, 4)} s   tick fraction ${fixed(t, 2)}   ticks $ticks   '
			+ (Time.clock.paused ? "paused (Space resumes)" : "running (Space pauses)"),
			vx
			+ 20, y, 16, vw
			- 40, 0xffc8c8c8)
			+ 4;
		y += text.drawTextWrapped('Enter presses: tick $tickPresses, frame $framePresses', vx + 20, y, 16, vw - 40, 0xffc8c8c8) + 36;
		y += text.drawTextWrapped("where the latest tick left it", vx + 20, y, 16, vw - 40, 0xff828282) + 5;
		stepped.setPosition(vx + LEFT + (x - LEFT) * scale, y);
		y += SQUARE + 55;
		y += text.drawTextWrapped("between the last two ticks, by the tick fraction", vx + 20, y, 16, vw - 40, 0xff828282) + 5;
		smooth.setPosition(vx + LEFT + (Interpolate.lerp(previousX, x, t) - LEFT) * scale, y);
		fps.setPosition(vx + 20, vy + vh - 30);
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
