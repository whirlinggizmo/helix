import helix.app.BaseApp;
import helix.collision.Collide2D;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.math.Curve;
import helix.math.Random;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.time.Time;
import helix.time.Timers;
import helix.tween.Ease;
import helix.tween.Tweens;

/** Motion from the game's clock (Time.clock): a column of squares each tweened across by one easing and back (yoyo, for ever); a ball
	following a closed curve through points at a steady speed (Curve, by distance); a timer dropping a spark every half second that falls and
	fades by two tweens onto a floor (counted there by Collide2D); and the squares' colors dealt by a seeded Random. Space pauses the clock,
	which stops all of it at once; - and = slow and quicken it; R deals the colors again from the seed. Escape quits where quitting means
	anything. */
class App extends BaseApp {
	static var EASES:Array<{name:String, f:Float->Float}> = [
		{name: "linear", f: Ease.linear},
		{name: "quadInOut", f: Ease.quadInOut},
		{name: "cubicOut", f: Ease.cubicOut},
		{name: "sineInOut", f: Ease.sineInOut},
		{name: "expoOut", f: Ease.expoOut},
		{name: "backOut", f: Ease.backOut},
		{name: "elasticOut", f: Ease.elasticOut},
		{name: "bounceOut", f: Ease.bounceOut}
	];
	static var COLORS = [
		0xe62937ff,
		0xe8a33cff,
		0xffcb00ff,
		0x2fa36bff,
		0x66bfffff,
		0x5a7bffff,
		0xc87affff,
		0xf5f5f5ff
	];
	static inline var FLOOR_WIDTH = 360;
	static inline var FLOOR_Y = 200;

	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var tweens = new Tweens();
	var timers = new Timers();
	var random = new Random(7);
	var squares:Array<Node2D> = [];
	var labels:Array<Node2D> = [];
	// Each square's tweened offset across, 0 to 300, placed from the column's left each frame.
	var offsets:Array<Float> = [];
	var ball:Node2D;
	var path:Node2D;
	var floor:Node2D;
	var curve:Curve;
	var along = 0.;
	var sparks:Array<Spark> = [];
	var caught = 0;

	override public function init():Void {
		Window.setTitle("HeliX motion");
		Window.requestSize(1000, 600);
		batch = new Batch2D(Graphics.instance);
		// A square a row, each tweened from 0 to 300 across and back by its easing, for ever, a little apart in time.
		for (i in 0...EASES.length) {
			var square = Node2D.rectangle(24, 24, COLORS[i]);
			square.setPivot(.5, .5);
			square.setCornerRadius(4);
			stage.add(square);
			squares.push(square);
			offsets.push(0);
			var label = Node2D.text(EASES[i].name, 13, 0x8a92a8ff);
			stage.add(label);
			labels.push(label);
			var tween = tweens.to(0, 300, 1.6, EASES[i].f, x -> offsets[i] = x);
			tween.setRepeat(-1, true);
			tween.setDelay(i * .1);
		}
		// A closed path through five points, drawn from 80 samples, and a ball along it at 160 units a second.
		curve = Curve.through([0, 0, 180, -60, 300, 40, 200, 160, 40, 120], 2, true);
		var samples = [];
		for (i in 0...80) {
			samples.push(curve.getX(i / 80));
			samples.push(curve.getY(i / 80));
		}
		path = Node2D.polygon(samples);
		path.setOutline(1);
		path.setColor(0x3a4150ff);
		stage.add(path);
		ball = Node2D.circle(12, 0x66bfffff);
		stage.add(ball);
		floor = Node2D.rectangle(FLOOR_WIDTH, 6, 0x3a4150ff);
		stage.add(floor);
		// Every half second, a spark: it falls by a tween (bounceOut onto the floor) and fades by another, gone when faded.
		timers.every(.5, () -> {
			var spark = new Spark(Node2D.circle(5, random.pick(COLORS)), random.nextRange(10, FLOOR_WIDTH - 10));
			stage.add(spark.node);
			sparks.push(spark);
			tweens.to(0, FLOOR_Y - 4, 1.2, Ease.bounceOut, y -> spark.y = y);
			var fade = tweens.to(1, 0, 2.5, Ease.quadIn, a -> spark.alpha = a);
			fade.setComplete(() -> {
				stage.remove(spark.node);
				sparks.remove(spark);
			});
		});
		deal();
	}

