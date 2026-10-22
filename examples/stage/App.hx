import helix.host.Window;
import helix.render2d.Shape2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;

/** The stage (helix.render2d.Stage; docs/DISPLAY_MODEL.md): display objects added once and moved in update, with nothing drawn by hand,
	as on Flash's stage. A ball crossing the window and bouncing off its edges, a title over it; the stage cleared to its color. */
class App extends helix.App {
	var ball = Shape2D.circle(20, 0xff66bfff);
	var title = new Text2D("HeliX stage: nothing drawn by hand", 20, 0xffebeef5);
	var speedX = 180.;
	var speedY = 120.;

	override public function init():Void {
		Window.title = "HeliX stage";
		Stage.color = 0xff1d2230;
		ball.setPosition(100, 100);
		title.setPosition(20, 20);
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
	}
}
