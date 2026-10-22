// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a window cleared, nothing drawn.
import helix.AppOptions;
import helix.host.Window;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-1-window";
		new Game(options);
	}
}

/** This rung's game: a window, cleared by the runner; nothing on the stage. */
class Game extends helix.App {
	override public function init():Void
		Window.title = "1-window";
}