	// The squares' colors dealt from the seed: the same deal each time.
	function deal():Void {
		random.setSeed(7);
		var dealt = random.shuffle(COLORS.copy());
		for (i in 0...squares.length)
			squares[i].setColor(dealt[i]);
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance, clock = Time.clock;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Space))
			if (clock.isPaused())
				clock.resume();
			else
				clock.pause();
		if (input.isFramePressed(Key.Minus))
			clock.setTimeScale(Math.max(.125, clock.getTimeScale() / 2));
		if (input.isFramePressed(Key.Equal))
			clock.setTimeScale(Math.min(4, clock.getTimeScale() * 2));
		if (input.isFramePressed(Key.R))
			deal();
		// Everything moves by the clock's delta: paused, it all stops.
		tweens.update(clock.getDelta());
		timers.update(clock.getDelta());
		along += clock.getDelta() * 160;
		var t = curve.getParameterAtDistance(along);
		fps.update(dt, Time.getFrameCpu());

		// Laid out in the design for the window's shape: the squares down the left, the path and the floor on the right (below, upright).
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		var upright = presentation.isPortrait();
		var left = vx + 120, top = vy + 100;
		for (i in 0...squares.length) {
			var y = top + i * 40;
			squares[i].setPosition(left + offsets[i], y);
			labels[i].setPosition(vx + 16, y - 7);
		}
		var rightX = upright ? vx + vw / 2 - 150 : vx + vw - 380,
			rightY = upright ? top + 8 * 40 + 70 : top + 20;
		path.setPosition(rightX, rightY);
		ball.setPosition(rightX + curve.getX(t), rightY + curve.getY(t));
		var floorX = upright ? rightX - 30 : rightX - 30,
			floorY = rightY + FLOOR_Y;
		floor.setPosition(floorX, floorY);
		caught = 0;
		for (spark in sparks) {
			spark.node.setPosition(floorX + spark.x, floorY - FLOOR_Y + spark.y);
			spark.node.setColor(spark.color & 0xffffff00 | Math.round(spark.alpha * 255));
			// On the floor: a circle against the floor's rectangle.
			if (Collide2D.rectCircle(floorX, floorY, FLOOR_WIDTH, 6, spark.node.getX(), spark.node.getY(), 5))
				caught++;
		}

		var width = Window.getFramebufferWidth(),
			height = Window.getFramebufferHeight();
		Graphics.beginFrame(width, height, 0x0c0e16ff);
		batch.begin(camera);
		stage.draw(batch, camera);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX motion: tweens, timers, a curve and the clock", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		Text2D.drawWrapped(batch,
			'Space: ${clock.isPaused() ? "resume" : "pause"}   - =: time x${clock.getTimeScale()}   R: deal again   ${sparks.length} sparks, $caught on the floor   clock ${Math.round(clock.getTime() * 10) / 10} s',
			vx + 12, y, 15, vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}

/** A falling spark: its node, where it is from the floor's left and top, and how faded. */
private class Spark {
	/** Its circle. */
	public final node:Node2D;

	/** Across the floor. */
	public final x:Float;

	/** Down from the floor's top edge less FLOOR_Y, tweened. */
	public var y = 0.;

	/** 1 bright to 0 gone, tweened. */
	public var alpha = 1.;

	/** Its color, with the alpha applied each frame. */
	public final color:Int;

	/** A spark drawn by node at x across. */
	public function new(node:Node2D, x:Float) {
		this.node = node;
		this.x = x;
		color = node.getColor();
	}
}
