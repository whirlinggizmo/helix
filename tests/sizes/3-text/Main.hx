// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + text in the built-in font (the starter).
import helix.app.AppOptions;
import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

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
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Window.title = "3-text";
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		camera.pixels(Window.pixelRatio);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff202840);
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0xff66bfff);
		batch.drawText("Hello", 60, 90, 48, 0xff102030);
		batch.end();
		Graphics.endFrame();
	}
}
