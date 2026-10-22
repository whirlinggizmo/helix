import helix.host.Window;
import helix.render2d.Drawing2D;
import helix.render2d.Shape2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;
import helix.time.Time;

/** The stage (helix.render2d.Stage; docs/DISPLAY_MODEL.md): display objects added once and moved in update, with nothing drawn by hand,
	as on Flash's stage. A ball crossing the window and bouncing off its edges; a Drawing2D (Flash's graphics) cleared and drawn again each
	update, the ball's trail and a frame; a title fading in and out by its alpha; the stage cleared to its color. */
class App extends helix.App {
	var ball = Shape2D.circle(20, 0xff66bfff);
	var trail = new Drawing2D();
	var title = new Text2D("HeliX stage: nothing drawn by hand", 20, 0xffebeef5);
	var speedX = 180.;
	var speedY = 120.;
	var past:Array<Float> = [];

	override public function init():Void {
		Window.title = "HeliX stage";
		Stage.color = 0xff1d2230;
		ball.setPosition(100, 100);
		title.setPosition(20, 20);
		Stage.addChild(trail);
		Stage.addChild(ball);
		Stage.addChild(title);
	}

	override public function update(dt:Float):Void {
		var width = Window.width, height = Window.height;
		ball.x += speedX * dt;
		ball.y += speedY * dt;
		if (ball.x < 20 || ball.x > width - 20)
			speedX = ball.x < 20 ? Math.abs(speedX) : -Math.abs(speedX);
		if (ball.y < 20 || ball.y > height - 20)
			speedY = ball.y < 20 ? Math.abs(speedY) : -Math.abs(speedY);
		// The trail: where the ball was, drawn again each update, older dots fainter and smaller.
		past.push(ball.x);
		past.push(ball.y);
		if (past.length > 60)
			past.splice(0, 2);
		trail.clear();
		trail.frame(10, 10, width - 20, height - 20, 2, 0xff3a4258);
		var k = 0;
		while (k < past.length) {
			var age = k / past.length;
			trail.circle(past[k], past[k + 1], 4 + age * 12, helix.graphics.Color.withAlpha(0xff66bfff, Math.round(age * 120)));
			k += 2;
		}
		title.alpha = .6 + .4 * Math.sin(Time.clock.time * 2);
	}
}
