// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + a sound loaded and played.
import helix.app.AppOptions;
import helix.audio.Audio;
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
		options.product = "size-5-audio";
		new Game(options);
	}
}

/** This rung's game: + a sound loaded and played. */
class Game extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();
	var logo:Texture2D;

	override public function init():Void {
		Window.title = "5-audio";
		batch = new Batch2D();
		Textures.load("sprites/logo.png", true, texture -> logo = texture);
		Audio.instance.loadClip("audio/click.ogg", clip -> Audio.play(clip));
	}

	override public function frame(dt:Float):Void {
		camera.pixels(Window.pixelRatio);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff202840);
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0xff66bfff);
		batch.drawText("Hello", 60, 90, 48, 0xff102030);
		if (logo != null)
			batch.sprite(logo, 400, 300, 64, 64);
		batch.end();
		Graphics.endFrame();
	}
}
