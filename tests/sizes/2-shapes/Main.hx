// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + the stage showing a rectangle.
import helix.app.AppOptions;
import helix.host.Window;
import helix.render2d.Shape2D;
import helix.render2d.Stage;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-2-shapes";
		new Game(options);
	}
}

/** This rung's game: + the stage, cleared to a color, showing a rectangle. */
class Game extends helix.App {
	override public function init():Void {
		Window.title = "2-shapes";
		Stage.color = 0xff202840;
		var box = Shape2D.rectangle(320, 160, 0xff66bfff);
		box.setPosition(40, 40);
		Stage.addChild(box);
	}
}
