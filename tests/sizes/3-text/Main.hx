// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + text in the built-in font (the starter).
import helix.AppOptions;
import helix.host.Window;
import helix.render2d.Shape2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-3-text";
		new Game(options);
	}
}

/** This rung's game: + text in the built-in font (the starter). */
class Game extends helix.App {
	override public function init():Void {
		Window.title = "3-text";
		Stage.color = 0xff202840;
		var box = Shape2D.rectangle(320, 160, 0xff66bfff);
		box.setPosition(40, 40);
		Stage.addChild(box);
		var hello = new Text2D("Hello", 48, 0xff102030);
		hello.setPosition(60, 90);
		Stage.addChild(hello);
	}
}
