import helix.host.Window;
import helix.render2d.Stage;

/** A window cleared each frame (the stage's color), and nothing drawn. No keys. */
class App extends helix.App {
	override public function init():Void {
		Window.title = "HeliX skeleton";
		Window.requestSize(800, 600);
		Stage.color = 0xfff5f5f5;
	}

	override public function update(dt:Float):Void {}
}
