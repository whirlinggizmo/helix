// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + a texture loaded and drawn.
import helix.app.AppOptions;
import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-4-sprites";
		new Game(options);
	}
}

/** This rung's game: + a texture loaded and drawn. */
class Game extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();
	var logo:Texture2D;

	override public function init():Void {
		Window.title = "4-sprites";
		batch = new Batch2D();
		Textures.load("sprites/logo.png", true, texture -> logo = texture);
	}

	override public function frame(dt:Float):Void {
		camera.pixels(Window.pixelRatio);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x202840ff);
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0x66bfffff);
		batch.drawText("Hello", 60, 90, 48, 0x102030ff);
		if (logo != null)
			batch.sprite(logo, 400, 300, 64, 64);
		batch.end();
		Graphics.endFrame();
	}
}
